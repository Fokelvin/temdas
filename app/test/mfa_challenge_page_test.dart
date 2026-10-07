import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas/view/auth_pages.dart';

void main() {
  testWidgets(
    'confirma com challenge interno e mostra só ações para o usuário',
    (tester) async {
      final requests = <String>[];
      final verifyBodies = <Map<String, dynamic>>[];
      final gate = Completer<void>();
      final fixture = _AuthFixture(
        requests: requests,
        verifyBodies: verifyBodies,
        beforeChallenge: () => gate.future,
      );
      final supabase = _client(fixture.client);
      await _signIn(supabase);
      addTearDown(fixture.close);

      await tester.pumpWidget(_page(supabase));
      expect(find.text('Confirme sua identidade'), findsOneWidget);
      expect(
        find.text('Informe o código gerado pelo seu aplicativo autenticador.'),
        findsOneWidget,
      );
      expect(find.text('Código de 6 dígitos'), findsOneWidget);
      expect(find.text('Confirmar'), findsOneWidget);
      expect(find.text('Sair'), findsOneWidget);
      expect(find.text('Iniciar challenge'), findsNothing);
      expect(find.text('Verificar'), findsNothing);
      expect(find.text('Código TOTP'), findsNothing);
      expect(find.textContaining('Fatores TOTP verificados'), findsNothing);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        requests.where((path) => path.contains('/challenge')),
        hasLength(1),
      );

      gate.complete();
      await _pumpRequest(tester);
      expect(requests.where((path) => path.contains('/verify')), hasLength(1));
      expect(verifyBodies.single, {
        'challenge_id': 'internal-challenge-id',
        'code': '123456',
      });
      expect(find.textContaining('internal-challenge-id'), findsNothing);
      expect(find.textContaining('factor-internal-id'), findsNothing);
    },
  );

  testWidgets('orienta quando o código não tem seis dígitos', (tester) async {
    final requests = <String>[];
    final fixture = _AuthFixture(requests: requests);
    final supabase = _client(fixture.client);
    await _signIn(supabase);
    addTearDown(fixture.close);

    await tester.pumpWidget(_page(supabase));
    await tester.enterText(find.byType(TextField), '123');
    await tester.tap(find.text('Confirmar'));
    await _pumpRequest(tester);

    expect(find.text('Informe um código válido de 6 dígitos.'), findsOneWidget);
    expect(requests.where((path) => path.contains('/challenge')), isEmpty);
  });

  testWidgets('código inválido é amigável e erro técnico é genérico', (
    tester,
  ) async {
    final requests = <String>[];
    final fixture = _AuthFixture(requests: requests, verifyError: true);
    final supabase = _client(fixture.client);
    await _signIn(supabase);
    addTearDown(fixture.close);

    await tester.pumpWidget(_page(supabase));
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Confirmar'));
    await _pumpRequest(tester);
    expect(
      find.text(
        'Código inválido. Confira o aplicativo autenticador e tente novamente.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('internal error detail'), findsNothing);

    fixture.challengeError = true;
    await tester.enterText(find.byType(TextField), '654321');
    await tester.tap(find.text('Confirmar'));
    await _pumpRequest(tester);
    expect(
      find.text('Não foi possível confirmar sua identidade. Tente novamente.'),
      findsOneWidget,
    );
    expect(find.textContaining('internal error detail'), findsNothing);
  });
}

Future<void> _pumpRequest(WidgetTester tester) async {
  for (var attempt = 0; attempt < 5; attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget _page(SupabaseClient supabase) => MaterialApp(
  home: MfaChallengePage(
    session: SupabaseSession(supabase),
    factors: [
      Factor(
        id: 'factor-internal-id',
        friendlyName: 'TEMDAS',
        factorType: FactorType.totp,
        status: FactorStatus.verified,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    ],
    onSignOut: () async {},
  ),
);

Future<void> _signIn(SupabaseClient supabase) async {
  await supabase.auth.signInWithPassword(
    email: 'user@example.com',
    password: 'password',
  );
}

SupabaseClient _client(http.Client client) => SupabaseClient(
  'https://example.supabase.co',
  'sb_publishable_test',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
  httpClient: client,
);

class _AuthFixture {
  _AuthFixture({
    required this.requests,
    List<Map<String, dynamic>>? verifyBodies,
    this.beforeChallenge,
    this.verifyError = false,
  }) : verifyBodies = verifyBodies ?? <Map<String, dynamic>>[] {
    client = MockClient(_respond);
  }

  final List<String> requests;
  final List<Map<String, dynamic>> verifyBodies;
  final Future<void> Function()? beforeChallenge;
  final bool verifyError;
  bool challengeError = false;
  late final MockClient client;

  void close() => client.close();

  Future<http.Response> _respond(http.Request request) async {
    requests.add(request.url.path);
    if (request.url.path.endsWith('/token')) {
      return _json(_session());
    }
    if (request.url.path.endsWith('/challenge')) {
      await beforeChallenge?.call();
      if (challengeError) {
        return _json({
          'message': 'internal error detail: signing key leaked',
        }, statusCode: 500);
      }
      return _json({
        'id': 'internal-challenge-id',
        'expires_at':
            DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch ~/
            1000,
      });
    }
    if (request.url.path.endsWith('/verify')) {
      verifyBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
      if (verifyError) {
        return _json({
          'code': 'mfa_verification_failed',
          'message': 'internal error detail: invalid TOTP code',
        }, statusCode: 400);
      }
      return _json(_session(aal: 'aal2'));
    }
    return _json({'message': 'not found'}, statusCode: 404);
  }
}

http.Response _json(Map<String, dynamic> body, {int statusCode = 200}) =>
    http.Response(
      jsonEncode(body),
      statusCode,
      headers: const {
        'content-type': 'application/json',
        'x-supabase-api-version': '2024-01-01',
      },
    );

Map<String, dynamic> _session({String aal = 'aal1'}) => {
  'access_token': _jwt(aal),
  'refresh_token': 'test-refresh',
  'token_type': 'bearer',
  'expires_in': 3600,
  'user': {
    'id': 'test-user',
    'app_metadata': <String, Object?>{},
    'user_metadata': <String, Object?>{},
    'aud': 'authenticated',
    'created_at': '2026-01-01T00:00:00Z',
  },
};

String _jwt(String aal) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry = DateTime.now().add(const Duration(hours: 1));
  return '${encode({'alg': 'HS256'})}.${encode({'aal': aal, 'exp': expiry.millisecondsSinceEpoch ~/ 1000})}.test';
}
