import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view/widgets/demanda_tree.dart';
import 'package:temdas/view/widgets/densidade_demanda.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/demandas_visualizacao.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

b.Sprint sprint(int id, b.SprintStatus status) => b.Sprint(
  id: id,
  usuarioId: 1,
  nome: 'Ciclo $id',
  dataInicio: DateTime(2026, 10, 1),
  dataFim: DateTime(2026, 10, 8),
  status: status,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Kanban padrão, escolha persistida, carga não sobrescreve seleção',
    () async {
      final preference = DemandasVisualizacao();
      addTearDown(preference.dispose);
      expect(preference.value, VisualizacaoDemandas.kanban);
      final loading = preference.load();
      await preference.select(VisualizacaoDemandas.lista);
      await loading;
      expect(preference.value, VisualizacaoDemandas.lista);
      final restored = DemandasVisualizacao();
      addTearDown(restored.dispose);
      await restored.load();
      expect(restored.value, VisualizacaoDemandas.lista);
      final first = restored.select(VisualizacaoDemandas.lista);
      final second = restored.select(VisualizacaoDemandas.kanban);
      await Future.wait([first, second]);
      expect(
        (await SharedPreferences.getInstance()).getString(
          DemandasVisualizacao.storageKey,
        ),
        'kanban',
      );
    },
  );

  test('preferência inválida usa Kanban', () async {
    SharedPreferences.setMockInitialValues({
      DemandasVisualizacao.storageKey: 'invalida',
    });
    final preference = DemandasVisualizacao();
    addTearDown(preference.dispose);
    await preference.load();
    expect(preference.value, VisualizacaoDemandas.kanban);
  });

  Future<FakeDemandaRepository> open(
    WidgetTester tester, {
    List<b.Demanda>? demandas,
    double width = 1440,
    List<b.Sprint>? sprints,
    Map<int, List<b.SprintDemanda>> links = const {},
    double scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = FakeDemandaRepository(
      demandas:
          demandas ??
          [
            demandaFixture(
              id: 1,
              titulo: 'Demanda mãe',
              status: b.DemandaStatus.emAndamento,
            ),
            demandaFixture(
              id: 2,
              demandaPaiId: 1,
              titulo: 'Ação de autenticação',
              prioridade: b.Prioridade.alta,
            ),
            demandaFixture(
              id: 3,
              titulo: 'Outra demanda',
              prioridade: b.Prioridade.alta,
            ),
          ],
    );
    final vm = DemandasViewModel(repository: repo);
    final svm = SprintViewModel(
      repository: FakeSprintRepository(
        sprints: sprints ?? [],
        vinculosPorSprint: links,
      ),
    );
    addTearDown(vm.dispose);
    addTearDown(svm.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: Size(width, 850),
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: DemandasPage(viewModel: vm, sprintViewModel: svm),
      ),
    );
    await tester.pumpAndSettle();
    return repo;
  }

  Future<void> filter(WidgetTester tester, String field, String value) async {
    await tester.tap(find.byKey(const ValueKey('abrir-filtros-demandas')));
    await tester.pumpAndSettle();
    final dropdown = field == 'Prioridade'
        ? find.byType(DropdownButtonFormField<b.Prioridade?>)
        : find.byType(DropdownButtonFormField<int?>);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Concluir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'busca sem acentos combina filtros e preserva ancestrais nas duas vistas',
    (tester) async {
      await open(
        tester,
        sprints: [sprint(1, b.SprintStatus.ativa)],
        links: {
          1: [b.SprintDemanda(sprintId: 1, demandaId: 2)],
        },
      );
      await tester.enterText(
        find.byKey(const ValueKey('buscar-demandas')),
        'ACAO DE AUTENTICACAO',
      );
      await tester.pumpAndSettle();
      await filter(tester, 'Prioridade', 'Alta');
      await filter(tester, 'Sprint', 'Ciclo 1');
      expect(find.text('Filtros (2)'), findsOneWidget);
      expect(find.byKey(const ValueKey('demanda-card-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('demanda-card-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('demanda-card-3')), findsNothing);
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('demandas-lista-status')),
        findsOneWidget,
      );
      expect(find.byWidgetPredicate((w) => w is Draggable), findsNothing);
      expect(find.byKey(const ValueKey('demanda-card-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('status-demanda-2')), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getString(
          DemandasVisualizacao.storageKey,
        ),
        'lista',
      );
      await tester.tap(find.text('Kanban'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('demandas-quadro-status')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('demanda-card-2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Sem Sprint usa exclusivamente vínculos abertos; Limpar preserva busca',
    (tester) async {
      await open(
        tester,
        demandas: [
          demandaFixture(id: 1, titulo: 'Relatório atual'),
          demandaFixture(id: 2, titulo: 'Relatório antigo'),
        ],
        sprints: [
          sprint(1, b.SprintStatus.ativa),
          sprint(2, b.SprintStatus.concluida),
        ],
        links: {
          1: [b.SprintDemanda(sprintId: 1, demandaId: 1)],
          2: [b.SprintDemanda(sprintId: 2, demandaId: 2)],
        },
      );
      await tester.enterText(
        find.byKey(const ValueKey('buscar-demandas')),
        'RELATORIO',
      );
      await tester.pumpAndSettle();
      await filter(tester, 'Sprint', 'Sem Sprint');
      expect(find.byKey(const ValueKey('demanda-card-1')), findsNothing);
      expect(find.byKey(const ValueKey('demanda-card-2')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('abrir-filtros-demandas')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('limpar-filtros-demandas')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Concluir'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('buscar-demandas')))
            .controller!
            .text,
        'RELATORIO',
      );
      expect(find.byType(DemandaCard), findsNWidgets(2));
    },
  );

  testWidgets('filtro de Sprint sem vínculos e estado sem resultados', (
    tester,
  ) async {
    await open(tester, sprints: [sprint(8, b.SprintStatus.planejada)]);
    await filter(tester, 'Sprint', 'Ciclo 8');
    expect(
      find.text('Nenhuma demanda encontrada. Ajuste a busca ou os filtros.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Lista restaura preferência e altera status pelas operações existentes',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        DemandasVisualizacao.storageKey: 'lista',
      });
      final repo = await open(tester, demandas: [demandaFixture(id: 1)]);
      expect(
        find.byKey(const ValueKey('demandas-lista-status')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('status-demanda-1')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('status-opcao-emAndamento-1')),
      );
      await tester.pumpAndSettle();
      expect(repo.chamadasAlterarStatus, 1);
      expect(repo.ultimaAlteracaoStatus?.status, b.DemandaStatus.emAndamento);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Lista mantém densidade compacta e restaura densidade do Kanban',
    (tester) async {
      await open(tester, demandas: [demandaFixture(id: 1)]);
      await tester.tap(find.byTooltip('Densidade dos cards'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(
          CheckedPopupMenuItem<DensidadeDemanda>,
          'Visualização normal',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<DemandaCard>(find.byType(DemandaCard)).densidade,
        DensidadeDemanda.normal,
      );
      await tester.tap(find.text('Lista'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DemandaCard>(find.byType(DemandaCard)).densidade,
        DensidadeDemanda.compacta,
      );
      await tester.tap(find.text('Kanban'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DemandaCard>(find.byType(DemandaCard)).densidade,
        DensidadeDemanda.normal,
      );
    },
  );

  testWidgets('filtrar não recalcula para menos o total da árvore', (
    tester,
  ) async {
    await open(
      tester,
      demandas: [
        demandaFixture(id: 1, titulo: 'Mãe', tempoExecutadoMinutos: 30),
        demandaFixture(
          id: 2,
          demandaPaiId: 1,
          titulo: 'Encontrar',
          tempoExecutadoMinutos: 30,
        ),
        demandaFixture(
          id: 3,
          demandaPaiId: 1,
          titulo: 'Oculta',
          tempoExecutadoMinutos: 60,
        ),
      ],
    );
    await tester.enterText(
      find.byKey(const ValueKey('buscar-demandas')),
      'Encontrar',
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('demanda-card-3')), findsNothing);
    expect(
      tester
          .widget<DemandaCard>(
            find.byKey(const PageStorageKey('demanda-expansao-1')),
          )
          .tempoExecutadoTotalMinutos,
      120,
    );
    await tester.tap(find.text('Lista'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DemandaCard>(
            find.byKey(const PageStorageKey('demanda-expansao-1')),
          )
          .tempoExecutadoTotalMinutos,
      120,
    );
  });

  testWidgets(
    'filtros abertos acompanham a conclusão da consulta de vínculos',
    (tester) async {
      final repo = FakeSprintRepository(sprints: []);
      final pending = Completer<List<b.Sprint>>();
      repo.listaPendente = pending;
      final vm = DemandasViewModel(
        repository: FakeDemandaRepository(demandas: []),
      );
      final svm = SprintViewModel(repository: repo);
      addTearDown(vm.dispose);
      addTearDown(svm.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: DemandasPage(viewModel: vm, sprintViewModel: svm),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('abrir-filtros-demandas')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<DropdownButtonFormField<int?>>(
              find.byType(DropdownButtonFormField<int?>),
            )
            .onChanged,
        isNull,
      );
      pending.complete([sprint(9, b.SprintStatus.planejada)]);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<int?>>(
              find.byType(DropdownButtonFormField<int?>),
            )
            .onChanged,
        isNotNull,
      );
      expect(find.text('Consultando vínculos…'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'corpo da Lista abre detalhes e só o chevron expande a hierarquia',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      final opened = <int?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DemandaTree(
                horizontalController: controller,
                demandas: [
                  demandaFixture(id: 1),
                  demandaFixture(id: 2, demandaPaiId: 1),
                ],
                lista: true,
                acoesHabilitadas: true,
                onEditar: (_) {},
                onExcluir: (_) {},
                onCriarFilha: (_) {},
                onLancarTempo: (_) {},
                onMostrarTudo: (demanda) => opened.add(demanda.id),
                onAlterarStatus: (_, _) {},
                onConcluir: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('abrir-painel-demanda-1')));
      await tester.pumpAndSettle();
      expect(opened, [1]);
      expect(find.byKey(const ValueKey('demanda-card-2')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
      await tester.pumpAndSettle();
      expect(opened, [1]);
      expect(find.byKey(const ValueKey('demanda-card-2')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('abrir-painel-demanda-2')));
      await tester.pumpAndSettle();
      expect(opened, [1, 2]);
    },
  );

  for (final width in [360.0, 800.0, 1440.0]) {
    testWidgets(
      'Lista em $width px com texto ampliado preserva expansão e detalhes',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          DemandasVisualizacao.storageKey: 'lista',
        });
        await open(tester, width: width, scale: 1.6);
        expect(find.byKey(const ValueKey('demanda-card-2')), findsNothing);
        await tester.ensureVisible(
          find.byKey(const ValueKey('expandir-demanda-1')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('expandir-demanda-1')));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('demanda-card-2')), findsOneWidget);
        final tree = tester.widget<DemandaTree>(find.byType(DemandaTree));
        expect(tree.lista, isTrue);
        final card = tester.widget<DemandaCard>(find.byType(DemandaCard).first);
        expect(card.onMostrarTudo, isNotNull);
        expect(
          find.byKey(const ValueKey('abrir-painel-demanda-1')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
