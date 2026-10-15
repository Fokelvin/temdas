import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

ConviteException _failure(String code) => ConviteException(codigo: code);

String normalizarEmail(String input) {
  final email = input.trim().toLowerCase();
  if (email.length > 254 ||
      email.isEmpty ||
      email.contains(RegExp(r'\s')) ||
      email.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
    throw _failure('emailInvalido');
  }
  final parts = email.split('@');
  if (parts.length != 2 ||
      parts[0].isEmpty ||
      parts[0].length > 64 ||
      parts[0].startsWith('.') ||
      parts[0].endsWith('.') ||
      parts[0].contains('..') ||
      parts[1].length > 253 ||
      !parts[1].contains('.') ||
      parts[1].startsWith('.') ||
      parts[1].endsWith('.') ||
      !RegExp(r"^[a-z0-9.!#\$%&'*+/=?^_`{|}~-]+$").hasMatch(parts[0]) ||
      !RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$').hasMatch(parts[1]) ||
      parts[1]
          .split('.')
          .any(
            (label) =>
                label.length > 63 ||
                label.startsWith('-') ||
                label.endsWith('-'),
          )) {
    throw _failure('emailInvalido');
  }
  return email;
}

abstract class ConviteStore {
  Future<EmailWhitelist?> buscar(Session session, String email);
  Future<ReservaConvite> reservar(
    Session session,
    String email,
    bool reenviar,
    DateTime agora,
  );
  Future<void> concluir(
    Session session,
    String email,
    ReservaConvite reserva,
    DateTime enviadoEm,
  );
  Future<void> liberar(Session session, String email, ReservaConvite reserva);
}

class ReservaConvite {
  const ReservaConvite(this.id, this.nova);
  final String id;
  final bool nova;
}

class PostgresConviteStore implements ConviteStore {
  const PostgresConviteStore();

  @override
  Future<EmailWhitelist?> buscar(Session session, String email) =>
      EmailWhitelist.db.findFirstRow(
        session,
        where: (t) => t.emailNormalizado.equals(email),
      );

  @override
  Future<ReservaConvite> reservar(
    Session session,
    String email,
    bool reenviar,
    DateTime agora,
  ) => session.db.transaction((transaction) async {
    await _lock(session, transaction, email);
    final atual = await EmailWhitelist.db.findFirstRow(
      session,
      where: (t) => t.emailNormalizado.equals(email),
      lockMode: LockMode.forUpdate,
      transaction: transaction,
    );
    if (atual?.utilizadoEm != null) throw _failure('jaProvisionado');
    final recuperarReserva =
        atual != null &&
        atual.ultimoConviteEm == null &&
        atual.conviteReservaId != null &&
        atual.conviteReservadoAte?.isAfter(agora) != true;
    if (!reenviar && atual != null && !recuperarReserva) {
      throw _failure('jaConvidado');
    }
    if (reenviar && atual == null) throw _failure('conviteNaoEncontrado');
    if (atual?.conviteReservadoAte?.isAfter(agora) == true) {
      throw _failure('aguardeReenvio');
    }
    if (atual?.ultimoConviteEm != null &&
        agora.difference(atual!.ultimoConviteEm!.toUtc()) <
            const Duration(minutes: 15)) {
      throw _failure('aguardeReenvio');
    }

    final random = Random.secure();
    final id = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final reservadoAte = agora.add(const Duration(minutes: 2));
    if (atual == null) {
      await EmailWhitelist.db.insertRow(
        session,
        EmailWhitelist(
          emailNormalizado: email,
          createdAt: agora,
          conviteReservaId: id,
          conviteReservadoAte: reservadoAte,
        ),
        transaction: transaction,
      );
    } else {
      await EmailWhitelist.db.updateById(
        session,
        atual.id!,
        columnValues: (t) => [
          t.conviteReservaId(id),
          t.conviteReservadoAte(reservadoAte),
        ],
        transaction: transaction,
      );
    }
    return ReservaConvite(id, atual == null || recuperarReserva);
  });

  @override
  Future<void> concluir(
    Session session,
    String email,
    ReservaConvite reserva,
    DateTime enviadoEm,
  ) => session.db.transaction((transaction) async {
    await _lock(session, transaction, email);
    final row = await EmailWhitelist.db.findFirstRow(
      session,
      where: (t) => t.emailNormalizado.equals(email),
      lockMode: LockMode.forUpdate,
      transaction: transaction,
    );
    if (row?.conviteReservaId != reserva.id) {
      throw _failure('conviteIndisponivel');
    }
    await EmailWhitelist.db.updateById(
      session,
      row!.id!,
      columnValues: (t) => [
        t.ultimoConviteEm(enviadoEm),
        t.conviteReservaId(null),
        t.conviteReservadoAte(null),
      ],
      transaction: transaction,
    );
  });

  @override
  Future<void> liberar(
    Session session,
    String email,
    ReservaConvite reserva,
  ) => session.db.transaction((transaction) async {
    await _lock(session, transaction, email);
    final row = await EmailWhitelist.db.findFirstRow(
      session,
      where: (t) => t.emailNormalizado.equals(email),
      lockMode: LockMode.forUpdate,
      transaction: transaction,
    );
    if (row == null || row.conviteReservaId != reserva.id) return;
    if (reserva.nova && row.utilizadoEm == null) {
      await EmailWhitelist.db.deleteRow(session, row, transaction: transaction);
    } else {
      await EmailWhitelist.db.updateById(
        session,
        row.id!,
        columnValues: (t) => [
          t.conviteReservaId(null),
          t.conviteReservadoAte(null),
        ],
        transaction: transaction,
      );
    }
  });

