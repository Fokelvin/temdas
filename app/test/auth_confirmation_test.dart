import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/app/auth_gate.dart';
import 'package:temdas/app/temdas_app.dart';
import 'package:temdas/data/auth_callback.dart';
import 'package:temdas/data/auth_callback_storage.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas/view/auth_callback_page.dart';

const _hash = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef01';
const _stateKey = 'temdas.auth.callback.v1';

Uri _link(String type, {String hash = _hash}) =>
    Uri.parse('https://app.example/auth/confirm?token_hash=$hash&type=$type');

void main() {
  for (final type in ['recovery', 'invite']) {
    testWidgets('$type preview and rebuild do not consume the token', (
      tester,
    ) async {
      final server = _Server();
      final storage = _Storage()..values[_stateKey] = 'old-state';

      final page = AuthCallbackPage.confirm(
        uri: _link(type),
        session: server.session,
        storage: storage,
      );
      await tester.pumpWidget(_app(page, server.session));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpWidget(_app(page, server.session));
      await tester.pumpAndSettle();

      expect(server.requests, isEmpty);
      expect(server.client.auth.currentSession, isNull);
      expect(find.byType(TextField), findsNothing);
      expect(
        find.text(
          type == 'invite'
              ? 'Confirmar convite'
              : 'Confirmar recuperação de senha',
        ),
        findsOneWidget,
      );
      expect(storage.clearCalls, 1);
      expect(storage.values, isEmpty);
    });

    testWidgets(
      '$type explicit click verifies once and reuses password onboarding',
      (tester) async {
        final server = _Server();
        final storage = _Storage();

        await tester.pumpWidget(
          _app(
            AuthCallbackPage.confirm(
              uri: _link(type),
              session: server.session,
              storage: storage,
            ),
            server.session,
          ),
        );
        await tester.pumpAndSettle();
        expect(server.verifyCalls, 0);
        await tester.tap(
          find.text(
            type == 'invite' ? 'Aceitar convite' : 'Continuar recuperação',
          ),
        );
        await tester.pumpAndSettle();
        expect(server.verifyCalls, 1);
        expect(server.verificationTypes, [type]);
        expect(
          server.requests
              .where((r) => r.url.path.endsWith('/verify'))
              .single
              .method,
          'POST',
        );
        expect(server.verifyCalls, 1);
        expect(
          find.text(type == 'invite' ? 'Definir senha' : 'Redefinir senha'),
          findsOneWidget,
        );

        await tester.enterText(
          find.byType(TextField).at(0),
          'Only-a-test-password123',
        );
        await tester.enterText(
          find.byType(TextField).at(1),
          'Only-a-test-password123',
        );
        await tester.tap(find.text('Salvar senha'));
        await tester.pumpAndSettle();
        expect(server.updateCalls, 1);
        expect(server.verifyCalls, 1);
        expect(server.client.auth.currentSession, isNull);
        expect(storage.values, isEmpty);
        expect(storage.leaveCalls, 1);
        expect(find.text('Entrar no TEMDAS'), findsOneWidget);
        expect(find.text('protected'), findsNothing);
      },
    );
  }

  testWidgets('rapid repeated clicks cannot submit multiple verifications', (
    tester,
  ) async {
    final server = _Server()..hold = Completer<void>();
    await tester.pumpWidget(
      _app(
        AuthCallbackPage.confirm(
          uri: _link('recovery'),
          session: server.session,
          storage: _Storage(),
        ),
        server.session,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar recuperação'));
    await tester.tap(find.text('Continuar recuperação'));
    await tester.pump();
    expect(server.verifyCalls, 1);
    server.hold!.complete();
    await tester.pumpAndSettle();
    expect(server.verifyCalls, 1);
    expect(find.text('Redefinir senha'), findsOneWidget);
  });

  for (final (code, description, expected) in [
    ('otp_expired', 'expired', 'Link ou sessão expirados'),
    ('otp_expired', 'already used', 'Link ou sessão expirados'),
    ('validation_failed', 'invalid', 'Link inválido'),
  ]) {
    testWidgets('$description token never reuses an existing session', (
      tester,
    ) async {
      final server = _Server()..errorCode = code;
      await server.client.auth.recoverSession(jsonEncode(_session('old-user')));

      await tester.pumpWidget(
        _app(
          AuthCallbackPage.confirm(
            uri: _link('invite'),
            session: server.session,
            storage: _Storage(),
          ),
          server.session,
        ),
      );
      await tester.pumpAndSettle();
      expect(server.requests, isEmpty);
      await tester.tap(find.text('Aceitar convite'));
      await tester.pumpAndSettle();
      expect(find.text(expected), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(server.client.auth.currentSession?.user.id, 'old-user');
      expect(server.verifyCalls, 1);
      expect(server.updateCalls, 0);
    });
  }

  testWidgets('clean refreshed confirmation URL cannot restore an old flow', (
    tester,
  ) async {
    final server = _Server();
    await server.client.auth.recoverSession(jsonEncode(_session('old-user')));
    final storage = _Storage()
      ..values[_stateKey] = jsonEncode({
        'userId': 'old-user',
        'flow': 'recovery',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    await tester.pumpWidget(
      _app(
        AuthCallbackPage.confirm(
          uri: Uri.parse('https://app.example/auth/confirm'),
          session: server.session,
          storage: storage,
        ),
        server.session,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Link inválido'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(server.requests, isEmpty);
    expect(storage.values, isEmpty);
  });

  test(
    'confirmation intent cannot verify twice, including after failure',
    () async {
      final server = _Server()..errorCode = 'otp_expired';

      final intent = AuthConfirmationIntent.parse(_link('recovery'))!;
      final processor = AuthCallbackProcessor(
        server.session,
        storage: _Storage(),
      );
      expect(server.requests, isEmpty);
      expect((await intent.confirm(processor)).status, CallbackStatus.expired);
      expect((await intent.confirm(processor)).status, CallbackStatus.invalid);
      expect(server.verifyCalls, 1);
    },
  );

  for (final (name, suffix) in [
    ('missing hash', '?type=recovery'),
    ('missing type', '?token_hash=$_hash'),
    ('empty hash', '?token_hash=&type=invite'),
    ('wrong hash format', '?token_hash=invalid&type=recovery'),
    ('whitespace in hash', '?token_hash=%20$_hash&type=recovery'),
    ('unknown type', '?token_hash=$_hash&type=signup'),
    ('legacy flow alias', '?token_hash=$_hash&type=passwordRecovery'),
    (
      'extra redirect',
      '?token_hash=$_hash&type=recovery&redirect_to=https://untrusted.invalid',
    ),
    ('extra code', '?token_hash=$_hash&type=recovery&code=not-a-real-code'),
    ('extra error', '?token_hash=$_hash&type=recovery&error=access_denied'),
    ('internal duplicate', '?token_hash=$_hash&type=recovery&type=recovery'),
    (
      'conflicting mirrored type',
      '?token_hash=$_hash&type=recovery#/auth/confirm?type=invite',
    ),
    ('wrong fragment route', '?token_hash=$_hash&type=recovery#/auth/callback'),
    (
      'default route with credential parameters',
      '?token_hash=$_hash&type=recovery#/demandas?type=invite',
    ),
    (
      'default route with extra parameters',
      '?token_hash=$_hash&type=recovery#/demandas?extra=value',
    ),
    (
      'default route with nested fragment',
      '?token_hash=$_hash&type=recovery#/demandas#nested',
    ),
    ('malformed UTF8', '?token_hash=%FF&type=recovery'),
    ('empty parameter name', '?token_hash=$_hash&type=recovery&=value'),
  ]) {
    testWidgets('$name is rejected without verification', (tester) async {
      final server = _Server();
      await tester.pumpWidget(
        _app(
          AuthCallbackPage.confirm(
            uri: Uri.parse('https://app.example/auth/confirm$suffix'),
            session: server.session,
            storage: _Storage(),
          ),
          server.session,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Link inválido'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(server.requests, isEmpty);
    });
  }

  for (final (name, url) in [
    (
      'direct',
      'https://app.example/auth/confirm?token_hash=$_hash&type=recovery',
    ),
    (
      'hash route',
      'https://app.example/#/auth/confirm?token_hash=$_hash&type=invite',
    ),
    (
      'mirrored hash',
      'https://app.example/auth/confirm?token_hash=$_hash&type=recovery#/auth/confirm?token_hash=$_hash&type=recovery',
    ),
    (
      'prefixed hash',
      'https://app.example/auth/confirm?token_hash=pkce_$_hash&type=recovery',
    ),
    (
      'direct recovery with default navigation fragment',
      'https://app.example/auth/confirm?token_hash=$_hash&type=recovery#/demandas',
    ),
    (
      'direct invite with default navigation fragment',
      'https://app.example/auth/confirm?token_hash=$_hash&type=invite#/demandas',
    ),
  ]) {
    testWidgets('$name routes outside AuthGate and waits for confirmation', (
      tester,
    ) async {
      final server = _Server();
      final old = supabaseSession;
      supabaseSession = server.session;
      addTearDown(() => supabaseSession = old);
      final uri = Uri.parse(url);
      tester.binding.platformDispatcher.defaultRouteNameTestValue =
          uri.fragment;
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      await tester.pumpWidget(TemdasApp(initialUri: uri));
      await tester.pumpAndSettle();
      expect(find.byType(AuthCallbackPage), findsOneWidget);
      expect(find.byType(AuthGate), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(server.requests, isEmpty);
      expect(
        find.text(
          uri.queryParameters['type'] == 'recovery' || name == 'prefixed hash'
              ? 'Confirmar recuperação de senha'
              : 'Confirmar convite',
        ),
        findsOneWidget,
      );
      if (name == 'prefixed hash') {
        await tester.tap(find.text('Continuar recuperação'));
        await tester.pumpAndSettle();
        expect(server.verifyCalls, 1);
      }
    });
  }

  for (final path in ['/auth/confirm', '/auth/callback']) {
    test('sanitizes $path query and fragment without retaining credentials', () {
      final uri = Uri.parse(
        'https://app.example$path?token_hash=$_hash&type=recovery#$path?token_hash=$_hash&type=recovery',
      );
      final sanitized = sanitizedAuthEntryUri(uri);
      expect(sanitized.query, isEmpty);
      expect(sanitized.fragment, path);
      expect(sanitized.toString(), isNot(contains(_hash)));
      expect(sanitized.toString(), isNot(contains('token_hash')));
    });
  }

  test('hash-only entry removes credentials while preserving its route', () {
    final uri = Uri.parse(
      'https://app.example/#/auth/confirm?token_hash=$_hash&type=invite',
    );
    expect(
      sanitizedAuthEntryUri(uri).toString(),
      'https://app.example/#/auth/confirm',
    );
  });

  for (final (name, location) in [
    ('scheme', 'javascript:/auth/confirm'),
    ('userinfo', 'https://user:pass@app.example/auth/confirm'),
    ('legacy route', 'https://app.example/auth/callback'),
  ]) {
    test('confirmation rejects an incompatible $name', () {
      expect(
        AuthConfirmationIntent.parse(
          Uri.parse('$location?token_hash=$_hash&type=invite'),
        ),
        isNull,
      );
    });
  }

  test('Web document suppresses credential-bearing referrers', () {
    expect(
      File('web/index.html').readAsStringSync(),
      contains('<meta name="referrer" content="no-referrer">'),
    );
  });

  test('Cloudflare SPA fallback covers the direct confirmation route', () {
    expect(
      File('web/_redirects').readAsStringSync(),
      contains('/* /index.html 200'),
    );
  });
}

Widget _app(Widget page, SupabaseSession session) => MaterialApp(
  home: page,
  onGenerateRoute: (settings) => MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => AuthGate(
      session: session,
      child: const Scaffold(body: Text('protected')),
    ),
  ),
);

class _Server {
  _Server() {
    addTearDown(client.auth.dispose);
  }
  final requests = <http.Request>[];
  final verificationTypes = <String>[];
  int verifyCalls = 0;
  int updateCalls = 0;
  String? errorCode;
  Completer<void>? hold;
  late final session = SupabaseSession(client);
  late final client = SupabaseClient(
    'https://test.invalid',
    'sb_publishable_test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/verify')) {
        verifyCalls++;
        final body = jsonDecode(request.body) as Map;
        verificationTypes.add(body['type'] as String);
        expect(body.keys.toSet(), {
          'token_hash',
          'type',
          'gotrue_meta_security',
          'redirect_to',
        });
        expect(body['redirect_to'], isNull);
        expect(body['type'], anyOf('invite', 'recovery'));
        expect(body['token_hash'], anyOf(_hash, 'pkce_$_hash'));
        await hold?.future;
        if (errorCode != null || verifyCalls > 1) {
          return _json({
            'code': errorCode ?? 'otp_expired',
            'message': 'untrusted error fake-access-value',
          }, status: 400);
        }
        return _json(_session('confirmed-user'));
      }
      if (request.url.path.endsWith('/user')) {
        if (request.method == 'PUT') updateCalls++;
        return _json(_user('confirmed-user'));
      }
      if (request.url.path.endsWith('/logout')) return http.Response('', 204);
      return _json({}, status: 404);
    }),
  );
}

http.Response _json(Map<String, dynamic> body, {int status = 200}) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {
        'content-type': 'application/json',
        'x-supabase-api-version': '2024-01-01',
      },
    );

Map<String, dynamic> _user(String id) => {
  'id': id,
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
};
Map<String, dynamic> _session(String id) => {
  'access_token': 'fake-access-value',
  'refresh_token': 'fake-refresh-value',
  'expires_in': 3600,
  'token_type': 'bearer',
  'user': _user(id),
};

class _Storage implements CallbackStorage {
  final values = <String, String>{};
  int clearCalls = 0;
  int leaveCalls = 0;
  @override
  String? read(String key) => values[key];
  @override
  void write(String key, String value) {
    values[key] = value;
  }

  @override
  void remove(String key) {
    values.remove(key);
  }

  @override
  void clearUrl() {
    clearCalls++;
  }

  @override
  void leaveCallback() {
    leaveCalls++;
  }
}
