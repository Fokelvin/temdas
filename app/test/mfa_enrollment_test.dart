import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/app/auth_gate.dart';
import 'package:temdas/data/auth_provisioning.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/auth_pages.dart';
import 'package:temdas/view/totp_enrollment_qr.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  testWidgets(
    'cadastro mostra QR/chave e confirma com challenge interno uma única vez',
    (tester) async {
      final server = _Server()..challengeHold = Completer<void>();
      await _open(tester, server);
      expect(server.enrolls, 0);
      expect(find.text('Iniciar challenge'), findsNothing);
      await tester.tap(find.text('Configurar autenticador'));
      await tester.pumpAndSettle();
      expect(server.enrolls, 1);
      expect(find.byType(TotpEnrollmentQr), findsOneWidget);
      expect(find.text('manual-secret'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.ensureVisible(find.text('Confirmar'));
      await tester.tap(find.text('Confirmar'));
      await tester.tap(find.text('Confirmar'));
      await tester.pump();
      expect(server.challenges, 1);
      expect(server.verifications, isEmpty);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      server.challengeHold!.complete();
      await tester.pumpAndSettle();
      expect(server.verifications, [
        {'challenge_id': 'challenge-1', 'code': '123456'},
      ]);
      expect(
        server.session.client.auth.mfa
            .getAuthenticatorAssuranceLevel()
            .currentLevel,
        AuthenticatorAssuranceLevels.aal2,
      );
      expect(
        find.text('Autenticador confirmado. Verificando acesso…'),
        findsOneWidget,
      );
    },
  );

  testWidgets('valida seis dígitos e permite corrigir código rejeitado', (
    tester,
  ) async {
    final server = _Server()..invalidCode = true;
    await _open(tester, server, pending: true);
    await tester.enterText(find.byType(TextField), '12');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(server.challenges, 0);
    expect(find.text('Informe um código válido de 6 dígitos.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Código inválido.'), findsOneWidget);
    expect(find.textContaining('private detail'), findsNothing);
    server.invalidCode = false;
    await tester.enterText(find.byType(TextField), '654321');
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(server.challenges, 2);
    expect(server.verifications.last, {
      'challenge_id': 'challenge-2',
      'code': '654321',
    });
    expect(server.enrolls, 0);
  });

  testWidgets(
    'cadastro interrompido reutiliza fator e só reinicia por ação explícita',
    (tester) async {
      final server = _Server();
      await _open(tester, server, pending: true);
      expect(server.enrolls, 0);
      expect(server.deleted, isEmpty);
      expect(find.textContaining('não tem mais o QR Code'), findsOneWidget);
      await tester.tap(find.text('Reiniciar configuração'));
      await tester.pumpAndSettle();
      expect(server.deleted, ['pending']);
      expect(server.enrolls, 1);
      expect(find.byType(TotpEnrollmentQr), findsOneWidget);
      expect(
        server.order.indexOf('DELETE pending'),
        lessThan(server.order.indexOf('POST factors')),
      );
    },
  );

  testWidgets(
    'reinício revalida estado e não exclui autenticador já verificado',
    (tester) async {
      final server = _Server();
      await _open(tester, server, pending: true);
      server.factors = [_factor('pending', verified: true)];
      await tester.tap(find.text('Reiniciar configuração'));
      await tester.pumpAndSettle();
      expect(server.deleted, isEmpty);
      expect(server.enrolls, 0);
      expect(
        find.textContaining('Já existe um autenticador configurado'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'falha de conexão na confirmação permite tentar novamente sem novo cadastro',
    (tester) async {
      final server = _Server()..offlineChallenge = true;
      await _open(tester, server, pending: true);
      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Não foi possível confirmar sua identidade. Tente novamente.',
        ),
        findsOneWidget,
      );
      server.offlineChallenge = false;
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(server.challenges, 2);
      expect(server.verifications, hasLength(1));
      expect(server.enrolls, 0);
    },
  );

  testWidgets(
    'resposta de cadastro perdida não cria fator duplicado ao tentar novamente',
    (tester) async {
      final server = _Server()..loseEnrollment = true;
      await _open(tester, server);
      await tester.tap(find.text('Configurar autenticador'));
      await tester.pumpAndSettle();
      expect(server.enrolls, 1);
      await tester.tap(find.text('Configurar autenticador'));
      await tester.pumpAndSettle();
      expect(server.enrolls, 1);
      expect(server.deleted, isEmpty);
      expect(find.text('Reiniciar configuração'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    },
  );

  testWidgets('AAL2 após cadastro ainda aguarda confirmação do provisioning', (
    tester,
  ) async {
    final server = _Server();
    await server.signIn();
    final ready = Completer<backend.AuthMe>();
    var confirmations = 0;
    final provisioning = AuthProvisioning(
      provisionar: () async =>
          backend.AuthMe(usuarioId: 7, aal: 'aal1', isAdmin: false),
      me: () {
        confirmations++;
        return ready.future;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthGate(
          session: server.session,
          provisioning: provisioning,
          child: const Scaffold(body: Text('protected')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsNothing);
    await tester.tap(find.text('Configurar autenticador'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(find.text('Confirmar'));
    await tester.tap(find.text('Confirmar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(confirmations, 1);
    expect(find.text('protected'), findsNothing);
    ready.complete(backend.AuthMe(usuarioId: 7, aal: 'aal2', isAdmin: false));
    await tester.pumpAndSettle();
    expect(find.text('protected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final dark in [false, true]) {
    for (final width in [320.0, 1440.0]) {
      testWidgets('cadastro responsivo $width escuro=$dark', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 680);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final server = _Server();
        await _open(tester, server, dark: dark);
        await tester.tap(find.text('Configurar autenticador'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Confirmar'));
        expect(find.text('Confirmar').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _open(
  WidgetTester tester,
  _Server server, {
  bool pending = false,
  bool dark = false,
}) async {
  if (pending) server.factors = [_factor('pending')];
  await server.signIn();
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: MfaEnrollPage(
        session: server.session,
        factors: server.factors.map(Factor.fromJson).toList(),
        onSignOut: server.session.signOut,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Server {
  _Server() {
    addTearDown(client.auth.dispose);
  }
  List<Map<String, dynamic>> factors = [];
  final deleted = <String>[];
  final order = <String>[];
  final verifications = <Map<String, dynamic>>[];
  int enrolls = 0;
  int challenges = 0;
  String aal = 'aal1';
  bool invalidCode = false;
  bool offlineChallenge = false;
  bool loseEnrollment = false;
  Completer<void>? challengeHold;
  late final session = SupabaseSession(client);
  late final client = SupabaseClient(
    'https://example.supabase.co',
    'sb_publishable_test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((r) async {
      final path = r.url.path;
      if (path.endsWith('/token')) return _json(_session());
      if (path.endsWith('/factors') && r.method == 'POST') {
        order.add('POST factors');
        enrolls++;
        factors.add(_factor('new-factor'));
        if (loseEnrollment) throw const SocketException('private detail');
        return _json({
          'id': 'new-factor',
          'type': 'totp',
          'totp': {
            'qr_code': '<svg/>',
            'secret': 'manual-secret',
            'uri': 'otpauth://totp/TEMDAS:test?secret=manual-secret',
          },
        });
      }
      if (r.method == 'DELETE') {
        final id = r.url.pathSegments.last;
        deleted.add(id);
        order.add('DELETE $id');
        factors.removeWhere((f) => f['id'] == id);
        return _json({'id': id});
      }
      if (path.endsWith('/challenge')) {
        challenges++;
        if (offlineChallenge) throw const SocketException('private detail');
        await challengeHold?.future;
        return _json({'id': 'challenge-$challenges', 'expires_at': 2000000000});
      }
      if (path.endsWith('/verify')) {
        verifications.add(jsonDecode(r.body) as Map<String, dynamic>);
        if (invalidCode) {
          return _json({
            'code': 'mfa_verification_failed',
            'message': 'private detail',
          }, status: 400);
        }
        aal = 'aal2';
        factors = [_factor('new-factor', verified: true)];
        return _json(_session());
      }
      return _json({}, status: 404);
    }),
  );
  Future<void> signIn() async {
    await session.signInWithPassword('user@example.com', 'password');
  }

  Map<String, dynamic> _session() => {
    'access_token': _jwt(aal),
    'refresh_token': 'refresh-$aal',
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': 'user',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-01-01T00:00:00Z',
      'factors': factors,
    },
  };
}

Map<String, dynamic> _factor(String id, {bool verified = false}) => {
  'id': id,
  'factor_type': 'totp',
  'status': verified ? 'verified' : 'unverified',
  'created_at': '2026-01-01T00:00:00Z',
  'updated_at': '2026-01-01T00:00:00Z',
};
String _jwt(String aal) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'ES256'})}.${encode({'sub': 'user', 'aal': aal, 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.signature';
}

http.Response _json(Map<String, dynamic> data, {int status = 200}) =>
    http.Response(
      jsonEncode(data),
      status,
      headers: {
        'content-type': 'application/json',
        'x-supabase-api-version': '2024-01-01',
      },
    );