  Future<void> _lock(
    Session session,
    Transaction transaction,
    String email,
  ) async {
    // Serializes the absent-row case across processes; released before HTTP.
    await session.db.unsafeQuery(
      'SELECT pg_advisory_xact_lock(1543623471, hashtext(@email))',
      transaction: transaction,
      parameters: QueryParameters.named({'email': email}),
    );
  }
}

abstract class ConviteSender {
  Future<void> enviar(String email);
}

class SupabaseConviteSender implements ConviteSender {
  SupabaseConviteSender({http.Client? client, Map<String, String>? environment})
    : _client = client ?? http.Client(),
      _environment = environment ?? Platform.environment;

  final http.Client _client;
  final Map<String, String> _environment;

  @override
  Future<void> enviar(String email) async {
    final url = _environment['SUPABASE_URL'];
    final key = _environment['SUPABASE_SECRET_KEY'];
    final redirect = _environment['SUPABASE_INVITE_REDIRECT_URL'];
    final origin = url == null ? null : Uri.tryParse(url);
    final redirectUri = redirect == null ? null : Uri.tryParse(redirect);
    if (origin == null ||
        origin.scheme != 'https' ||
        origin.host.isEmpty ||
        origin.userInfo.isNotEmpty ||
        origin.hasQuery ||
        origin.hasFragment ||
        (origin.path.isNotEmpty && origin.path != '/') ||
        key == null ||
        !key.startsWith('sb_secret_') ||
        redirectUri == null ||
        !redirectUri.hasScheme ||
        redirectUri.host.isEmpty ||
        redirectUri.userInfo.isNotEmpty ||
        redirectUri.hasFragment ||
        const {'javascript', 'data', 'file', 'about'}.contains(
          redirectUri.scheme,
        ) ||
        (redirectUri.scheme == 'http' &&
            redirectUri.host != 'localhost' &&
            redirectUri.host != '127.0.0.1' &&
            redirectUri.host != '::1')) {
      throw _failure('conviteNaoConfigurado');
    }

    final endpoint = origin.replace(
      path: '/auth/v1/invite',
      queryParameters: {'redirect_to': redirect},
    );
    final request = http.Request('POST', endpoint)
      ..followRedirects = false
      ..headers['apikey'] = key
      ..headers['content-type'] = 'application/json'
      ..body = jsonEncode({'email': email});
    try {
      final response = await _client
          .send(request)
          .timeout(const Duration(seconds: 8));
      await response.stream.drain<void>().timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) return;
      if (response.statusCode == 429) throw _failure('limiteSupabase');
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw _failure('conviteNaoConfigurado');
      }
      if (response.statusCode >= 400 && response.statusCode < 500) {
        throw _failure('conviteRecusado');
      }
      throw _failure('conviteIndisponivel');
    } on ConviteException {
      rethrow;
    } catch (_) {
      // Do not expose the secret, request body or Supabase response.
      throw _failure('conviteIndisponivel');
    }
  }
}

class ConviteRateLimiter {
  ConviteRateLimiter({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  final Map<String, DateTime> _emailBlockedUntil = {};
  final Map<int, List<DateTime>> _adminAttempts = {};

  DateTime agora() => _now().toUtc();

  void reservar(int adminId, String email) {
    final now = agora();
    _emailBlockedUntil.removeWhere((_, until) => !until.isAfter(now));
    _adminAttempts.removeWhere((_, attempts) {
      attempts.removeWhere(
        (at) => !at.add(const Duration(hours: 1)).isAfter(now),
      );
      return attempts.isEmpty;
    });
    if (_emailBlockedUntil[email]?.isAfter(now) == true) {
      throw _failure('aguardeReenvio');
    }
    final attempts = _adminAttempts.putIfAbsent(adminId, () => []);
    if (attempts.length >= 20 || _emailBlockedUntil.length >= 10000) {
      throw _failure('limiteEnvios');
    }
    attempts.add(now);
  }

  void falhou(String email) {
    // A timeout may happen after Supabase has accepted the invitation.
    _emailBlockedUntil[email] = agora().add(const Duration(minutes: 1));
  }
}

class ConviteService {
  ConviteService({
    required ConviteStore store,
    required ConviteSender sender,
    required ConviteRateLimiter rateLimiter,
  }) : _store = store,
       _sender = sender,
       _rateLimiter = rateLimiter;

  factory ConviteService.production() => ConviteService(
    store: const PostgresConviteStore(),
    sender: SupabaseConviteSender(),
    rateLimiter: _sharedLimiter,
  );

  static final ConviteRateLimiter _sharedLimiter = ConviteRateLimiter();
  final ConviteStore _store;
  final ConviteSender _sender;
  final ConviteRateLimiter _rateLimiter;

  Future<String> consultar(Session session, String input) async {
    final email = normalizarEmail(input);
    final row = await _store.buscar(session, email);
    if (row == null) return 'ausente';
    return row.utilizadoEm == null ? 'pendente' : 'provisionado';
  }

  Future<String> enviar(
    Session session,
    int adminId,
    String input, {
    required bool reenviar,
  }) async {
    final email = normalizarEmail(input);
    _rateLimiter.reservar(adminId, email);
    final reserva = await _store.reservar(
      session,
      email,
      reenviar,
      _rateLimiter.agora(),
    );
    try {
      await _sender.enviar(email);
    } catch (_) {
      _rateLimiter.falhou(email);
      await _store.liberar(session, email, reserva);
      rethrow;
    }
    await _store.concluir(session, email, reserva, _rateLimiter.agora());
    return reenviar ? 'reenviado' : 'enviado';
  }
}
