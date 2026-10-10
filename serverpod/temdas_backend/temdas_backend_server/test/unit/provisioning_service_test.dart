import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jose/jose.dart';
import 'package:serverpod/serverpod.dart' show Session;
import 'package:temdas_backend_server/src/auth/auth_endpoint.dart';
import 'package:temdas_backend_server/src/auth/provisioning_service.dart';
import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  const sub = '11111111-1111-4111-8111-111111111111';
  const otherSub = '22222222-2222-4222-8222-222222222222';
  final signingKey = JsonWebKey.fromJson({
    ...JsonWebKey.generate('ES256').toJson(),
    'kid': 'onboarding-key',
    'alg': 'ES256',
  });
  final publicKey = Map<String, dynamic>.of(signingKey.toJson())..remove('d');
  final now = DateTime.utc(2026, 10, 8);

  String token({
    String userId = sub,
    String aal = 'aal1',
    Map<String, dynamic> claims = const {},
  }) {
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = {
        'iss': 'https://project.supabase.co/auth/v1',
        'sub': userId,
        'aal': aal,
        'aud': 'authenticated',
        'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        // This value must never be used for provisioning.
        'email': 'attacker@example.com',
        ...claims,
      };
    builder.addRecipient(signingKey, algorithm: 'ES256');
    return builder.build().toCompactSerialization();
  }

  Matcher authError(String code) => throwsA(
    isA<AuthException>().having((error) => error.codigo, 'codigo', code),
  );

  late _FakeEmailSource emails;
  late _MemoryStore store;
  late AuthEndpoint endpoint;
  setUp(() {
    emails = _FakeEmailSource('  Pessoa@EXAMPLE.COM  ');
    store = _MemoryStore(now);
    store.whitelist['pessoa@example.com'] = EmailWhitelist(
      id: 10,
      emailNormalizado: 'pessoa@example.com',
      createdAt: now,
    );
    final auth = SupabaseAuthService(
      supabaseUrl: 'https://project.supabase.co',
      now: () => now,
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'keys': [publicKey],
          }),
          200,
        ),
      ),
    );
    endpoint = AuthEndpoint(
      authService: auth,
      provisioningService: ProvisioningService(
        emailSource: emails,
        store: store,
      ),
    );
  });
  tearDown(() => setUsuarioResolverForTesting(null));

  test('only a valid AAL1 or AAL2 JWT reaches onboarding', () async {
    await expectLater(
      endpoint.provisionar(_TokenSession(null)),
      authError('tokenMissing'),
    );
    await expectLater(
      endpoint.provisionar(_TokenSession('bad')),
      authError('tokenInvalid'),
    );
    await expectLater(
      endpoint.provisionar(_TokenSession(token(aal: 'aal3'))),
      authError('tokenInvalid'),
    );
    await expectLater(
      endpoint.provisionar(
        _TokenSession(
          token(
            claims: {
              'exp': now.millisecondsSinceEpoch ~/ 1000,
            },
          ),
        ),
      ),
      authError('tokenExpired'),
    );
    await expectLater(
      endpoint.provisionar(
        _TokenSession(token(claims: {'aud': 'service_role'})),
      ),
      authError('tokenInvalid'),
    );
    expect(emails.lookups, isEmpty);
    expect(store.users, isEmpty);

    final first = await endpoint.provisionar(_TokenSession(token()));
    final second = await endpoint.provisionar(
      _TokenSession(token(aal: 'aal2')),
    );
    expect(first.usuarioId, second.usuarioId);
    expect(first.aal, 'aal1');
    expect(second.aal, 'aal2');
    expect(first.isAdmin, isFalse);
    expect(second.isAdmin, isFalse);
    expect(emails.lookups, [sub, sub]);
    expect(store.users[sub]!.isAdmin, isFalse);
    expect(store.whitelist['pessoa@example.com']!.utilizadoEm, now);
    expect(store.creations, 1);
  });

  test(
    'JWT email is ignored and absent whitelist rejects without writes',
    () async {
      emails.email = 'other@example.com';
      await expectLater(
        endpoint.provisionar(_TokenSession(token())),
        authError('emailNaoAutorizado'),
      );
      expect(store.users, isEmpty);
      expect(store.whitelist['pessoa@example.com']!.utilizadoEm, isNull);
    },
  );

  test('unconfirmed email and malformed source email fail closed', () async {
    emails.failure = AuthException(codigo: 'emailNaoConfirmado');
    await expectLater(
      endpoint.provisionar(_TokenSession(token())),
      authError('emailNaoConfirmado'),
    );
    emails.failure = null;
    emails.email = 'not-an-email';
    await expectLater(
      endpoint.provisionar(_TokenSession(token())),
      authError('emailInvalido'),
    );
    expect(store.users, isEmpty);
  });

  test('existing admin and consumed timestamp are preserved', () async {
    final admin = Usuario(
      id: 77,
      supabaseUserId: sub,
      isAdmin: true,
      createdAt: now.subtract(const Duration(days: 1)),
    );
    store.users[sub] = admin;
    store.whitelist['pessoa@example.com']!.utilizadoEm = now.subtract(
      const Duration(hours: 1),
    );
    final result = await endpoint.provisionar(_TokenSession(token()));
    expect(result.usuarioId, 77);
    expect(result.isAdmin, isTrue);
    expect(store.users[sub], same(admin));
    expect(admin.isAdmin, isTrue);
    expect(
      store.whitelist['pessoa@example.com']!.utilizadoEm,
      now.subtract(const Duration(hours: 1)),
    );
    expect(store.creations, 0);
  });

  test('existing admin without whitelist keeps identity and role', () async {
    store.whitelist.clear();
    final admin = Usuario(
      id: 77,
      supabaseUserId: sub,
      isAdmin: true,
      createdAt: now,
    );
    store.users[sub] = admin;

    final result = await endpoint.provisionar(
      _TokenSession(token(claims: {'isAdmin': false})),
    );
    expect(result.usuarioId, admin.id);
    expect(result.isAdmin, isTrue);
    expect(store.users[sub], same(admin));
    expect(store.creations, 0);
    expect(emails.lookups, [sub]);
  });

  test('existing common user without whitelist stays non-admin', () async {
    store.whitelist.clear();
    final common = Usuario(
      id: 78,
      supabaseUserId: sub,
      isAdmin: false,
      createdAt: now,
    );
    store.users[sub] = common;

    final result = await endpoint.provisionar(
      _TokenSession(token(claims: {'isAdmin': true})),
    );
    expect(result.usuarioId, common.id);
    expect(result.isAdmin, isFalse);
    expect(store.users[sub], same(common));
    expect(store.creations, 0);
  });

  test(
    'existing user still requires valid JWT and confirmed identity',
    () async {
      store.whitelist.clear();
      store.users[sub] = Usuario(
        id: 77,
        supabaseUserId: sub,
        isAdmin: true,
        createdAt: now,
      );
      await expectLater(
        endpoint.provisionar(_TokenSession('invalid')),
        authError('tokenInvalid'),
      );
      emails.failure = AuthException(codigo: 'emailNaoConfirmado');
      await expectLater(
        endpoint.provisionar(_TokenSession(token())),
        authError('emailNaoConfirmado'),
      );
      expect(store.users[sub]!.isAdmin, isTrue);
      expect(store.creations, 0);
    },
  );

  test('another sub cannot claim an existing user by email', () async {
    store.whitelist.clear();
    store.users[sub] = Usuario(
      id: 77,
      supabaseUserId: sub,
      isAdmin: true,
      createdAt: now,
    );
    await expectLater(
      endpoint.provisionar(_TokenSession(token(userId: otherSub))),
      authError('emailNaoAutorizado'),
    );
    expect(store.users.keys, [sub]);
    expect(store.creations, 0);
  });

  test('consumed whitelist cannot create another user', () async {
    store.whitelist['pessoa@example.com']!.utilizadoEm = now;
    await expectLater(
      endpoint.provisionar(_TokenSession(token(userId: otherSub))),
      authError('conviteJaUtilizado'),
    );
    expect(store.users, isEmpty);
  });

  test('concurrent repetitions create one user and consume once', () async {
    final release = Completer<void>();
    emails.waitFor = release.future;
    final calls = [
      endpoint.provisionar(_TokenSession(token())),
      endpoint.provisionar(_TokenSession(token(aal: 'aal2'))),
    ];
    release.complete();
    final results = await Future.wait(calls);
    expect(results.map((r) => r.usuarioId).toSet(), hasLength(1));
    expect(store.creations, 1);
    expect(store.whitelist['pessoa@example.com']!.utilizadoEm, now);
  });

  test(
    'concurrent different subjects cannot consume one email twice',
    () async {
      final release = Completer<void>();
      emails.waitFor = release.future;
      final first = endpoint.provisionar(_TokenSession(token()));
      final second = expectLater(
        endpoint.provisionar(_TokenSession(token(userId: otherSub))),
        authError('conviteJaUtilizado'),
      );
      release.complete();
      expect((await first).usuarioId, 100);
      await second;
      expect(store.users.keys, [sub]);
      expect(store.creations, 1);
    },
  );

  test('auth.me reads admin from Usuario and still requires AAL2', () async {
    final existing = Usuario(id: 9, supabaseUserId: sub, createdAt: now);
    setUsuarioResolverForTesting(
      (_) async => AuthenticatedUsuario(existing, sub, 'aal1'),
    );
    await expectLater(
      endpoint.me(_TokenSession(token())),
      authError('aal2Required'),
    );
    setUsuarioResolverForTesting(
      (_) async => AuthenticatedUsuario(existing, sub, 'aal2'),
    );
    final common = await endpoint.me(
      _TokenSession(token(aal: 'aal2', claims: {'isAdmin': true})),
    );
    expect(common.usuarioId, 9);
    expect(common.aal, 'aal2');
    expect(common.isAdmin, isFalse);

    final admin = existing.copyWith(isAdmin: true);
    setUsuarioResolverForTesting(
      (_) async => AuthenticatedUsuario(admin, sub, 'aal2'),
    );
    final elevated = await endpoint.me(
      _TokenSession(token(aal: 'aal2', claims: {'isAdmin': false})),
    );
    expect(elevated.usuarioId, 9);
    expect(elevated.aal, 'aal2');
    expect(elevated.isAdmin, isTrue);
  });

  test('auth.me rejects an identity without an internal Usuario', () async {
    setUsuarioResolverForTesting(
      (_) async => throw AuthException(codigo: 'usuarioNotFound'),
    );
    await expectLater(
      endpoint.me(_TokenSession(token(userId: otherSub, aal: 'aal2'))),
      authError('usuarioNotFound'),
    );
  });

  test(
    'Supabase admin source requires confirmed email for matching sub',
    () async {
      Map<String, dynamic> body = {
        'id': sub,
        'email': 'Pessoa@Example.com',
        'email_confirmed_at': '2026-10-08T00:00:00Z',
        'is_anonymous': false,
      };
      var status = 200;
      final source = SupabaseConfirmedEmailSource(
        environment: {
          'SUPABASE_URL': 'https://project.supabase.co',
          'SUPABASE_SECRET_KEY': 'sb_secret_test',
        },
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, '/auth/v1/admin/users/$sub');
          expect(request.followRedirects, isFalse);
          expect(request.headers['apikey'], 'sb_secret_test');
          expect(request.headers.containsKey('authorization'), isFalse);
          return http.Response(jsonEncode(body), status);
        }),
      );
      expect(await source.emailForUser(sub), 'Pessoa@Example.com');
      body = {...body, 'email_confirmed_at': null};
      await expectLater(
        source.emailForUser(sub),
        authError('emailNaoConfirmado'),
      );
      body = {
        ...body,
        'email_confirmed_at': '2026-10-08T00:00:00Z',
        'id': otherSub,
      };
      await expectLater(
        source.emailForUser(sub),
        authError('authIndisponivel'),
      );
      status = 404;
      await expectLater(
        source.emailForUser(sub),
        authError('usuarioSupabaseNaoEncontrado'),
      );
      status = 503;
      await expectLater(
        source.emailForUser(sub),
        authError('authIndisponivel'),
      );
      status = 200;
      body = {...body, 'id': sub, 'is_anonymous': true};
      await expectLater(
        source.emailForUser(sub),
        authError('emailNaoConfirmado'),
      );
    },
  );

  test(
    'admin source fails closed without server secret or on denial',
    () async {
      final unconfigured = SupabaseConfirmedEmailSource(
        environment: {
          'SUPABASE_URL': 'https://project.supabase.co',
        },
      );
      await expectLater(
        unconfigured.emailForUser(sub),
        authError('authNaoConfigurado'),
      );
      final denied = SupabaseConfirmedEmailSource(
        environment: {
          'SUPABASE_URL': 'https://project.supabase.co',
          'SUPABASE_SECRET_KEY': 'sb_secret_test',
        },
        client: MockClient((_) async => http.Response('private', 403)),
      );
      await expectLater(
        denied.emailForUser(sub),
        authError('authNaoConfigurado'),
      );
    },
  );
}

