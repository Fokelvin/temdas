import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/data/auth_callback_diagnostics.dart';
import 'package:temdas/data/auth_callback_storage.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas/view/auth_callback_page.dart';

void main() {
  for (final flow in ['recovery', 'invite']) {
    testWidgets(
      '$flow verified TOTP blocks password until AAL2 then logs out',
      (tester) async {
        final f = _Fixture();
        await _open(tester, f, flow);
        expect(find.text('Confirmar MFA'), findsOneWidget);
        expect(find.text('Salvar senha'), findsNothing);
        expect(f.writes, 0);
        await _totp(tester);
        expect(f.challengeCalls, 1);
        expect(f.verifyCalls, 1);
        expect(find.text('Salvar senha'), findsOneWidget);
        await _save(tester);
        expect(f.writes, 1);
        expect(f.writeAals, ['aal2']);
        expect(f.logoutCalls, 1);
        expect(f.client.auth.currentSession, isNull);
        expect(find.text('login'), findsOneWidget);
        _safe(f);
      },
    );
  }
  testWidgets('already AAL2 needs no challenge', (tester) async {
    final f = _Fixture()..aal = 'aal2';
    await _open(tester, f, 'recovery');
    expect(find.text('Salvar senha'), findsOneWidget);
    await _save(tester);
    expect(f.writes, 1);
    expect(f.challengeCalls, 0);
  });
  testWidgets('initial invite without factors can define password', (
    tester,
  ) async {
    final f = _Fixture()..hasFactor = false;
    await _open(tester, f, 'invite');
    expect(find.text('Confirmar MFA'), findsNothing);
    await _save(tester);
    expect(f.writes, 1);
    expect(f.challengeCalls, 0);
  });
  for (final mismatch in ['before', 'after']) {
    testWidgets('identity mismatch $mismatch TOTP never writes', (
      tester,
    ) async {
      final f = _Fixture()..differentUser = mismatch == 'before';
      await _open(tester, f, 'recovery');
      if (mismatch == 'after') {
        f.changeUserAfterVerify = true;
        await _totp(tester);
      }
      expect(find.text('Link ou sessão expirados'), findsOneWidget);
      expect(find.text('Salvar senha'), findsNothing);
      expect(f.writes, 0);
    });
  }
  for (final error in [
    'mfa_verification_failed',
    'mfa_challenge_expired',
    'mfa_challenge_not_found',
    'session_not_found',
  ]) {
    testWidgets('$error blocks password and uses safe message', (tester) async {
      final f = _Fixture()..verifyError = error;
      await _open(tester, f, 'recovery');
      await _totp(tester);
      expect(f.writes, 0);
      expect(find.text('Salvar senha'), findsNothing);
      expect(find.text('unsafe-private-detail'), findsNothing);
      if (error == 'session_not_found') {
        expect(find.text('Link ou sessão expirados'), findsOneWidget);
      } else {
        expect(find.text('Link ou sessão expirados'), findsNothing);
        expect(find.text('Confirmar MFA'), findsOneWidget);
      }
      _safe(f);
    });
  }
  testWidgets('verify response still AAL1 cannot open password form', (
    tester,
  ) async {
    final f = _Fixture()..elevate = false;
    await _open(tester, f, 'recovery');
    await _totp(tester);
    expect(find.text('Salvar senha'), findsNothing);
    expect(f.writes, 0);
  });
  testWidgets('duplicate clicks create exactly one challenge and verify', (
    tester,
  ) async {
    final f = _Fixture()..hold = Completer<void>();
    await _open(tester, f, 'recovery');
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Confirmar MFA'));
    await tester.tap(find.text('Confirmar MFA'));
    await tester.pump();
    expect(f.challengeCalls, 1);
    f.hold!.complete();
    await tester.pumpAndSettle();
    expect(f.verifyCalls, 1);
    expect(f.challengeCalls, 1);
  });
  testWidgets('invalid local TOTP never contacts challenge API', (
    tester,
  ) async {
    final f = _Fixture();
    await _open(tester, f, 'recovery');
    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Confirmar MFA'));
    await tester.pumpAndSettle();
    expect(f.challengeCalls, 0);
    expect(find.text('Informe um código válido de 6 dígitos.'), findsOneWidget);
  });
  testWidgets('insufficient_aal is MFA requirement, not expiration', (
    tester,
  ) async {
    final f = _Fixture()..hasFactor = false;
    await _open(tester, f, 'recovery');
    f.writeError = 'insufficient_aal';
    await _save(tester);
    expect(find.text('Link ou sessão expirados'), findsNothing);
    expect(find.text('Salvar senha'), findsNothing);
    expect(
      find.text('Confirme o MFA antes de salvar a senha.'),
      findsOneWidget,
    );
    expect(f.logoutCalls, 0);
    _safe(f);
  });
  testWidgets('new verified factor before save cannot bypass MFA', (
    tester,
  ) async {
    final f = _Fixture()..hasFactor = false;
    await _open(tester, f, 'invite');
    f.hasFactor = true;
    await _save(tester);
    expect(f.writes, 0);
    expect(find.text('Confirmar MFA'), findsOneWidget);
  });
  testWidgets('session lost before challenge blocks verification', (
    tester,
  ) async {
    final f = _Fixture();
    await _open(tester, f, 'recovery');
    await f.client.auth.signOut();
    await _totp(tester);
    expect(f.verifyCalls, 0);
    expect(f.writes, 0);
    expect(find.text('Link ou sessão expirados'), findsOneWidget);
  });
  testWidgets('factor lookup failure does not reveal password form', (
    tester,
  ) async {
    final f = _Fixture()..lookupError = true;
    await _open(tester, f, 'recovery');
    expect(find.text('Salvar senha'), findsNothing);
    expect(find.text('Verificar sessão novamente'), findsOneWidget);
    expect(f.writes, 0);
  });
}

