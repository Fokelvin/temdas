import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jose/jose.dart';
// Serverpod's test-only helpers are intentionally internal in 3.4.11.
// ignore: implementation_imports
import 'package:serverpod/src/server/server.dart';
// ignore: implementation_imports
import 'package:serverpod/src/server/session.dart';
import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Supabase internal Usuario resolution', (
    sessionBuilder,
    endpoints,
  ) {
    test('auth.me rejects missing token', () async {
      await expectLater(
        endpoints.auth.me(sessionBuilder),
        throwsA(
          isA<AuthException>().having(
            (e) => e.codigo,
            'codigo',
            'tokenMissing',
          ),
        ),
      );
    });

    test('sub selects the correct database row and AAL2 is required', () async {
      final session = sessionBuilder.build();
      session.server.setAuthenticationHandlerForTesting(
        (session, token) async => null,
      );
      final usuario = await Usuario.db.insertRow(
        session,
        Usuario(
          supabaseUserId: 'auth-test-sub',
          createdAt: DateTime.now().toUtc(),
        ),
      );
      final private = JsonWebKey.fromJson({
        ...JsonWebKey.generate('ES256').toJson(),
        'kid': 'test-key',
        'alg': 'ES256',
      });
      final public = Map.of(private.toJson())..remove('d');
      final service = SupabaseAuthService(
        supabaseUrl: 'https://project.supabase.co',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'keys': [public],
            }),
            200,
          ),
        ),
      );
      String token(String sub, String aal) {
        final builder = JsonWebSignatureBuilder()
          ..jsonContent = {
            'sub': sub,
            'aal': aal,
            'iss': service.issuer,
            'aud': 'authenticated',
            'exp':
                DateTime.now()
                    .add(const Duration(hours: 1))
                    .millisecondsSinceEpoch ~/
                1000,
          };
        builder.addRecipient(private, algorithm: 'ES256');
        return builder.build().toCompactSerialization();
      }

      await session.updateAuthenticationKey(
        token(usuario.supabaseUserId, 'aal2'),
      );
      final authenticated = await requireAal2Usuario(
        session,
        authService: service,
      );
      expect(authenticated.usuario.id, usuario.id);
      expect(authenticated.supabaseUserId, usuario.supabaseUserId);
      await session.updateAuthenticationKey(
        token(usuario.supabaseUserId, 'aal1'),
      );
      await expectLater(
        requireAal2Usuario(session, authService: service),
        throwsA(
          isA<AuthException>().having(
            (e) => e.codigo,
            'codigo',
            'aal2Required',
          ),
        ),
      );
      await session.updateAuthenticationKey(token('unknown-sub', 'aal2'));
      await expectLater(
        requireAuthenticatedUsuario(session, authService: service),
        throwsA(
          isA<AuthException>().having(
            (e) => e.codigo,
            'codigo',
            'usuarioNotFound',
          ),
        ),
      );
    });
  });
}
