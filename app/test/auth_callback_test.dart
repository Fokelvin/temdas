import 'dart:convert';

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
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/meu_perfil_page.dart';

void main() {
  testWidgets('callback opens before AuthGate', (tester) async {
    await tester.pumpWidget(
      TemdasApp(initialUri: Uri.parse('https://app.example/auth/callback')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível validar o link'), findsOneWidget);
    expect(find.text('Entrar no TEMDAS'), findsNothing);
  });

  for (final flow in ['invite', 'recovery']) {
    testWidgets('$flow fragment opens callback over an existing admin session', (
      tester,
    ) async {
      final client = _client();
      await client.auth.recoverSession(jsonEncode(_adminSession()));
      final previousSession = supabaseSession;
      supabaseSession = SupabaseSession(client);
      addTearDown(() => supabaseSession = previousSession);

      final uri = Uri.parse(
        'https://app.example/auth/callback#access_token=test-token'
        '&refresh_token=test-refresh&expires_in=3600&token_type=bearer&type=$flow',
      );
      tester.binding.platformDispatcher.defaultRouteNameTestValue =
          uri.fragment;
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );

      await tester.pumpWidget(TemdasApp(initialUri: uri));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AuthCallbackPage), findsOneWidget);
      expect(find.byType(AuthGate), findsNothing);
      expect(
        find.text(flow == 'invite' ? 'Definir senha' : 'Redefinir senha'),
        findsOneWidget,
      );
      expect(client.auth.currentSession?.user.id, 'user-1');
    });
  }

  testWidgets('invalid callback fragment never opens the old admin session', (
    tester,
  ) async {
    final client = _client();
    await client.auth.recoverSession(jsonEncode(_adminSession()));
    final previousSession = supabaseSession;
    supabaseSession = SupabaseSession(client);
    addTearDown(() => supabaseSession = previousSession);

    final uri = Uri.parse(
      'https://app.example/auth/callback#access_token=invalid&type=invite',
    );
    tester.binding.platformDispatcher.defaultRouteNameTestValue = uri.fragment;
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await tester.pumpWidget(TemdasApp(initialUri: uri));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AuthCallbackPage), findsOneWidget);
    expect(find.byType(AuthGate), findsNothing);
    expect(find.text('Link inválido'), findsOneWidget);
    expect(client.auth.currentSession?.user.id, 'admin-1');
  });

  testWidgets('expired callback fragment stays outside AuthGate', (
    tester,
  ) async {
    final client = _client();
    await client.auth.recoverSession(jsonEncode(_adminSession()));
    final previousSession = supabaseSession;
    supabaseSession = SupabaseSession(client);
    addTearDown(() => supabaseSession = previousSession);

    final uri = Uri.parse(
      'https://app.example/auth/callback#error=access_denied'
      '&error_code=otp_expired&type=invite',
    );
    tester.binding.platformDispatcher.defaultRouteNameTestValue = uri.fragment;
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );

    await tester.pumpWidget(TemdasApp(initialUri: uri));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AuthCallbackPage), findsOneWidget);
    expect(find.byType(AuthGate), findsNothing);
    expect(find.text('Link ou sessão expirados'), findsOneWidget);
    expect(client.auth.currentSession?.user.id, 'admin-1');
  });

  for (final (route, page) in [
    ('/perfil', MeuPerfilPage),
    ('/demandas', DemandasPage),
  ]) {
    testWidgets('ordinary hash route $route keeps its destination', (
      tester,
    ) async {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = route;
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );

      await tester.pumpWidget(
        TemdasApp(initialUri: Uri.parse('https://app.example/#$route')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthCallbackPage), findsNothing);
      expect(
        tester.widget<AuthGate>(find.byType(AuthGate)).child.runtimeType,
        page,
      );
    });
  }

  test('recognizes clean and hash callback routes', () {
    expect(
      isAuthCallbackLocation(
        Uri.parse('https://app.example/auth/callback?code=x'),
      ),
      isTrue,
    );
    expect(
      isAuthCallbackLocation(
        Uri.parse('https://app.example/#/auth/callback?code=x'),
      ),
      isTrue,
    );
    expect(
      isAuthCallbackLocation(Uri.parse('https://app.example/#/demandas')),
      isFalse,
    );
  });

  test(
    'valid invite is exchanged by SDK and restored for the same user',
    () async {
      final storage = _MemoryStorage();
      final client = _client();
      addTearDown(client.dispose);
      final processor = AuthCallbackProcessor(
        SupabaseSession(client),
        storage: storage,
      );
      final url = Uri.parse(
        'https://app.example/auth/callback#access_token=test-token'
        '&refresh_token=test-refresh&expires_in=3600&token_type=bearer&type=invite',
      );

      final result = await processor.process(url);
      expect(result.status, CallbackStatus.valid);
      expect(result.flow, CallbackFlow.invite);
      expect(client.auth.currentSession?.user.id, 'user-1');
      expect(storage.values.values.single, isNot(contains('test-token')));
      expect(storage.values.values.single, isNot(contains('test-refresh')));

      final restored = await AuthCallbackProcessor(
        SupabaseSession(client),
        storage: storage,
      ).process(Uri.parse('https://app.example/auth/callback'));
      expect(restored.status, CallbackStatus.valid);
      expect(restored.flow, CallbackFlow.invite);

      await client.auth.signOut();
      final afterLogout = await processor.process(
        Uri.parse('https://app.example/auth/callback'),
      );
      expect(afterLogout.status, CallbackStatus.expired);
    },
  );

  test(
    'recovery token hash uses verifyOTP and preserves recovery flow',
    () async {
      final requests = <http.Request>[];
      final client = _client(requests: requests);
      addTearDown(client.dispose);
      final result =
          await AuthCallbackProcessor(
            SupabaseSession(client),
            storage: _MemoryStorage(),
          ).process(
            Uri.parse(
              'https://app.example/#/auth/callback?token_hash=hash-1&type=recovery',
            ),
          );
      expect(result.status, CallbackStatus.valid);
      expect(result.flow, CallbackFlow.recovery);
      expect(requests.single.url.path, '/auth/v1/verify');
      expect(
        jsonDecode(requests.single.body),
        containsPair('type', 'recovery'),
      );
    },
  );

  test('PKCE recovery uses locally stored flow after code exchange', () async {
    final pkce = _PkceStorage();
    await pkce.setItem(
      key: 'supabase.auth.token-code-verifier',
      value: 'verifier/passwordRecovery',
    );
    final requests = <http.Request>[];
    final client = _client(requests: requests, pkce: pkce);
    addTearDown(client.dispose);
    final result =
        await AuthCallbackProcessor(
          SupabaseSession(client),
          storage: _MemoryStorage(),
        ).process(
          Uri.parse('https://app.example/auth/callback?code=one-time-code'),
        );
    expect(result.status, CallbackStatus.valid);
    expect(result.flow, CallbackFlow.recovery);
    expect(requests.single.url.queryParameters['grant_type'], 'pkce');
    expect(pkce.values, isEmpty);
  });

  test('expired token hash is classified from the SDK error', () async {
    final client = _client(expiredOtp: true);
    addTearDown(client.dispose);
    final result =
        await AuthCallbackProcessor(
          SupabaseSession(client),
          storage: _MemoryStorage(),
        ).process(
          Uri.parse(
            'https://app.example/auth/callback?token_hash=old&type=invite',
          ),
        );
    expect(result.status, CallbackStatus.expired);
    expect(client.auth.currentSession, isNull);
  });

  test('expired and invalid links do not reuse an old success', () async {
    final storage = _MemoryStorage();
    final client = _client();
    addTearDown(client.dispose);
    final processor = AuthCallbackProcessor(
      SupabaseSession(client),
      storage: storage,
    );
    expect(
      (await processor.process(
        Uri.parse(
          'https://app.example/auth/callback#error=access_denied'
          '&error_code=otp_expired&type=invite',
        ),
      )).status,
      CallbackStatus.expired,
    );
    expect(storage.values, isEmpty);
    expect(
      (await processor.process(
        Uri.parse(
          'https://app.example/auth/callback?token_hash=hash-1&type=other',
        ),
      )).status,
      CallbackStatus.invalid,
    );
    expect(
      (await processor.process(
        Uri.parse(
          'https://app.example/auth/callback#access_token=bad&type=invite',
        ),
      )).status,
      CallbackStatus.invalid,
    );
  });
}

