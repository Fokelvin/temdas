import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/app/auth_gate.dart';
import 'package:temdas/data/auth_callback_storage.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/auth_callback_page.dart';

void main() {
  for (final flow in ['invite', 'recovery']) {
    testWidgets('$flow updates password, signs out and opens login', (
      tester,
    ) async {
      final server = _PasswordServer();
      final storage = _MemoryStorage();
      await tester.pumpWidget(_app(server, storage, _link(flow)));
      await tester.pumpAndSettle();
      expect(
        find.text(flow == 'invite' ? 'Definir senha' : 'Redefinir senha'),
        findsOneWidget,
      );

      await _fill(tester, 'SenhaSegura123');
      await tester.tap(find.text('Salvar senha'));
      await tester.pumpAndSettle();

      expect(server.updateCalls, 1);
      expect(server.logoutCalls, 1);
      expect(server.updatedPassword, 'SenhaSegura123');
      expect(server.client.auth.currentSession, isNull);
      expect(storage.values, isEmpty);
      expect(storage.leaveCalls, 1);
      expect(find.text('Entrar no TEMDAS'), findsOneWidget);
      expect(find.text('protected'), findsNothing);
    });
  }

  testWidgets('validates fields and toggles both password fields', (
    tester,
  ) async {
    final server = _PasswordServer();
    await tester.pumpWidget(_app(server, _MemoryStorage(), _link('invite')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salvar senha'));
    await tester.pump();
    expect(find.text('Informe uma senha.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'curta');
    await tester.tap(find.text('Salvar senha'));
    await tester.pump();
    expect(find.text('Use pelo menos 8 caracteres.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'SenhaSegura123');
    await tester.enterText(find.byType(TextField).at(1), 'outraSenha123');
    await tester.tap(find.text('Salvar senha'));
    await tester.pump();
    expect(find.text('As senhas não coincidem.'), findsOneWidget);

    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
      isTrue,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isTrue,
    );
    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.tap(find.byTooltip('Mostrar confirmação'));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField).at(0)).obscureText,
      isFalse,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
    expect(server.updateCalls, 0);
  });

  testWidgets('weak password stays on form and can be retried', (tester) async {
    final server = _PasswordServer()..updateErrorCode = 'weak_password';
    await tester.pumpWidget(_app(server, _MemoryStorage(), _link('recovery')));
    await tester.pumpAndSettle();
    await _fill(tester, 'SenhaSegura123');
    await tester.tap(find.text('Salvar senha'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'A senha não atende aos requisitos de segurança. Escolha outra.',
      ),
      findsOneWidget,
    );
    expect(server.logoutCalls, 0);
    server.updateErrorCode = null;
    await _fill(tester, 'OutraSenha456');
    await tester.tap(find.text('Salvar senha'));
    await tester.pumpAndSettle();
    expect(server.updateCalls, 2);
    expect(find.text('Entrar no TEMDAS'), findsOneWidget);
  });

  testWidgets('expired session before submit never updates password', (
    tester,
  ) async {
    final server = _PasswordServer();
    final storage = _MemoryStorage();
    await tester.pumpWidget(_app(server, storage, _link('invite')));
    await tester.pumpAndSettle();
    await server.client.auth.signOut();
    await _fill(tester, 'SenhaSegura123');
    await tester.tap(find.text('Salvar senha'));
    await tester.pumpAndSettle();
    expect(server.updateCalls, 0);
    expect(storage.values, isEmpty);
    expect(find.text('Link ou sessão expirados'), findsOneWidget);
  });

  testWidgets('expired session reported by updateUser shows expired state', (
    tester,
  ) async {
    final server = _PasswordServer()..updateErrorCode = 'session_not_found';
    await tester.pumpWidget(_app(server, _MemoryStorage(), _link('recovery')));
    await tester.pumpAndSettle();
    await _fill(tester, 'SenhaSegura123');
    await tester.tap(find.text('Salvar senha'));
    await tester.pumpAndSettle();
    expect(server.updateCalls, 1);
    expect(server.logoutCalls, 0);
    expect(find.text('Link ou sessão expirados'), findsOneWidget);
    await tester.tap(find.text('Voltar ao login'));
    await tester.pumpAndSettle();
    expect(server.client.auth.currentSession, isNull);
    expect(find.text('Entrar no TEMDAS'), findsOneWidget);
  });

  testWidgets('refresh restores form only with matching Supabase session', (
    tester,
  ) async {
    final server = _PasswordServer();
    final storage = _MemoryStorage();
    await tester.pumpWidget(_app(server, storage, _link('recovery')));
    await tester.pumpAndSettle();
    expect(storage.values, isNotEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _app(server, storage, Uri.parse('https://app.example/auth/callback')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Redefinir senha'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await server.client.auth.signOut();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      _app(server, storage, Uri.parse('https://app.example/auth/callback')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Link ou sessão expirados'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('double submit sends only one update request', (tester) async {
    final server = _PasswordServer()..updateHold = Completer<void>();
    await tester.pumpWidget(_app(server, _MemoryStorage(), _link('invite')));
    await tester.pumpAndSettle();
    await _fill(tester, 'SenhaSegura123');

    await tester.tap(find.text('Salvar senha'));
    await tester.tap(find.text('Salvar senha'));
    await tester.pump();
    expect(server.updateCalls, 1);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    server.updateHold!.complete();
    await tester.pumpAndSettle();
    expect(server.updateCalls, 1);
    expect(find.text('Entrar no TEMDAS'), findsOneWidget);
  });

  testWidgets('remote logout failure still clears callback session', (
    tester,
  ) async {
    final server = _PasswordServer()..logoutStatus = 500;
    final storage = _MemoryStorage();
    await tester.pumpWidget(_app(server, storage, _link('invite')));
    await tester.pumpAndSettle();
    await _fill(tester, 'SenhaSegura123');
    await tester.tap(find.text('Salvar senha'));
    await tester.pumpAndSettle();
    expect(server.updateCalls, 1);
    expect(server.logoutCalls, 1);
    expect(server.client.auth.currentSession, isNull);
    expect(storage.values, isEmpty);
    expect(find.text('Entrar no TEMDAS'), findsOneWidget);
  });
}

Uri _link(String flow) => Uri.parse(
  'https://app.example/auth/callback#access_token=test-token'
  '&refresh_token=test-refresh&expires_in=3600&token_type=bearer&type=$flow',
);

Widget _app(_PasswordServer server, _MemoryStorage storage, Uri uri) {
  final session = SupabaseSession(server.client);
  return MaterialApp(
    theme: AppTheme.light,
    home: AuthCallbackPage(uri: uri, session: session, storage: storage),
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => AuthGate(
        session: session,
        child: const Scaffold(body: Text('protected')),
      ),
    ),
  );
}

Future<void> _fill(WidgetTester tester, String password) async {
  await tester.enterText(find.byType(TextField).at(0), password);
  await tester.enterText(find.byType(TextField).at(1), password);
}

class _PasswordServer {
  int updateCalls = 0;
  int logoutCalls = 0;
  String? updatedPassword;
  String? updateErrorCode;
  Completer<void>? updateHold;
  int logoutStatus = 204;

  late final SupabaseClient client = SupabaseClient(
    'http://localhost:9999',
    'sb_publishable_test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/user') && request.method == 'GET') {
        return _json(_user());
      }
      if (request.url.path.endsWith('/user') && request.method == 'PUT') {
        updateCalls++;
        updatedPassword =
            (jsonDecode(request.body) as Map<String, dynamic>)['password']
                as String?;
        await updateHold?.future;
        if (updateErrorCode != null) {
          return _json({
            'code': updateErrorCode,
            'message': 'internal error detail',
          }, statusCode: updateErrorCode == 'session_not_found' ? 401 : 422);
        }
        return _json(_user());
      }
      if (request.url.path.endsWith('/logout')) {
        logoutCalls++;
        return http.Response(
          logoutStatus == 204 ? '' : '{"message":"unavailable"}',
          logoutStatus,
          headers: logoutStatus == 204
              ? const {}
              : const {'content-type': 'application/json'},
        );
      }
      return _json({'message': 'not found'}, statusCode: 404);
    }),
  );
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

Map<String, dynamic> _user() => {
  'id': 'user-1',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-01-01T00:00:00Z',
};

class _MemoryStorage implements CallbackStorage {
  final values = <String, String>{};
  int leaveCalls = 0;

  @override
  String? read(String key) => values[key];

  @override
  void write(String key, String value) => values[key] = value;

  @override
  void remove(String key) => values.remove(key);

  @override
  void clearUrl() {}

  @override
  void leaveCallback() => leaveCalls++;
}
