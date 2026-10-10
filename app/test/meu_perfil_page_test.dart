import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/app/auth_gate.dart';
import 'package:temdas/data/auth_provisioning.dart';
import 'package:temdas/data/convites_gateway.dart';
import 'package:temdas/data/supabase_session.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/meu_perfil_page.dart';
import 'package:temdas/view/widgets/app_drawer.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

void main() {
  testWidgets('admin sees profile, AAL2, and invitation form', (tester) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    await tester.pumpWidget(
      _page(auth.session, () async => _me(isAdmin: true)),
    );
    await tester.pumpAndSettle();

    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('Ativa (AAL2)'), findsOneWidget);
    expect(find.text('Administrador'), findsOneWidget);
    expect(find.text('Convites'), findsOneWidget);
    expect(find.text('E-mail do convite'), findsOneWidget);
    expect(find.text('Consultar convite'), findsOneWidget);
  });

  testWidgets('common user does not see invitations section', (tester) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    await tester.pumpWidget(_page(auth.session, () async => _me()));
    await tester.pumpAndSettle();

    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('Ativa (AAL2)'), findsOneWidget);
    expect(find.text('Usuário'), findsOneWidget);
    expect(find.text('Convites'), findsNothing);
  });

  testWidgets('profile cards fit a narrow viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = _SupabaseFixture();
    await auth.signIn();
    await tester.pumpWidget(_page(auth.session, () async => _me()));
    await tester.pumpAndSettle();

    expect(find.text('admin@example.com'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('drawer navigates to protected profile route', (tester) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    final provisioning = AuthProvisioning(
      provisionar: () async => _me(),
      me: () async => _me(),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AuthGate(
          session: auth.session,
          provisioning: provisioning,
          child: const PageScaffold(
            title: 'Demandas',
            route: AppRoutes.demandas,
            body: Center(child: Text('home')),
          ),
        ),
        onGenerateRoute: (settings) => MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => AuthGate(
            session: auth.session,
            provisioning: provisioning,
            child: settings.name == AppRoutes.perfil
                ? MeuPerfilPage(
                    session: auth.session,
                    loadMe: () async => _me(isAdmin: true),
                  )
                : const Scaffold(body: Text('home')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Meu Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Meu Perfil'), findsWidgets);
    expect(find.text('admin@example.com'), findsOneWidget);
  });

  testWidgets('shows loading, recovers from error with retry', (tester) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    final response = Completer<backend.AuthMe>();
    var calls = 0;
    await tester.pumpWidget(
      _page(auth.session, () {
        calls++;
        return calls == 1 ? response.future : Future.value(_me());
      }),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('perfil-carregando')), findsOneWidget);
    response.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Não foi possível carregar o perfil'), findsOneWidget);
    expect(find.text('Sessão expirada'), findsNothing);

    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('admin@example.com'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('reports expired session from auth.me and on logout', (
    tester,
  ) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    await tester.pumpWidget(
      _page(
        auth.session,
        () async => throw backend.AuthException(codigo: 'tokenExpired'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sessão expirada'), findsOneWidget);
    expect(find.text('admin@example.com'), findsNothing);

    await auth.client.auth.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Sessão expirada'), findsOneWidget);
  });

  testWidgets('missing session displays expired state', (tester) async {
    final auth = _SupabaseFixture();
    await tester.pumpWidget(_page(auth.session, () async => _me()));
    await tester.pumpAndSettle();
    expect(find.text('Sessão expirada'), findsOneWidget);
    expect(find.text('admin@example.com'), findsNothing);
  });

  testWidgets('consult shows new, pending and provisioned states', (
    tester,
  ) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    var status = 'ausente';
    final gateway = ConvitesGateway(
      consultar: (_) async => status,
      convidar: (_) async => 'enviado',
      reenviar: (_) async => 'reenviado',
    );
    await tester.pumpWidget(
      _page(auth.session, () async => _me(isAdmin: true), gateway: gateway),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('convite-email')),
      ' TEST@Example.com ',
    );

    await tester.tap(find.byKey(const ValueKey('consultar-convite')));
    await tester.pumpAndSettle();
    expect(find.text('Novo convite'), findsOneWidget);
    expect(find.byKey(const ValueKey('enviar-convite')), findsOneWidget);

    status = 'pendente';
    await tester.tap(find.byKey(const ValueKey('consultar-convite')));
    await tester.pumpAndSettle();
    expect(find.text('Convite pendente'), findsOneWidget);
    expect(find.byKey(const ValueKey('reenviar-convite')), findsOneWidget);

    status = 'provisionado';
    await tester.tap(find.byKey(const ValueKey('consultar-convite')));
    await tester.pumpAndSettle();
    expect(find.text('Conta provisionada'), findsOneWidget);
    expect(find.byKey(const ValueKey('reenviar-convite')), findsNothing);
    expect(find.byKey(const ValueKey('enviar-convite')), findsNothing);
  });

  testWidgets('invitation actions normalize email and show feedback', (
    tester,
  ) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    final sent = <String>[];
    final gateway = ConvitesGateway(
      consultar: (_) async => 'ausente',
      convidar: (email) async {
        sent.add('invite:$email');
        return 'enviado';
      },
      reenviar: (email) async {
        sent.add('resend:$email');
        return 'reenviado';
      },
    );
    await tester.pumpWidget(
      _page(auth.session, () async => _me(isAdmin: true), gateway: gateway),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('convite-email')),
      ' TEST@Example.com ',
    );
    await tester.tap(find.byKey(const ValueKey('consultar-convite')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('enviar-convite')));
    await tester.tap(find.byKey(const ValueKey('enviar-convite')));
    await tester.pumpAndSettle();
    expect(sent, ['invite:test@example.com']);
    expect(find.text('Convite enviado com sucesso.'), findsOneWidget);

    final pendingGateway = ConvitesGateway(
      consultar: (_) async => 'pendente',
      convidar: (_) async => 'enviado',
      reenviar: (email) async {
        sent.add('resend:$email');
        return 'reenviado';
      },
    );
    await tester.pumpWidget(
      _page(
        auth.session,
        () async => _me(isAdmin: true),
        gateway: pendingGateway,
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('convite-email')),
      ' TEST@Example.com ',
    );
    await tester.tap(find.byKey(const ValueKey('consultar-convite')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('reenviar-convite')));
    await tester.tap(find.byKey(const ValueKey('reenviar-convite')));
    await tester.pumpAndSettle();
    expect(sent.last, 'resend:test@example.com');
    expect(find.text('Convite reenviado com sucesso.'), findsOneWidget);
  });

  testWidgets('cooldown and invalid email errors are visible', (tester) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    final gateway = ConvitesGateway(
      consultar: (_) async => 'pendente',
      convidar: (_) async => 'enviado',
      reenviar: (_) async =>
          throw backend.ConviteException(codigo: 'aguardeReenvio'),
    );
    await tester.pumpWidget(
      _page(auth.session, () async => _me(isAdmin: true), gateway: gateway),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('convite-email')),
      'user@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('consultar-convite')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('reenviar-convite')));
    await tester.tap(find.byKey(const ValueKey('reenviar-convite')));
    await tester.pumpAndSettle();
    expect(find.textContaining('cooldown'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('convite-email')),
      'invalid',
    );
    await tester.tap(find.byKey(const ValueKey('consultar-convite')));
    await tester.pumpAndSettle();
    expect(find.text('Informe um e-mail válido.'), findsOneWidget);
  });

  testWidgets('double click sends only once and disables while pending', (
    tester,
  ) async {
    final auth = _SupabaseFixture();
    await auth.signIn();
    final response = Completer<String>();
    var sendCalls = 0;
    final gateway = ConvitesGateway(
      consultar: (_) async => 'ausente',
      convidar: (_) {
        sendCalls++;
        return response.future;
      },
      reenviar: (_) async => 'reenviado',
    );
    await tester.pumpWidget(
      _page(auth.session, () async => _me(isAdmin: true), gateway: gateway),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('convite-email')),
      'user@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('consultar-convite')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('enviar-convite')));
    await tester.tap(find.byKey(const ValueKey('enviar-convite')));
    await tester.pump();
    expect(find.byKey(const ValueKey('convite-loading')), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('enviar-convite')))
          .onPressed,
      isNull,
    );
    expect(sendCalls, 1);
    response.complete('enviado');
    await tester.pumpAndSettle();
    expect(find.text('Convite enviado com sucesso.'), findsOneWidget);
  });
}

