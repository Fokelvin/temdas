import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/app/auth_gate.dart';
import 'package:temdas/data/auth_provisioning.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas/view/auth_pages.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  testWidgets('sign-in while gate is mounted provisions before MFA', (
    tester,
  ) async {
    final server = _AuthServer();
    var calls = 0;
    final provisioning = AuthProvisioning(
      provisionar: () async {
        calls++;
        return _me(7, 'aal1');
      },
    );
    await tester.pumpWidget(_app(server, provisioning));
    await tester.pumpAndSettle();
    expect(find.text('Entrar no TEMDAS'), findsOneWidget);
    expect(calls, 0);
    await server.signIn();
    await tester.pumpAndSettle();
    expect(find.byType(MfaEnrollPage), findsOneWidget);
    expect(calls, 1);
  });

  testWidgets(
    'AAL1 provisions before TOTP enrollment and reuses result on remount',
    (tester) async {
      final server = _AuthServer();
      await server.signIn();
      final pending = Completer<backend.AuthMe>();
      var calls = 0;
      final provisioning = AuthProvisioning(
        provisionar: () {
          calls++;
          return pending.future;
        },
      );

      await tester.pumpWidget(_app(server, provisioning));
      await tester.pump();
      expect(find.text('Verificando sessão…'), findsOneWidget);
      expect(find.byType(MfaEnrollPage), findsNothing);
      pending.complete(_me(11, 'aal1'));
      await tester.pumpAndSettle();
      expect(find.byType(MfaEnrollPage), findsOneWidget);
      expect(find.text('protected'), findsNothing);
      expect(calls, 1);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(_app(server, provisioning));
      await tester.pumpAndSettle();
      expect(find.byType(MfaEnrollPage), findsOneWidget);
      expect(calls, 1);
    },
  );

  testWidgets('existing AAL1 user reaches current TOTP challenge', (
    tester,
  ) async {
    final server = _AuthServer()..verifiedTotp = true;
    await server.signIn();
    var calls = 0;
    final provisioning = AuthProvisioning(
      provisionar: () async {
        calls++;
        return _me(17, 'aal1');
      },
    );
    await tester.pumpWidget(_app(server, provisioning));
    await tester.pumpAndSettle();
    expect(find.byType(MfaChallengePage), findsOneWidget);
    expect(find.text('protected'), findsNothing);
    expect(calls, 1);
  });

  testWidgets('new AAL2 user waits for backend confirmation before app', (
    tester,
  ) async {
    final server = _AuthServer()..aal = 'aal2';
    await server.signIn();
    final pending = Completer<backend.AuthMe>();
    var provisionCalls = 0;
    var meCalls = 0;
    final provisioning = AuthProvisioning(
      provisionar: () async {
        provisionCalls++;
        return _me(29, 'aal2');
      },
      me: () {
        meCalls++;
        return pending.future;
      },
    );
    await tester.pumpWidget(_app(server, provisioning));
    await tester.pump();
    expect(find.text('protected'), findsNothing);
    expect(provisionCalls, 1);
    expect(meCalls, 1);
    pending.complete(_me(29, 'aal2'));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsOneWidget);

    await tester.pumpWidget(_app(server, provisioning, label: 'updated'));
    await tester.pumpAndSettle();
    expect(find.text('updated'), findsOneWidget);
    expect(provisionCalls, 1);
    expect(meCalls, 1);
  });

  testWidgets('mismatched backend identity never unlocks AAL2', (tester) async {
    final server = _AuthServer()..aal = 'aal2';
    await server.signIn();
    final provisioning = AuthProvisioning(
      provisionar: () async => _me(29, 'aal2'),
      me: () async => _me(30, 'aal2'),
    );
    await tester.pumpWidget(_app(server, provisioning));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsNothing);
    expect(find.text('Não foi possível validar a sessão'), findsOneWidget);
  });

  testWidgets('whitelist failure blocks access; retry recovers', (
    tester,
  ) async {
    final server = _AuthServer()..aal = 'aal2';
    await server.signIn();
    var calls = 0;
    final provisioning = AuthProvisioning(
      provisionar: () async {
        calls++;
        if (calls == 1) {
          throw backend.AuthException(codigo: 'emailNaoAutorizado');
        }
        return _me(41, 'aal2');
      },
      me: () async => _me(41, 'aal2'),
    );
    await tester.pumpWidget(_app(server, provisioning));
    await tester.pumpAndSettle();
    expect(
      find.text('Este e-mail não está autorizado para o TEMDAS.'),
      findsOneWidget,
    );
    expect(find.text('protected'), findsNothing);
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('old provisioning result cannot unlock a replacement session', (
    tester,
  ) async {
    final server = _AuthServer()..aal = 'aal2';
    await server.signIn();
    final first = Completer<backend.AuthMe>();
    var calls = 0;
    final provisioning = AuthProvisioning(
      provisionar: () {
        calls++;
        return calls == 1 ? first.future : Future.value(_me(52, 'aal2'));
      },
      me: () async => _me(52, 'aal2'),
    );
    await tester.pumpWidget(_app(server, provisioning));
    await tester.pump();
    await server.session.signOut();
    server.userId = 'user-2';
    await server.signIn();
    first.complete(_me(51, 'aal2'));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('old AAL2 confirmation cannot unlock a replacement session', (
    tester,
  ) async {
    final server = _AuthServer()..aal = 'aal2';
    await server.signIn();
    final first = Completer<backend.AuthMe>();
    var provisionCalls = 0;
    var meCalls = 0;
    final provisioning = AuthProvisioning(
      provisionar: () async {
        provisionCalls++;
        return _me(provisionCalls == 1 ? 71 : 72, 'aal2');
      },
      me: () {
        meCalls++;
        return meCalls == 1 ? first.future : Future.value(_me(72, 'aal2'));
      },
    );
    await tester.pumpWidget(_app(server, provisioning));
    await tester.pump();
    expect(find.text('protected'), findsNothing);

    await server.session.signOut();
    server.userId = 'user-2';
    await server.signIn();
    first.complete(_me(71, 'aal2'));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsOneWidget);
    expect(provisionCalls, 2);
    expect(meCalls, 2);
  });

  testWidgets('refresh rechecks AAL2 backend with the new token', (
    tester,
  ) async {
    final server = _AuthServer()..aal = 'aal2';
    await server.signIn();
    final pending = Completer<backend.AuthMe>();
    var provisionCalls = 0;
    var meCalls = 0;
    final provisioning = AuthProvisioning(
      provisionar: () async {
        provisionCalls++;
        return _me(61, 'aal2');
      },
      me: () {
        meCalls++;
        return meCalls == 1 ? Future.value(_me(61, 'aal2')) : pending.future;
      },
    );
    await tester.pumpWidget(_app(server, provisioning));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsOneWidget);

    await server.client.auth.refreshSession();
    await tester.pump();
    expect(find.text('protected'), findsNothing);
    expect(meCalls, 2);
    pending.complete(_me(61, 'aal2'));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsOneWidget);
    expect(provisionCalls, 1);
  });
}

