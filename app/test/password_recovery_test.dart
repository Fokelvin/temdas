import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas/view/auth_pages.dart';
import 'package:temdas/view/auth_callback_page.dart';
import 'package:temdas/theme/app_theme.dart';

void main() {
  testWidgets(
    'sends a recovery request to the callback on the current origin',
    (tester) async {
      final server = _RecoveryServer();
      await tester.pumpWidget(_app(server));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '  pessoa@example.com  ');
      await tester.tap(find.text('Enviar instruções'));
      await tester.pump();

      expect(server.calls, 1);
      expect(server.email, 'pessoa@example.com');
      expect(server.redirectTo, 'https://temdas.example:8443/auth/callback');
      expect(server.client.auth.currentSession, isNull);
      expect(find.textContaining('Se houver uma conta'), findsOneWidget);
      expect(find.textContaining('Aguarde um minuto'), findsOneWidget);
      expect(find.text('Enviar instruções'), findsNothing);
      await tester.tap(find.text('Voltar ao login'));
      await tester.pump();
      expect(find.text('Entrar no TEMDAS'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();
      expect(find.text('Enviar instruções'), findsNothing);
      expect(server.calls, 1);
      await tester.pump(const Duration(minutes: 1));
      expect(find.text('Enviar instruções'), findsOneWidget);
    },
  );

  testWidgets('invalid and oversized emails do not call Supabase', (
    tester,
  ) async {
    final server = _RecoveryServer();
    await tester.pumpWidget(_app(server));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pump();
    await tester.tap(find.text('Enviar instruções'));
    await tester.pump();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '${'a' * 250}@example.com');
    await tester.tap(find.text('Enviar instruções'));
    await tester.pump();
    expect(server.calls, 0);
  });

  for (final status in [400, 404]) {
    testWidgets('user_not_found with $status keeps the generic response', (
      tester,
    ) async {
      final server = _RecoveryServer()
        ..status = status
        ..errorCode = 'user_not_found';
      await tester.pumpWidget(_app(server));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'unknown@example.com');
      await tester.tap(find.text('Enviar instruções'));
      await tester.pump();
      expect(find.textContaining('Se houver uma conta'), findsOneWidget);
      expect(find.textContaining('Aguarde um minuto'), findsOneWidget);
      expect(find.textContaining('internal account detail'), findsNothing);
      expect(server.calls, 1);
    });
  }

  testWidgets('400 validation failure is reported without server details', (
    tester,
  ) async {
    final server = _RecoveryServer()
      ..status = 400
      ..errorCode = 'validation_failed';
    await tester.pumpWidget(_app(server));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'pessoa@example.com');
    await tester.tap(find.text('Enviar instruções'));
    await tester.pump();
    expect(find.textContaining('foi recusada'), findsOneWidget);
    expect(find.textContaining('Se houver uma conta'), findsNothing);
    expect(find.textContaining('internal account detail'), findsNothing);
    expect(find.text('Enviar instruções'), findsOneWidget);
  });

  for (final status in [401, 403]) {
    testWidgets('$status reports unavailable configuration', (tester) async {
      final server = _RecoveryServer()
        ..status = status
        ..errorCode = 'no_authorization';
      await tester.pumpWidget(_app(server));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'pessoa@example.com');
      await tester.tap(find.text('Enviar instruções'));
      await tester.pump();
      expect(find.textContaining('Contate o suporte'), findsOneWidget);
      expect(find.textContaining('Se houver uma conta'), findsNothing);
      expect(find.textContaining('internal account detail'), findsNothing);
    });
  }

  for (final status in [400, 429]) {
    testWidgets('rate-limit code with $status reports the limit', (
      tester,
    ) async {
      final server = _RecoveryServer()
        ..status = status
        ..errorCode = 'over_email_send_rate_limit';
      await tester.pumpWidget(_app(server));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'pessoa@example.com');
      await tester.tap(find.text('Enviar instruções'));
      await tester.pump();
      expect(find.textContaining('Limite de tentativas'), findsOneWidget);
      expect(find.textContaining('Se houver uma conta'), findsNothing);
      expect(find.textContaining('internal account detail'), findsNothing);
    });
  }

  testWidgets('429 without an SDK code still reports the limit', (
    tester,
  ) async {
    final server = _RecoveryServer()
      ..status = 429
      ..errorCode = 'validation_failed';
    await tester.pumpWidget(_app(server));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'pessoa@example.com');
    await tester.tap(find.text('Enviar instruções'));
    await tester.pump();
    expect(find.textContaining('Limite de tentativas'), findsOneWidget);
  });

  testWidgets('server errors allow retry without exposing internal details', (
    tester,
  ) async {
    final server = _RecoveryServer()
      ..status = 500
      ..errorCode = 'user_not_found';
    await tester.pumpWidget(_app(server));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'pessoa@example.com');
    await tester.tap(find.text('Enviar instruções'));
    await tester.pump();
    expect(find.textContaining('Não foi possível solicitar'), findsOneWidget);
    expect(find.textContaining('internal account detail'), findsNothing);
    server.status = 200;
    await tester.tap(find.text('Enviar instruções'));
    await tester.pump();
    expect(server.calls, 2);
    expect(find.textContaining('Se houver uma conta'), findsOneWidget);
  });

  for (final failure in ['network', 'timeout']) {
    testWidgets('$failure failure allows retry', (tester) async {
      final server = _RecoveryServer()..transportFailure = failure;
      await tester.pumpWidget(_app(server));
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'pessoa@example.com');
      await tester.tap(find.text('Enviar instruções'));
      await tester.pump();
      expect(find.textContaining('Não foi possível solicitar'), findsOneWidget);
      expect(find.text('Enviar instruções'), findsOneWidget);
      expect(find.textContaining('Se houver uma conta'), findsNothing);
      server.transportFailure = null;
      await tester.tap(find.text('Enviar instruções'));
      await tester.pump();
      expect(server.calls, 2);
      expect(find.textContaining('Se houver uma conta'), findsOneWidget);
    });
  }

  testWidgets('loading blocks double submit and navigation', (tester) async {
    final server = _RecoveryServer()..hold = Completer<void>();
    await tester.pumpWidget(_app(server));
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'pessoa@example.com');
    await tester.tap(find.text('Enviar instruções'));
    await tester.tap(find.text('Enviar instruções'));
    await tester.pump();
    expect(server.calls, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Enviando instruções…'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, 'Voltar ao login'),
          )
          .onPressed,
      isNull,
    );
    server.hold!.complete();
    await tester.pump();
    expect(find.textContaining('Se houver uma conta'), findsOneWidget);
    expect(server.calls, 1);
  });

  testWidgets('requires a web origin for the callback redirect', (
    tester,
  ) async {
    final server = _RecoveryServer();
    await tester.pumpWidget(
      _app(server, uri: Uri.parse('file:///app/main.dart')),
    );
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'pessoa@example.com');
    await tester.tap(find.text('Enviar instruções'));
    await tester.pump();
    expect(find.textContaining('endereço do app'), findsOneWidget);
    expect(server.calls, 0);
  });
  for (final source in ['login', 'invalid', 'expired']) {
    for (final status in [200, 404]) {
      testWidgets(
        'ativação via $source mantém confirmação genérica HTTP $status',
        (tester) async {
          final server = _RecoveryServer()
            ..status = status
            ..errorCode = 'user_not_found';
          await _openActivation(tester, server, source);
          expect(server.calls, 0);
          expect(
            find.textContaining('procure o administrador'),
            findsOneWidget,
          );
          expect(find.widgetWithText(TextField, 'Senha'), findsNothing);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            isEmpty,
          );
          await tester.enterText(
            find.byType(TextField),
            '  pessoa@example.com  ',
          );
          await tester.tap(find.text('Enviar link para continuar'));
          await tester.pumpAndSettle();
          expect(server.calls, 1);
          expect(server.email, 'pessoa@example.com');
          expect(
            server.redirectTo,
            'https://temdas.example:8443/auth/callback',
          );
          expect(server.client.auth.currentSession, isNull);
          expect(find.textContaining('Se houver uma conta'), findsOneWidget);
          expect(find.textContaining('internal account detail'), findsNothing);
          expect(find.text('Enviar link para continuar'), findsNothing);
          expect(find.text('Voltar ao login'), findsOneWidget);
        },
      );
    }
  }

  testWidgets(
    'limite de envio também bloqueia reenvio na retomada da ativação',
    (tester) async {
      final server = _RecoveryServer()..status = 429;
      await _openActivation(tester, server, 'login');
      await tester.enterText(find.byType(TextField), 'pessoa@example.com');
      await tester.tap(find.text('Enviar link para continuar'));
      await tester.pumpAndSettle();
      expect(server.calls, 1);
      expect(find.textContaining('Limite de tentativas'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Enviar link para continuar'),
            )
            .onPressed,
        isNull,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(server.calls, 1);
      await tester.tap(find.text('Voltar ao login'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Esqueci minha senha'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Enviar instruções'),
            )
            .onPressed,
        isNull,
      );
      await tester.pump(const Duration(minutes: 1));
      server.status = 200;
      await tester.tap(find.text('Enviar instruções'));
      await tester.pumpAndSettle();
      expect(server.calls, 2);
      expect(find.textContaining('Se houver uma conta'), findsOneWidget);
    },
  );

  for (final dark in [false, true]) {
    for (final width in [320.0, 1440.0]) {
      testWidgets('recuperação de ativação responsiva $width escuro=$dark', (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 640);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final server = _RecoveryServer();
        await _openActivation(tester, server, 'invalid', dark: dark);
        await tester.ensureVisible(find.text('Enviar link para continuar'));
        expect(
          find.text('Enviar link para continuar').hitTestable(),
          findsOneWidget,
        );
        expect(server.calls, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _openActivation(
  WidgetTester tester,
  _RecoveryServer server,
  String source, {
  bool dark = false,
}) async {
  final uri = source == 'expired'
      ? Uri.parse(
          'https://temdas.example:8443/auth/confirm?token_hash=${'a' * 56}&type=invite',
        )
      : Uri.parse(
          'https://temdas.example:8443/auth/confirm?token_hash=invalid&type=invite&email=private@example.com',
        );
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: source == 'login'
          ? LoginPage(session: SupabaseSession(server.client), currentUri: uri)
          : AuthCallbackPage.confirm(
              session: SupabaseSession(server.client),
              uri: uri,
            ),
    ),
  );
  await tester.pumpAndSettle();
  if (source == 'login') {
    await tester.ensureVisible(find.text('Problemas para ativar sua conta?'));
    await tester.tap(find.text('Problemas para ativar sua conta?'));
  } else if (source == 'expired') {
    await tester.tap(find.text('Aceitar convite'));
  }
  await tester.pumpAndSettle();
  if (source != 'login') {
    expect(find.text('Este link não está mais disponível.'), findsOneWidget);
  }
}

Widget _app(_RecoveryServer server, {Uri? uri}) => MaterialApp(
  home: LoginPage(
    session: SupabaseSession(server.client),
    currentUri:
        uri ?? Uri.parse('https://temdas.example:8443/demandas?tab=all'),
  ),
);

class _RecoveryServer {
  int calls = 0;
  int status = 200;
  String? errorCode;
  String? transportFailure;
  String? email;
  String? redirectTo;
  Completer<void>? hold;

  late final SupabaseClient client = SupabaseClient(
    'http://localhost:9999',
    'sb_publishable_test',
    authOptions: AuthClientOptions(
      autoRefreshToken: false,
      pkceAsyncStorage: _PkceStorage(),
    ),
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/recover')) {
        calls++;
        email =
            (jsonDecode(request.body) as Map<String, dynamic>)['email']
                as String?;
        redirectTo = request.url.queryParameters['redirect_to'];
        await hold?.future;
        if (transportFailure == 'network') {
          throw const SocketException('offline');
        }
        if (transportFailure == 'timeout') {
          throw TimeoutException('request timed out');
        }
        return http.Response(
          jsonEncode(
            status == 200
                ? <String, dynamic>{}
                : {
                    'code': errorCode ?? 'validation_failed',
                    'message': 'internal account detail',
                  },
          ),
          status,
          headers: const {
            'content-type': 'application/json',
            'x-supabase-api-version': '2024-01-01',
          },
        );
      }
      if (request.url.path.endsWith('/verify')) {
        return http.Response(
          '{"code":"otp_expired","message":"private expired link"}',
          400,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('', 404);
    }),
  );
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
