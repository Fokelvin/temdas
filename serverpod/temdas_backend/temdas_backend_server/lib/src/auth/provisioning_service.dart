import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../admin/convite_service.dart' show normalizarEmail;
import '../generated/protocol.dart';

AuthException _failure(String code) => AuthException(codigo: code);

abstract class ConfirmedEmailSource {
  Future<String> emailForUser(String supabaseUserId);
}

/// Reads the current Auth user from Supabase, rather than trusting JWT.email
/// or an email supplied by the caller.
class SupabaseConfirmedEmailSource implements ConfirmedEmailSource {
  SupabaseConfirmedEmailSource({
    http.Client? client,
    Map<String, String>? environment,
  }) : _client = client ?? http.Client(),
       _environment = environment ?? Platform.environment;

  final http.Client _client;
  final Map<String, String> _environment;

  @override
  Future<String> emailForUser(String supabaseUserId) async {
    final url = _environment['SUPABASE_URL'];
    final key = _environment['SUPABASE_SECRET_KEY'];
    final origin = url == null ? null : Uri.tryParse(url);
    if (origin == null ||
        origin.scheme != 'https' ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/') ||
        key == null ||
        !key.startsWith('sb_secret_')) {
      throw _failure('authNaoConfigurado');
    }

    final request =
        http.Request(
            'GET',
            origin.replace(
              pathSegments: ['auth', 'v1', 'admin', 'users', supabaseUserId],
            ),
          )
          ..followRedirects = false
          ..headers['apikey'] = key;
    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 404) {
        throw _failure('usuarioSupabaseNaoEncontrado');
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw _failure('authNaoConfigurado');
      }
      if (response.statusCode != 200) throw _failure('authIndisponivel');

      final bytes = await (() async {
        final body = <int>[];
        await for (final chunk in response.stream) {
          if (body.length + chunk.length > 65536) {
            throw _failure('authIndisponivel');
          }
          body.addAll(chunk);
        }
        return body;
      })().timeout(const Duration(seconds: 5));
      final data = jsonDecode(utf8.decode(bytes));
      if (data is! Map<String, dynamic> ||
          data['id'] != supabaseUserId ||
          data['email'] is! String) {
        throw _failure('authIndisponivel');
      }
      final confirmedAt = data['email_confirmed_at'];
      if (data['is_anonymous'] == true || confirmedAt == null) {
        throw _failure('emailNaoConfirmado');
      }
      if (confirmedAt is! String || DateTime.tryParse(confirmedAt) == null) {
        throw _failure('authIndisponivel');
      }
      return data['email'] as String;
    } on AuthException {
      rethrow;
    } catch (_) {
      // Never expose the secret, user object, or Supabase response.
      throw _failure('authIndisponivel');
    }
  }
}

abstract class ProvisioningStore {
  Future<Usuario> provisionar(
    Session session,
    String supabaseUserId,
    String email,
  );
}

class PostgresProvisioningStore implements ProvisioningStore {
  const PostgresProvisioningStore();

  @override
  Future<Usuario> provisionar(
    Session session,
    String supabaseUserId,
    String email,
  ) => session.db.transaction((transaction) async {
    // Lock by subject first, then email. The email lock is shared with invites.
    await session.db.unsafeQuery(
      'SELECT pg_advisory_xact_lock(1543623472, hashtext(@sub))',
      transaction: transaction,
      parameters: QueryParameters.named({'sub': supabaseUserId}),
    );
    var usuario = await Usuario.db.findFirstRow(
      session,
      where: (t) => t.supabaseUserId.equals(supabaseUserId),
      lockMode: LockMode.forUpdate,
      transaction: transaction,
    );
    if (usuario != null) return usuario;

    await session.db.unsafeQuery(
      'SELECT pg_advisory_xact_lock(1543623471, hashtext(@email))',
      transaction: transaction,
      parameters: QueryParameters.named({'email': email}),
    );

    final whitelist = await EmailWhitelist.db.findFirstRow(
      session,
      where: (t) => t.emailNormalizado.equals(email),
      lockMode: LockMode.forUpdate,
      transaction: transaction,
    );
    if (whitelist == null) throw _failure('emailNaoAutorizado');
    if (whitelist.utilizadoEm != null) {
      throw _failure('conviteJaUtilizado');
    }

    // The unique index also handles writers outside this advisory lock.
    await session.db.unsafeQuery(
      'INSERT INTO "usuarios" ("supabaseUserId", "isAdmin", "createdAt") '
      'VALUES (@sub, false, @createdAt) '
      'ON CONFLICT ("supabaseUserId") DO NOTHING',
      transaction: transaction,
      parameters: QueryParameters.named({
        'sub': supabaseUserId,
        'createdAt': DateTime.now().toUtc(),
      }),
    );
    usuario = await Usuario.db.findFirstRow(
      session,
      where: (t) => t.supabaseUserId.equals(supabaseUserId),
      transaction: transaction,
    );
    if (usuario == null) throw _failure('provisioningConflito');

    await EmailWhitelist.db.updateById(
      session,
      whitelist.id!,
      columnValues: (t) => [t.utilizadoEm(DateTime.now().toUtc())],
      transaction: transaction,
    );
    return usuario;
  });
}

class ProvisioningService {
  const ProvisioningService({
    required ConfirmedEmailSource emailSource,
    required ProvisioningStore store,
  }) : _emailSource = emailSource,
       _store = store;

  factory ProvisioningService.production() => ProvisioningService(
    emailSource: SupabaseConfirmedEmailSource(),
    store: const PostgresProvisioningStore(),
  );

  final ConfirmedEmailSource _emailSource;
  final ProvisioningStore _store;

  Future<Usuario> provisionar(Session session, String supabaseUserId) async {
    final confirmedEmail = await _emailSource.emailForUser(supabaseUserId);
    String email;
    try {
      email = normalizarEmail(confirmedEmail);
    } on ConviteException {
      throw _failure('emailInvalido');
    }
    return _store.provisionar(session, supabaseUserId, email);
  }
}
