import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/theme/theme_preference.dart';
import 'package:temdas/ui/components/demand_components.dart';
import 'package:temdas/ui/components/app_shell.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view_model/demandas_visualizacao.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

Future<FakeDemandaRepository> open(
  WidgetTester tester, {
  double width = 1440,
  bool dark = false,
  String mode = 'kanban',
  double scale = 1,
  List<b.Demanda>? demands,
}) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    DemandasVisualizacao.storageKey: mode,
  });
  final repo = FakeDemandaRepository(
    demandas:
        demands ??
        [
          demandaFixture(
            id: 13,
            titulo:
                'Preparar integração e revisar os critérios de aceite com título extenso',
            status: b.DemandaStatus.emAndamento,
            tempoEstimadoMinutos: 2400,
            tempoExecutadoMinutos: 615,
          ),
          demandaFixture(
            id: 14,
            demandaPaiId: 13,
            titulo: 'Subdemanda preservada',
          ),
          demandaFixture(
            id: 15,
            titulo: 'Revisar planejamento',
            tempoEstimadoMinutos: 600,
          ),
          demandaFixture(
            id: 16,
            titulo: 'Entrega concluída',
            status: b.DemandaStatus.concluida,
            tempoExecutadoMinutos: 60,
          ),
        ],
  );
  final vm = DemandasViewModel(repository: repo);
  final svm = SprintViewModel(repository: FakeSprintRepository(sprints: []));
  final preference = ThemePreference();
  addTearDown(vm.dispose);
  addTearDown(svm.dispose);
  addTearDown(preference.dispose);
  await tester.pumpWidget(
    ThemePreferenceScope(
      notifier: preference,
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: RepaintBoundary(
          key: const ValueKey('capture'),
          child: DemandasPage(viewModel: vm, sprintViewModel: svm),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  setUpAll(() async {
    for (final font in {
      'packages/material_symbols_icons/MaterialSymbolsRounded':
          'packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
      'Roboto Mono': 'assets/fonts/inter/RobotoMono-Regular.ttf',
    }.entries) {
      final loader = FontLoader(font.key)..addFont(rootBundle.load(font.value));
      await loader.load();
    }
  });
  test('horas pt-BR sem zeros residuais', () {
    expect(HoursLabel.format(0), '0');
    expect(HoursLabel.format(60), '1');
    expect(HoursLabel.format(30), '0,5');
    expect(HoursLabel.format(615), '10,25');
  });
  for (final width in [
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
      for (final mode in ['lista', 'kanban']) {
        testWidgets(
          '$mode $width escuro=$dark: títulos longos, horas e navegação',
          (tester) async {
            await open(tester, width: width, dark: dark, mode: mode);
            expect(tester.takeException(), isNull);
            expect(find.byType(AppShell), findsOneWidget);
            final search = tester.getRect(find.byType(SearchField));
            expect(search.left, greaterThanOrEqualTo(0));
            expect(search.right, lessThanOrEqualTo(width));
            final shell = tester.getRect(find.byType(AppShell));
            expect(shell.width, width);
            if (width < 600) expect(find.byType(AppFab), findsOneWidget);
            expect(
              find.byType(mode == 'lista' ? DemandRow : DemandCard),
              findsWidgets,
            );
            final dir = Platform.environment['TEMDAS_SCREENSHOTS'];
            if (dir != null) {
              await tester.runAsync(() async {
                final boundary = tester.renderObject<RenderRepaintBoundary>(
                  find.byKey(const ValueKey('capture')),
                );
                final capture = await boundary.toImage();
                final bytes = await capture.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                Directory(dir).createSync(recursive: true);
                File(
                  '$dir/${mode}_${width.toInt()}_${dark ? 'dark' : 'light'}.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
                capture.dispose();
              });
            }
          },
        );
      }
    }
  }
  for (final width in [360.0, 768.0, 1440.0]) {
    for (final mode in ['lista', 'kanban']) {
      testWidgets('$mode $width texto ampliado', (tester) async {
        await open(tester, width: width, mode: mode, scale: 1.8);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('preferência mantida ao mudar de breakpoint e ao reabrir', (
    tester,
  ) async {
    await open(tester, width: 1440, mode: 'lista');
    tester.view.physicalSize = const Size(390, 900);
    await tester.pumpAndSettle();
    expect(find.byType(DemandRow), findsWidgets);
    expect(find.byType(DemandCard), findsNothing);
    await tester.tap(find.byTooltip('Kanban').last);
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getString(
        DemandasVisualizacao.storageKey,
      ),
      'kanban',
    );
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byType(DemandCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('busca sem resultados limpa busca e preserva árvore', (
    tester,
  ) async {
    await open(tester, mode: 'lista');
    await tester.enterText(
      find.byKey(const ValueKey('buscar-demandas')),
      'inexistente',
    );
    await tester.pumpAndSettle();
    expect(find.text('Nenhuma demanda encontrada'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Limpar busca'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demanda-card-13')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('expandir-demanda-13')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demanda-card-14')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('atualizar mantém conteúdo e não mostra skeleton parcial', (
    tester,
  ) async {
    final repo = await open(tester, mode: 'lista');
    final pending = Completer<List<b.Demanda>>();
    repo.respostasListarPendentes.add(pending);
    await tester.tap(find.byTooltip('Recarregar demandas'));
    await tester.pump();
    expect(find.byKey(const ValueKey('demanda-card-13')), findsOneWidget);
    expect(find.byType(SkeletonRow), findsNothing);
    pending.complete([demandaFixture(id: 13)]);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('celular arrasta o card com pressão longa até uma aba', (
    tester,
  ) async {
    final repo = await open(tester, width: 390);
    final origin = tester.getCenter(
      find.byKey(const ValueKey('demanda-long-press-13')),
    );
    final target = tester.getCenter(find.text('Aberta'));
    final gesture = await tester.startGesture(origin);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(repo.ultimaMovimentacao?.demandaId, 13);
    expect(repo.ultimaMovimentacao?.statusDestino, b.DemandaStatus.aberta);
    expect(tester.takeException(), isNull);
  });
  testWidgets('vazio oferece a ação existente de criar', (tester) async {
    await open(tester, width: 390, demands: []);
    expect(find.text('Nenhuma demanda ainda.'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Criar demanda'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