Future<void> _open(WidgetTester tester, _Fixture f, String flow) async {
  addTearDown(f.client.auth.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: AuthCallbackPage.confirm(
        uri: Uri.parse(
          'https://test.invalid/auth/confirm?token_hash=${'a' * 56}&type=$flow#/demandas',
        ),
        session: SupabaseSession(f.client),
        storage: _Storage(),
        diagnostics: CallbackDiagnostics(f.logs.add),
      ),
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('login')),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(flow == 'invite' ? 'Aceitar convite' : 'Continuar recuperação'),
  );
  await tester.pumpAndSettle();
}

Future<void> _totp(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), '123456');
  await tester.tap(find.text('Confirmar MFA'));
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), 'Fixture-password-123');
  await tester.enterText(find.byType(TextField).at(1), 'Fixture-password-123');
  await tester.tap(find.text('Salvar senha'));
  await tester.pumpAndSettle();
}

void _safe(_Fixture f) {
  for (final line in f.logs) {
    for (final secret in [
      '123456',
      'Fixture-password-123',
      'unsafe-private-detail',
      'fixture-user',
      'https://',
      'token_hash=',
      'a' * 56,
    ]) {
      expect(line, isNot(contains(secret)));
    }
  }
}

class _Fixture {
  String aal = 'aal1';
  bool hasFactor = true,
      differentUser = false,
      changeUserAfterVerify = false,
      elevate = true,
      lookupError = false;
  String? verifyError, writeError;
  Completer<void>? hold;
  int writes = 0, challengeCalls = 0, verifyCalls = 0, logoutCalls = 0;
  final writeAals = <String>[];
  final logs = <String>[];
  Map<String, dynamic> user({bool original = false}) => {
    'id': differentUser && !original ? 'other-fixture-user' : 'fixture-user',
    'aud': 'authenticated',
    'app_metadata': <String, dynamic>{},
    'user_metadata': <String, dynamic>{},
    'created_at': '2026-01-01T00:00:00Z',
    'factors': hasFactor
        ? [
            {
              'id': 'fixture-factor',
              'factor_type': 'totp',
              'status': 'verified',
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            },
          ]
        : [],
  };
  Map<String, dynamic> session({bool original = false}) => {
    'access_token': jwt(aal),
    'refresh_token': 'fake-refresh',
    'expires_in': 3600,
    'token_type': 'bearer',
    'user': user(original: original),
  };
  late final client = SupabaseClient(
    'https://test.invalid',
    'sb_publishable_fixture',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((r) async {
      if (r.url.path.endsWith('/factors/fixture-factor/challenge')) {
        challengeCalls++;
        await hold?.future;
        return jsonResponse({
          'id': 'fixture-challenge',
          'expires_at': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 300,
        });
      }
      if (r.url.path.endsWith('/factors/fixture-factor/verify')) {
        verifyCalls++;
        if (verifyError != null) return error(verifyError!);
        if (elevate) aal = 'aal2';
        if (changeUserAfterVerify) differentUser = true;
        return jsonResponse(session());
      }
      if (r.url.path.endsWith('/verify')) {
        return jsonResponse(session(original: true));
      }
      if (r.url.path.endsWith('/user')) {
        if (r.method == 'PUT') {
          writes++;
          writeAals.add(aal);
          if (writeError != null) return error(writeError!);
        }
        if (lookupError) return error('unexpected_failure', status: 500);
        return jsonResponse(user());
      }
      if (r.url.path.endsWith('/logout')) {
        logoutCalls++;
        return http.Response('', 204);
      }
      return error('not_found', status: 404);
    }),
  );
}

http.Response error(String code, {int status = 401}) => jsonResponse({
  'code': code,
  'message': 'unsafe-private-detail',
}, status: status);
http.Response jsonResponse(Map<String, dynamic> body, {int status = 200}) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {
        'content-type': 'application/json',
        'x-supabase-api-version': '2024-01-01',
      },
    );
String jwt(String aal) {
  String enc(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${enc({'alg': 'HS256'})}.${enc({'aal': aal, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})}.fixture';
}

class _Storage implements CallbackStorage {
  final values = <String, String>{};
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
  void clearUrl() {}
  @override
  void leaveCallback() {}
}
