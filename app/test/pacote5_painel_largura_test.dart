import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/widgets/demanda_painel_redimensionavel.dart';
import 'package:temdas/view_model/largura_painel_demanda.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    '420 padrão, limites, persistência e corrida da carga inicial',
    () async {
      final w = LarguraPainelDemanda();
      addTearDown(w.dispose);
      expect(w.paraViewport(1440), 420);
      final loading = w.load();
      w.ajustar(600, 1440);
      await w.salvar();
      await loading;
      expect(w.value, 600);
      expect(w.paraViewport(390), 390);
      w.ajustar(390, 390);
      expect(w.value, 600);
      expect(w.paraViewport(840), 588);
      expect(w.paraViewport(1440), 600);
      w.ajustar(2000, 1440);
      expect(w.value, 1008);
      w.ajustar(200, 1440);
      expect(w.value, 360);
      w.ajustar(600, 1440);
      final first = w.salvar();
      w.ajustar(480, 1440);
      final second = w.salvar();
      await Future.wait([first, second]);
      final restored = LarguraPainelDemanda();
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.value, 480);
      await restored.alternar(1440);
      expect(restored.value, 1008);
      await restored.alternar(1440);
      expect(restored.value, 420);
    },
  );
  for (final invalid in [
    double.nan,
    double.infinity,
    -1.0,
    200.0,
    'inválida',
  ]) {
    test('preferência inválida $invalid mantém padrão', () async {
      SharedPreferences.setMockInitialValues({
        LarguraPainelDemanda.storageKey: invalid,
      });
      final w = LarguraPainelDemanda();
      addTearDown(w.dispose);
      await w.load();
      expect(w.paraViewport(1440), 420);
    });
  }
  final panel = find.byKey(const ValueKey('demanda-detalhe-dialog'));
  final edge = find.byKey(const ValueKey('redimensionar-painel-demanda'));
  Future<void> open(
    WidgetTester tester, {
    Brightness theme = Brightness.light,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme == Brightness.light ? AppTheme.light : AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: DemandaPainelRedimensionavel(
            title: 'Demanda #42',
            onClose: () {},
            child: const Column(
              children: [
                TextField(key: ValueKey('texto-preservado')),
                Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final theme in Brightness.values) {
    testWidgets('ícone, mouse e restauração preservam estado em $theme', (
      tester,
    ) async {
      await open(tester, theme: theme);
      expect(tester.getSize(panel).width, 420);
      await tester.enterText(
        find.byKey(const ValueKey('texto-preservado')),
        'texto não salvo',
      );
      await tester.tap(find.byTooltip('Ampliar painel'));
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, 1008);
      await tester.tap(find.byTooltip('Reduzir painel'));
      await tester.pumpAndSettle();
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getCenter(edge));
      await gesture.down(tester.getCenter(edge));
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();
      await gesture.up();
      await gesture.removePointer();
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, closeTo(580, 1));
      expect(find.text('texto não salvo'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getDouble(
          LarguraPainelDemanda.storageKey,
        ),
        closeTo(580, 1),
      );
      await tester.pumpWidget(const SizedBox());
      await open(tester, theme: theme);
      expect(tester.getSize(panel).width, closeTo(580, 1));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'toque, limites, teclado e celular preservam preferência desktop',
    (tester) async {
      await open(tester);
      await tester.drag(edge, const Offset(-1600, 0));
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, 1008);
      await tester.drag(edge, const Offset(1600, 0));
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, 360);
      Focus.of(tester.element(edge)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, 420);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, 440);
      tester.view.physicalSize = const Size(390, 900);
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, 390);
      expect(edge, findsNothing);
      expect(
        find.byKey(const ValueKey('ampliar-painel-demanda')),
        findsNothing,
      );
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      expect(tester.getSize(panel).width, 440);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('420 px suporta texto ampliado', (tester) async {
    await open(tester, scale: 2);
    expect(tester.getSize(panel).width, 420);
    expect(find.byTooltip('Fechar detalhes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