Widget _page(
  SupabaseSession session,
  Future<backend.AuthMe> Function() loadMe, {
  ConvitesGateway? gateway,
}) => MaterialApp(
  theme: AppTheme.light,
  home: MeuPerfilPage(
    session: session,
    loadMe: loadMe,
    convitesGateway: gateway,
  ),
);

backend.AuthMe _me({bool isAdmin = false}) =>
    backend.AuthMe(usuarioId: 7, aal: 'aal2', isAdmin: isAdmin);

class _SupabaseFixture {
  late final SupabaseClient client = SupabaseClient(
    'http://localhost:9999',
    'sb_publishable_test',
    authOptions: const AuthClientOptions(autoRefreshToken: false),
    httpClient: MockClient((request) async {
      if (request.url.path.endsWith('/token')) {
        return _json({
          'access_token': _jwt(),
          'refresh_token': 'profile-refresh',
          'token_type': 'bearer',
          'expires_in': 3600,
          'user': {
            'id': 'profile-user',
            'email': 'admin@example.com',
            'app_metadata': <String, Object?>{},
            'user_metadata': <String, Object?>{},
            'aud': 'authenticated',
            'created_at': '2026-01-01T00:00:00Z',
          },
        });
      }
      if (request.url.path.endsWith('/logout')) return http.Response('', 204);
      return _json({'message': 'not found'}, statusCode: 404);
    }),
  );

  late final SupabaseSession session = SupabaseSession(client);

  Future<void> signIn() async {
    await session.signInWithPassword('admin@example.com', 'password');
  }
}

String _jwt() {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${encode({'alg': 'ES256'})}.${encode({'sub': 'profile-user', 'aal': 'aal2', 'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000})}.test-signature';
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
