import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jose/jose.dart';
import 'package:serverpod/serverpod.dart' show Session;
import 'package:temdas_backend_server/src/auth/auth_endpoint.dart';
import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  final privateKey = JsonWebKey.fromJson({
    ...JsonWebKey.generate('ES256').toJson(),
    'kid': 'key-1',
    'alg': 'ES256',
  });
  final otherKey = JsonWebKey.fromJson({
    ...JsonWebKey.generate('ES256').toJson(),
    'kid': 'key-2',
    'alg': 'ES256',
  });
  Map<String, dynamic> public(JsonWebKey key) =>
      Map.of(key.toJson())..remove('d');
  late DateTime now;
  late int fetches;
  late List<Map<String, dynamic>> keys;
  late SupabaseAuthService service;
  late int httpStatus;
  late String? malformedBody;

  String token({
    Map<String, dynamic> claims = const {},
    JsonWebKey? key,
    String algorithm = 'ES256',
    Map<String, dynamic> headers = const {},
  }) {
    final builder = JsonWebSignatureBuilder()
      ..jsonContent = {
        'iss': 'https://project.supabase.co/auth/v1',
        'sub': 'supabase-user',
        'aal': 'aal2',
        'aud': 'authenticated',
        'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        ...claims,
      };
    headers.forEach(builder.setProtectedHeader);
    builder.addRecipient(key ?? privateKey, algorithm: algorithm);
    return builder.build().toCompactSerialization();
  }

  Matcher error(String code) => throwsA(
    isA<AuthException>().having(
      (e) => e.codigo,
      'codigo',
      code,
    ),
  );

  setUp(() {
    now = DateTime.utc(2026, 10, 1);
    fetches = 0;
    httpStatus = 200;
    malformedBody = null;
    keys = [public(privateKey)];
    service = SupabaseAuthService(
      supabaseUrl: 'https://project.supabase.co/',
      now: () => now,
      httpClient: MockClient((request) async {
        fetches++;
        expect(
          request.url.toString(),
          'https://project.supabase.co/auth/v1/.well-known/jwks.json',
        );
        expect(request.followRedirects, isFalse);
        return http.Response(
          malformedBody ?? jsonEncode({'keys': keys}),
          httpStatus,
        );
      }),
    );
  });

  test('missing and malformed token', () async {
    await expectLater(service.validateToken(null), error('tokenMissing'));
    await expectLater(service.validateToken('bad'), error('tokenInvalid'));
    expect(fetches, 0);
  });

  test('expired, including exact expiration boundary', () async {
    await expectLater(
      service.validateToken(
        token(
          claims: {
            'exp': now.millisecondsSinceEpoch ~/ 1000,
          },
        ),
      ),
      error('tokenExpired'),
    );
  });

  test('issuer, sub, exp, aal and audience are mandatory', () async {
    for (final claims in <Map<String, dynamic>>[
      {'iss': 'https://attacker.invalid/auth/v1'},
      {'sub': ''},
      {'sub': '  '},
      {'sub': null},
      {'exp': null},
      {'exp': '9999999999'},
      {'aal': null},
      {'aal': 'aal3'},
      {'aud': 'service_role'},
      {
        'nbf':
            now.add(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000,
      },
    ]) {
      await expectLater(
        service.validateToken(token(claims: claims)),
        error('tokenInvalid'),
      );
    }
  });

  test('invalid signature and unknown kid', () async {
    final impostor = JsonWebKey.fromJson({
      ...otherKey.toJson(),
      'kid': 'key-1',
    });
    await expectLater(
      service.validateToken(token(key: impostor)),
      error('tokenInvalid'),
    );
    await expectLater(
      service.validateToken(token(key: otherKey)),
      error('tokenInvalid'),
    );
  });

  test('rejects none, HS256, absent kid, critical extensions', () async {
    final unsigned = JsonWebSignatureBuilder()..jsonContent = {'sub': 'fake'};
    unsigned.addRecipient(null, algorithm: 'none');
    await expectLater(
      service.validateToken(unsigned.build().toCompactSerialization()),
      error('tokenInvalid'),
    );
    await expectLater(
      service.validateToken(
        token(
          key: JsonWebKey.generate('HS256'),
          algorithm: 'HS256',
        ),
      ),
      error('tokenInvalid'),
    );
    final noKid = JsonWebKey.fromJson(
      Map.of(privateKey.toJson())..remove('kid'),
    );
    await expectLater(
      service.validateToken(token(key: noKid)),
      error('tokenInvalid'),
    );
    await expectLater(
      service.validateToken(
        token(
          headers: {
            'crit': ['custom'],
          },
        ),
      ),
      error('tokenInvalid'),
    );
    expect(fetches, 0);
  });

  test('aal1 authenticates but functional access requires aal2', () async {
    final usuario = Usuario(
      id: 42,
      supabaseUserId: 'supabase-user',
      createdAt: now,
    );
    Future<Usuario?> lookup(String sub) async {
      expect(sub, usuario.supabaseUserId);
      return usuario;
    }

    final result = await service.authenticate(
      token(claims: {'aal': 'aal1'}),
      findUsuario: lookup,
    );
    expect(result.aal, 'aal1');
    await expectLater(
      service.authenticate(
        token(claims: {'aal': 'aal1'}),
        findUsuario: lookup,
        requireAal2: true,
      ),
      error('aal2Required'),
    );
    final aal2 = await service.authenticate(
      token(),
      findUsuario: lookup,
      requireAal2: true,
    );
    expect(aal2.usuario, same(usuario));
    expect(aal2.supabaseUserId, 'supabase-user');
    expect(aal2.aal, 'aal2');
  });

  test('valid Supabase user without internal Usuario', () async {
    await expectLater(
      service.authenticate(token(), findUsuario: (_) async => null),
      error('usuarioNotFound'),
    );
  });

  test('cached requests and concurrent fetches share one JWKS', () async {
    await Future.wait(List.generate(10, (_) => service.validateToken(token())));
    expect(fetches, 1);
  });

  test('unknown kid refreshes with cooldown, rotation works', () async {
    await service.validateToken(token());
    keys = [public(privateKey), public(otherKey)];
    await expectLater(
      service.validateToken(token(key: otherKey)),
      error('tokenInvalid'),
    );
    expect(fetches, 1);
    now = now.add(const Duration(seconds: 31));
    expect((await service.validateToken(token(key: otherKey))).aal, 'aal2');
    expect(fetches, 2);
    await expectLater(
      service.validateToken(
        token(
          key: JsonWebKey.fromJson({...privateKey.toJson(), 'kid': 'unknown'}),
        ),
      ),
      error('tokenInvalid'),
    );
    expect(fetches, 2);
  });

  test('expired cache refreshes and removed keys no longer verify', () async {
    await service.validateToken(token());
    now = now.add(const Duration(minutes: 11));
    keys = [public(otherKey)];
    await expectLater(service.validateToken(token()), error('tokenInvalid'));
    expect(fetches, 2);
  });

  test('JWKS failure and malformed responses fail closed', () async {
    httpStatus = 503;
    await expectLater(service.validateToken(token()), error('jwksUnavailable'));
    expect(fetches, 1);
    now = now.add(const Duration(seconds: 31));
    httpStatus = 200;
    malformedBody = 'not json';
    await expectLater(service.validateToken(token()), error('jwksUnavailable'));
  });

  test('expired cached keys are never used during outage', () async {
    await service.validateToken(token());
    now = now.add(const Duration(minutes: 11));
    httpStatus = 503;
    await expectLater(service.validateToken(token()), error('jwksUnavailable'));
    await expectLater(service.validateToken(token()), error('jwksUnavailable'));
    expect(fetches, 2);
  });

  test('reject mismatched JWK algorithm and use', () async {
    keys = [
      {...public(privateKey), 'alg': 'ES384'},
    ];
    await expectLater(service.validateToken(token()), error('tokenInvalid'));
    now = now.add(const Duration(minutes: 11));
    keys = [
      {...public(privateKey), 'use': 'enc'},
    ];
    await expectLater(service.validateToken(token()), error('tokenInvalid'));
  });
  test('RS256 is verified with an RSA public JWK', () async {
    final rsa = JsonWebKey.fromJson({
      ...JsonWebKey.generate('RS256', keyBitLength: 2048).toJson(),
      'kid': 'rsa-key',
      'alg': 'RS256',
    });
    keys = [
      {
        for (final field in ['kty', 'n', 'e', 'kid', 'alg']) field: rsa[field],
      },
    ];
    expect(
      (await service.validateToken(token(key: rsa, algorithm: 'RS256'))).aal,
      'aal2',
    );
  });

  test(
    'request claims are reused and changing token invalidates them',
    () async {
      final session = _TokenSession(token());
      expect((await service.claimsForSession(session)).aal, 'aal2');
      session.token = token(claims: {'aal': 'aal1'});
      expect((await service.claimsForSession(session)).aal, 'aal1');
      session.token = null;
      await expectLater(
        service.claimsForSession(session),
        error('tokenMissing'),
      );
    },
  );

  test('auth.me reports tokenMissing without configuration or DB', () async {
    await expectLater(
      AuthEndpoint().me(_TokenSession(null)),
      error('tokenMissing'),
    );
  });
}

class _TokenSession implements Session {
  String? token;
  _TokenSession(this.token);
  @override
  String? get authenticationKey => token;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