SupabaseClient _client({
  List<http.Request>? requests,
  GotrueAsyncStorage? pkce,
  bool expiredOtp = false,
}) => SupabaseClient(
  'http://localhost:9999',
  'sb_publishable_test',
  authOptions: AuthClientOptions(
    autoRefreshToken: false,
    pkceAsyncStorage: pkce,
  ),
  httpClient: MockClient((request) async {
    requests?.add(request);
    if (request.url.path.endsWith('/user')) {
      return http.Response(jsonEncode(_user()), 200, headers: _jsonHeaders);
    }
    if (request.url.path.endsWith('/verify')) {
      if (expiredOtp) {
        return http.Response(
          '{"code":"otp_expired","message":"token expired"}',
          403,
          headers: _jsonHeaders,
        );
      }
      return http.Response(jsonEncode(_session()), 200, headers: _jsonHeaders);
    }
    if (request.url.path.endsWith('/token')) {
      return http.Response(jsonEncode(_session()), 200, headers: _jsonHeaders);
    }
    if (request.url.path.endsWith('/logout')) {
      return http.Response('', 204);
    }
    return http.Response('{"message":"invalid"}', 400, headers: _jsonHeaders);
  }),
);

const _jsonHeaders = {'content-type': 'application/json'};

Map<String, dynamic> _user() => {
  'id': 'user-1',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
};

Map<String, dynamic> _session() => {
  'access_token': 'test-token',
  'refresh_token': 'test-refresh',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': _user(),
};

Map<String, dynamic> _adminSession() => {
  ..._session(),
  'access_token': 'admin-token',
  'refresh_token': 'admin-refresh',
  'user': {..._user(), 'id': 'admin-1'},
};

class _MemoryStorage implements CallbackStorage {
  final values = <String, String>{};

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;

  @override
  void remove(String key) => values.remove(key);

  @override
  void clearUrl() {}

  @override
  void leaveCallback() {}
}

class _PkceStorage extends GotrueAsyncStorage {
  final values = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => values[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}
