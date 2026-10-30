import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/app/auth_gate.dart';
import 'package:temdas/app/public_home_entry.dart';
import 'package:temdas/app/temdas_app.dart';
import 'package:temdas/theme/theme_preference.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/auth_pages.dart';
import 'package:temdas/view/home_page.dart';

Future<void> openHome(
  WidgetTester tester, {
  double width = 1440,
  bool dark = false,
  double scale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    ThemePreference.storageKey: dark ? 'dark' : 'light',
  });
  if (scale != 1 || reduceMotion) {
    final preference = ThemePreference();
    addTearDown(preference.dispose);
    await preference.load();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('home-capture'),
        child: ThemePreferenceScope(
          notifier: preference,
          child: MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: preference.mode,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                disableAnimations: reduceMotion,
              ),
              child: child!,
            ),
            home: const HomePage(),
          ),
        ),
      ),
    );
  } else {
    await tester.pumpWidget(
      const RepaintBoundary(key: ValueKey('home-capture'), child: TemdasApp()),
    );
  }
  await tester.pumpAndSettle();
}

Future<void> capture(WidgetTester tester, String name) async {
  final directory = Platform.environment['TEMDAS_HOME_SCREENSHOTS'];
  if (directory == null) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('home-capture')),
    );
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(directory).createSync(recursive: true);
    File('$directory/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'packages/material_symbols_icons/MaterialSymbolsRounded':
          'packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
      'Roboto Mono': 'assets/fonts/inter/RobotoMono-Regular.ttf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load(entry.value));
      await loader.load();
    }
  });

  for (final width in [
    320.0,
    360.0,
    390.0,
    430.0,
    768.0,
    820.0,
    1024.0,
    1280.0,
    1440.0,
  ]) {
    for (final dark in [false, true]) {
      testWidgets('homepage responsiva $width escuro=$dark', (tester) async {
        await openHome(tester, width: width, dark: dark);
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(AuthGate), findsNothing);
        expect(find.byType(LoginPage), findsNothing);
        expect(
          tester.widget<Text>(find.byKey(const ValueKey('home-title'))).data,
          'Tempo e Demandas',
        );
        expect(
          Theme.of(tester.element(find.byType(HomePage))).brightness,
          dark ? Brightness.dark : Brightness.light,
        );
        for (var i = 1; i < 5; i++) {
          expect(find.byKey(ValueKey('home-section-$i')), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await capture(tester, '${width.toInt()}_${dark ? 'dark' : 'light'}');
      });
    }
  }

  for (final width in [320.0, 768.0, 1440.0]) {
    testWidgets('homepage texto ampliado em $width', (tester) async {
      await openHome(tester, width: width, scale: 1.8);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [390.0, 1440.0]) {
    for (final reduceMotion in [false, true]) {
      testWidgets(
        'âncoras mantêm a mesma página em $width reduzir=$reduceMotion',
        (tester) async {
          await openHome(tester, width: width, reduceMotion: reduceMotion);
          final home = tester.element(find.byType(HomePage));
          final navigator = tester.state<NavigatorState>(
            find.byType(Navigator).first,
          );
          for (final i in [1, 2, 3, 4, 0]) {
            final link = find.byKey(ValueKey('home-nav-$i'));
            await tester.ensureVisible(link);
            await tester.pumpAndSettle();
            await tester.tap(link);
            await tester.pumpAndSettle();
            expect(tester.element(find.byType(HomePage)), same(home));
            expect(navigator.canPop(), isFalse);
            final target = find.byKey(
              ValueKey(i == 0 ? 'home-title' : 'home-section-$i'),
            );
            final bounds = tester.getRect(target);
            final viewport = tester.getRect(
              find.byKey(const ValueKey('home-scroll')),
            );
            expect(bounds.top, greaterThanOrEqualTo(viewport.top));
            expect(bounds.bottom, lessThan(viewport.bottom));
            expect(tester.takeException(), isNull);
            if (!reduceMotion) {
              await capture(tester, '${width.toInt()}_section_$i');
            }
          }
        },
      );
    }
  }

  testWidgets('Entrar mantém o login e a recuperação existentes', (
    tester,
  ) async {
    await openHome(tester, width: 390);
    await tester.tap(find.byKey(const ValueKey('home-enter')));
    await tester.pumpAndSettle();
    expect(find.byType(AuthGate), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(PublicHomeEntry, skipOffstage: false), findsNothing);
    expect(find.text('Entrar no TEMDAS'), findsOneWidget);
    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();
    expect(find.text('Enviar instruções'), findsOneWidget);
    await tester.tap(find.text('Voltar ao login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tema da homepage persiste e acompanha o login', (tester) async {
    await openHome(tester, width: 390, dark: true);
    await tester.tap(find.byKey(const ValueKey('alternar-tema')));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString(
        ThemePreference.storageKey,
      ),
      'light',
    );
    await tester.tap(find.byKey(const ValueKey('home-enter')));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(LoginPage))).brightness,
      Brightness.light,
    );
  });

  test('logo possui fundo transparente e conteúdo visível', () async {
    final asset = await rootBundle.load(
      'assets/images/temdas_wordmark_transparent.png',
    );
    final codec = await ui.instantiateImageCodec(asset.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final pixels = (await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!;
    expect(pixels.getUint8(3), 0);
    var visible = false;
    for (var i = 3; i < pixels.lengthInBytes; i += 4) {
      if (pixels.getUint8(i) > 0) {
        visible = true;
        break;
      }
    }
    expect(visible, isTrue);
    frame.image.dispose();
    codec.dispose();
  });

  test('destinos de links diretos e hash são preservados', () {
    expect(
      initialAppLocation(Uri.parse('https://temdas.com.br/')),
      AppRoutes.home,
    );
    expect(
      initialAppLocation(Uri.parse('https://temdas.com.br/#/perfil')),
      AppRoutes.perfil,
    );
    expect(
      initialAppLocation(
        Uri.parse('https://temdas.com.br/demandas/detalhe?id=42'),
      ),
      '/demandas/detalhe?id=42',
    );
    expect(
      initialAppLocation(Uri.parse('https://temdas.com.br/#/sprint/7')),
      '/sprint/7',
    );
  });
}