class _TokenSession implements Session {
  _TokenSession(this.authenticationKey);
  @override
  final String? authenticationKey;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEmailSource implements ConfirmedEmailSource {
  _FakeEmailSource(this.email);
  String email;
  Object? failure;
  Future<void>? waitFor;
  final List<String> lookups = [];

  @override
  Future<String> emailForUser(String supabaseUserId) async {
    lookups.add(supabaseUserId);
    if (waitFor != null) await waitFor;
    if (failure != null) throw failure!;
    return email;
  }
}

class _MemoryStore implements ProvisioningStore {
  _MemoryStore(this.now);
  final DateTime now;
  final Map<String, EmailWhitelist> whitelist = {};
  final Map<String, Usuario> users = {};
  int creations = 0;

  @override
  Future<Usuario> provisionar(Session session, String sub, String email) async {
    final existing = users[sub];
    if (existing != null) return existing;
    final row = whitelist[email];
    if (row == null) throw AuthException(codigo: 'emailNaoAutorizado');
    if (row.utilizadoEm != null) {
      throw AuthException(codigo: 'conviteJaUtilizado');
    }
    final usuario = Usuario(
      id: 100 + creations++,
      supabaseUserId: sub,
      isAdmin: false,
      createdAt: now,
    );
    users[sub] = usuario;
    row.utilizadoEm ??= now;
    return usuario;
  }
}