Widget _app(
  _AuthServer server,
  AuthProvisioning provisioning, {
  String label = 'protected',
}) => MaterialApp(
  home: AuthGate(
    session: server.session,
    provisioning: provisioning,
    child: Scaffold(body: Text(label)),
  ),
);

backend.AuthMe _me(int usuarioId, String aal) =>
    backend.AuthMe(usuarioId: usuarioId, aal: aal, isAdmin: false);

class _AuthServer {
  String aal = 'aal1';
  String userId = 'user-1';
  bool verifiedTotp = false;
  int refreshCount = 0;

  late final SupabaseClient client = SupabaseClient(
    'http://localhost:9999',
    'sb_publishable_test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/token')) {
        if (request.url.queryParameters['grant_type'] == 'refresh_token') {
          refreshCount++;
        }
        return _json({
          'access_token': _jwt(userId, aal, refreshCount),
          'refresh_token': 'refresh-$userId',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': userId,
            'app_metadata': <String, dynamic>{},
            'user_metadata': <String, dynamic>{},
            'aud': 'authenticated',
            'created_at': '2026-01-01T00:00:00Z',
            'factors': verifiedTotp
                ? [
                    {
                      'id': 'factor-1',
                      'factor_type': 'totp',
                      'status': 'verified',
                      'created_at': '2026-01-01T00:00:00Z',
                      'updated_at': '2026-01-01T00:00:00Z',
                    },
                  ]
                : <Object>[],
          },
        });
      }
      if (request.url.path.endsWith('/logout')) {
        return http.Response('', 204);
      }
      return _json({'message': 'not found'}, statusCode: 404);
    }),
  );

  late final SupabaseSession session = SupabaseSession(client);

  Future<void> signIn() =>
      session.signInWithPassword('test@example.com', 'password').then((_) {});
}

String _jwt(String userId, String aal, int version) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'ES256'})}.${encode({'sub': userId, 'aal': aal, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000, 'version': version})}.signature';
}

http.Response _json(Map<String, dynamic> body, {int statusCode = 200}) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: {
        'content-type': 'application/json',
        'x-supabase-api-version': '2024-01-01',
      },
    );
