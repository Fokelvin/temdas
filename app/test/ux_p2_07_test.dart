import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/ui/components/demand_components.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view_model/demanda_hierarquia_lista.dart';
import 'package:temdas/view_model/demanda_lista_preferencias.dart';
import 'package:temdas/view_model/demandas_agrupamento.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/demandas_visualizacao.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;

import 'demandas_redesign_test.dart' show open;
import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

final demandas = [
  demandaFixture(id: 1, titulo: 'Projeto Z', prioridade: b.Prioridade.urgente),
  demandaFixture(id: 2, demandaPaiId: 1, titulo: 'Etapa B'),
  demandaFixture(
    id: 3,
    demandaPaiId: 2,
    titulo: 'Revisão técnica',
    prioridade: b.Prioridade.alta,
  ),
  demandaFixture(id: 4, demandaPaiId: 1, titulo: 'Etapa A'),
  demandaFixture(id: 5, titulo: 'Projeto A'),
  demandaFixture(
    id: 6,
    titulo: 'Revisão independente',
    prioridade: b.Prioridade.alta,
  ),
];

Finder linha(int id) => find.byKey(ValueKey('demanda-card-$id'));

Future<void> capturar(WidgetTester tester, String nome) async {
  final diretorio = Platform.environment['TEMDAS_SELECTION_SCREENSHOTS'];
  if (diretorio == null) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    final imagem = await boundary.toImage();
    final bytes = await imagem.toByteData(format: ui.ImageByteFormat.png);
    Directory(diretorio).createSync(recursive: true);
    File('$diretorio/$nome.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    imagem.dispose();
  });
}

