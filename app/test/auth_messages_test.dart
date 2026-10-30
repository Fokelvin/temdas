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
  for (final code in [
    'invalid_credentials',
    'user_not_found',
    'email_not_confirmed',
  ]) {
    testWidgets('login protege dados da conta: $code', (tester) async {
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'code': code, 'message': 'internal account detail'}),
            400,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(home: LoginPage(session: SupabaseSession(client))),
      );
      await tester.enterText(find.byType(TextField).first, 'user@example.com');
      await tester.enterText(find.byType(TextField).last, 'password');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Não foi possível entrar. Confira seus dados e tente novamente.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('internal account detail'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });
  }

  testWidgets(
    'login permite retry e conclusão após fechar não usa estado descartado',
    (tester) async {
      var response = Completer<http.Response>();
      var calls = 0;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((_) {
          calls++;
          return response.future;
        }),
      );
      await tester.pumpWidget(
        MaterialApp(home: LoginPage(session: SupabaseSession(client))),
      );
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(find.text('Entrando…'), findsOneWidget);
      response.complete(
        http.Response('{"message":"private server detail"}', 400),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('private server detail'), findsNothing);
      response = Completer<http.Response>();
      await tester.tap(find.text('Entrar'));
      await tester.pump();
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
      response.complete(
        http.Response('{"message":"private server detail"}', 400),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'enrollment não exibe falhas técnicas e permite tentar novamente',
    (tester) async {
      var calls = 0;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((_) async {
          calls++;
          return http.Response(
            '{"message":"private enrollment detail"}',
            400,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MfaEnrollPage(
            session: SupabaseSession(client),
            factors: const [],
            onSignOut: () async {},
          ),
        ),
      );
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.text('Cadastrar TOTP'));
        await tester.pumpAndSettle();
        expect(find.textContaining('private enrollment detail'), findsNothing);
        expect(
          find.text(
            'Não foi possível confirmar sua identidade. Tente novamente.',
          ),
          findsOneWidget,
        );
      }
      expect(calls, 2);
    },
  );
}