Future<void> fecharDialogo(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Concluir'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final loader =
        FontLoader(
          'packages/material_symbols_icons/MaterialSymbolsRounded',
        )..addFont(
          rootBundle.load(
            'packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
          ),
        );
    await loader.load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Tipo usa a árvore completa e Filha prevalece sobre Mãe', () {
    final hierarquia = DemandaHierarquiaLista(demandas);
    expect(hierarquia.tipo(demandas[0]), TipoDemanda.mae);
    expect(hierarquia.tipo(demandas[1]), TipoDemanda.filha);
    expect(hierarquia.tipo(demandas.last), TipoDemanda.independente);
    final orfa = demandaFixture(id: 20, demandaPaiId: 30);
    expect(DemandaHierarquiaLista([orfa]).tipo(orfa), TipoDemanda.filha);
  });

  test('ordenação desempata pela ordem de entrada e conserva o modelo', () {
    final itens = [
      demandas[0].copyWith(ordem: 8),
      demandas[4].copyWith(ordem: 3),
      demandas[2].copyWith(ordem: 1),
    ];
    final hierarquia = DemandaHierarquiaLista(itens);
    final ordenadas = hierarquia.ordenar(
      itens,
      (coluna: ColunaDemanda.executado, crescente: false),
      {3: 90},
    );
    expect(ordenadas.map((d) => d.id), [3, 1, 5]);
    expect(itens.map((d) => (d.id, d.ordem)), [(1, 8), (5, 3), (3, 1)]);
  });

  test(
    'preferências isolam páginas e preservam a coluna obrigatória',
    () async {
      final demandasPrefs = DemandaListaPreferencias('demandas');
      final backlogPrefs = DemandaListaPreferencias('backlog');
      final reaberta = DemandaListaPreferencias('demandas');
      addTearDown(demandasPrefs.dispose);
      addTearDown(backlogPrefs.dispose);
      addTearDown(reaberta.dispose);
      await demandasPrefs.alternarColuna(ColunaDemanda.demanda);
      await demandasPrefs.alternarColuna(ColunaDemanda.tipo);
      await Future.wait([
        demandasPrefs.ordenar(ColunaDemanda.tipo),
        demandasPrefs.ordenar(ColunaDemanda.tipo),
      ]);
      await reaberta.load();
      await backlogPrefs.load();
      expect(
        reaberta.colunas,
        containsAll([ColunaDemanda.demanda, ColunaDemanda.tipo]),
      );
      expect(reaberta.ordem, (coluna: ColunaDemanda.tipo, crescente: false));
      expect(backlogPrefs.colunas, ColunaDemanda.padrao);
      expect(backlogPrefs.ordem, isNull);
      await reaberta.alternarColuna(ColunaDemanda.tipo);
      expect(reaberta.ordem, isNull);
    },
  );

  test(
    'preferências inválidas conservam as colunas padrão e a ordem original',
    () async {
      SharedPreferences.setMockInitialValues({
        'temdas.demandas.lista':
            '{"colunas":[42],"ordem":"sprint","crescente":true}',
      });
      final prefs = DemandaListaPreferencias('demandas');
      addTearDown(prefs.dispose);
      await prefs.load();
      expect(prefs.colunas, ColunaDemanda.padrao);
      expect(prefs.ordem, isNull);
    },
  );

  testWidgets(
    'cabeçalho ordena irmãos em ambas as direções sem misturar ramos',
    (tester) async {
      await open(tester, mode: 'lista', density: 'compacta', demands: demandas);
      await tester.tap(find.text('Expandir todas'));
      await tester.pumpAndSettle();
      expect(linha(3), findsOneWidget);
      expect(find.text('Concluir demanda'), findsNothing);
      final cabecalho = find.byKey(const ValueKey('ordenar-lista-demanda'));
      await tester.tap(cabecalho);
      await tester.pumpAndSettle();
      double y(int id) => tester.getTopLeft(linha(id)).dy;
      expect(y(5), lessThan(y(1)));
      expect(y(1), lessThan(y(4)));
      expect(y(4), lessThan(y(2)));
      expect(y(2), lessThan(y(3)));
      await tester.tap(cabecalho);
      await tester.pumpAndSettle();
      expect(y(1), lessThan(y(2)));
      expect(y(2), lessThan(y(3)));
      expect(y(3), lessThan(y(4)));
      expect(y(4), lessThan(y(5)));
      expect(find.byKey(const ValueKey('ordenar-lista-sprint')), findsNothing);
    },
  );

  testWidgets('chevron recolhe individualmente um ramo expandido em lote', (
    tester,
  ) async {
    await open(tester, mode: 'lista', density: 'compacta', demands: demandas);
    await tester.tap(find.text('Expandir todas'));
    await tester.pumpAndSettle();
    final chevron = find.byKey(const ValueKey('expandir-demanda-1'));
    expect(tester.widget<IconButton>(chevron).tooltip, 'Recolher demanda');
    await tester.tap(chevron);
    await tester.pumpAndSettle();
    expect(linha(2), findsNothing);
    expect(find.text('Concluir demanda'), findsNothing);
  });

  testWidgets('expansão coletiva preserva detalhes individuais e busca ativa', (
    tester,
  ) async {
    await open(tester, mode: 'lista', density: 'compacta', demands: demandas);
    await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
    await tester.pumpAndSettle();
    expect(find.text('Concluir demanda'), findsOneWidget);
    await tester.tap(find.text('Expandir todas'));
    await tester.pumpAndSettle();
    expect(linha(3), findsOneWidget);
    expect(find.text('Concluir demanda'), findsOneWidget);
    await tester.tap(find.text('Recolher todas'));
    await tester.pumpAndSettle();
    expect(linha(2), findsNothing);
    expect(find.text('Concluir demanda'), findsOneWidget);

    final busca = find.byKey(const ValueKey('buscar-demandas'));
    await tester.enterText(busca, '#3');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recolher todas'));
    await tester.pumpAndSettle();
    expect(linha(3), findsOneWidget);
    await tester.enterText(busca, '');
    await tester.pumpAndSettle();
    expect(linha(2), findsNothing);
    expect(find.text('Concluir demanda'), findsOneWidget);
  });

  testWidgets(
    'Possui filhas combina busca, Prioridade e Sprint e revela um grupo recolhido',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        DemandasVisualizacao.storageKey: 'lista',
        DemandasAgrupamento.storageKey: 'prioridade',
      });
      final vm = DemandasViewModel(
        repository: FakeDemandaRepository(demandas: demandas),
      );
      final sprintVm = SprintViewModel(
        repository: FakeSprintRepository(
          sprints: [
            b.Sprint(
              id: 10,
              usuarioId: 1,
              nome: 'A',
              status: b.SprintStatus.ativa,
              dataInicio: DateTime.utc(2026, 10),
              dataFim: DateTime.utc(2026, 11),
            ),
          ],
          vinculosPorSprint: {
            10: [
              b.SprintDemanda(sprintId: 10, demandaId: 3),
              b.SprintDemanda(sprintId: 10, demandaId: 6),
            ],
          },
        ),
      );
      addTearDown(vm.dispose);
      addTearDown(sprintVm.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: DemandasPage(viewModel: vm, sprintViewModel: sprintVm),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Expandir todas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Recolher todas'));
      await tester.pumpAndSettle();
      expect(linha(1), findsNothing);
      expect(
        tester
            .widgetList<GroupHeader>(find.byType(GroupHeader))
            .every((g) => g.collapsed),
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('abrir-filtros-demandas')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Possui filhas'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<b.Prioridade?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alta').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int?>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sprint A').last);
      await tester.pumpAndSettle();
      await fecharDialogo(tester);

      await tester.enterText(
        find.byKey(const ValueKey('buscar-demandas')),
        'revisao',
      );
      await tester.pumpAndSettle();
      expect(linha(1), findsOneWidget);
      expect(linha(2), findsOneWidget);
      expect(linha(3), findsOneWidget);
      for (final id in [4, 5, 6]) {
        expect(linha(id), findsNothing);
      }
      expect(
        tester.widget<GroupHeader>(find.byType(GroupHeader)).prioridade,
        b.Prioridade.urgente,
      );
      expect(find.text('Concluir demanda'), findsNothing);
      await tester.tap(find.byTooltip('Kanban'));
      await tester.pumpAndSettle();
      expect(find.text('Escolher colunas'), findsNothing);
      expect(linha(6), findsOneWidget);
    },
  );

  testWidgets(
    'escolha de colunas mantém Demanda e a seleção com Sprint oculta',
    (tester) async {
      await open(
        tester,
        mode: 'lista',
        density: 'compacta',
        width: 390,
        demands: demandas,
      );
      await tester.tap(find.text('Escolher colunas'));
      await tester.pumpAndSettle();
      final obrigatoria = find.widgetWithText(CheckboxListTile, 'Demanda');
      expect(tester.widget<CheckboxListTile>(obrigatoria).value, isTrue);
      expect(tester.widget<CheckboxListTile>(obrigatoria).onChanged, isNull);
      for (final label in ['Sprint', 'Data de criação', 'Tipo']) {
        final coluna = find.widgetWithText(CheckboxListTile, label);
        await tester.ensureVisible(coluna);
        await tester.tap(coluna);
        await tester.pumpAndSettle();
      }
      await fecharDialogo(tester);
      expect(find.textContaining('Tipo: Mãe'), findsOneWidget);
      expect(find.textContaining('Data de criação:'), findsWidgets);
      expect(find.text('Sem Sprint'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('alternar-modo-selecao-lista')),
      );
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: linha(1), matching: find.byType(Checkbox)),
        findsOneWidget,
      );
      expect(find.text('Ações'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final width in [390.0, 1440.0]) {
    for (final dark in [false, true]) {
      for (final density in ['normal', 'compacta']) {
        testWidgets('seleção em lote alinhada $width escuro=$dark $density', (
          tester,
        ) async {
          await open(
            tester,
            mode: 'lista',
            width: width,
            dark: dark,
            density: density,
            demands: demandas,
          );
          final alternar = find.byKey(
            const ValueKey('alternar-modo-selecao-lista'),
          );
          expect(find.byType(Checkbox), findsNothing);
          await tester.tap(alternar);
          await tester.pumpAndSettle();

          final checkbox = find.byKey(const ValueKey('selecionar-demanda-1'));
          expect(tester.widget<Checkbox>(checkbox).value, isFalse);
          expect(
            (tester.getCenter(alternar).dx - tester.getCenter(checkbox).dx)
                .abs(),
            lessThan(2),
          );
          expect(
            find.byKey(const ValueKey('selecionar-demanda-sprint-1')),
            findsNothing,
          );
          expect(find.text('Ações'), findsNothing);

          await tester.tap(checkbox);
          await tester.pumpAndSettle();
          expect(find.text('1 selecionada'), findsOneWidget);
          expect(find.byTooltip('Ações'), findsOneWidget);
          await capturar(
            tester,
            'selection_${width.toInt()}_${dark ? 'dark' : 'light'}_$density',
          );
          await tester.tap(find.byTooltip('Ações'));
          await tester.pumpAndSettle();
          expect(find.text('Vincular à Sprint'), findsOneWidget);
          await tester.tapAt(const Offset(4, 4));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('selecionar-demanda-1')),
            findsOneWidget,
          );
          expect(find.text('1 selecionada'), findsOneWidget);
          await capturar(
            tester,
            'selection_details_${width.toInt()}_${dark ? 'dark' : 'light'}_$density',
          );
          await tester.tap(find.text('Cancelar seleção'));
          await tester.pumpAndSettle();
          expect(
            find.byKey(const ValueKey('selecionar-demanda-1')),
            findsNothing,
          );
          expect(find.byType(Checkbox), findsNothing);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
