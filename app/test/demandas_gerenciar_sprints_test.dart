import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/demanda_detalhe_page.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_dialog.dart';
import 'package:temdas/view_model/demanda_detalhe_view_model.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;

import 'demanda_painel_test.dart' show Notes;
import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

b.Sprint sprint(int id, [b.SprintStatus status = b.SprintStatus.planejada]) =>
    b.Sprint(
      id: id,
      usuarioId: 1,
      nome: 'Ciclo $id',
      dataInicio: DateTime(2026, 11, id * 3),
      dataFim: DateTime(2026, 11, id * 3 + 1),
      status: status,
    );

class _ConflitoNoSegundoVinculo extends FakeSprintRepository {
  _ConflitoNoSegundoVinculo() : super(sprints: [sprint(1), sprint(2)]);

  @override
  Future<List<b.SprintDemanda>> vincularDemanda({
    required int sprintId,
    required int demandaId,
  }) {
    if (sprintId == 2) {
      return Future.error(
        b.SprintException(codigo: b.SprintErroCodigo.periodoSobreposto),
      );
    }
    return super.vincularDemanda(sprintId: sprintId, demandaId: demandaId);
  }
}

Future<void> tocar(
  WidgetTester t,
  Finder finder, {
  bool aguardar = true,
}) async {
  await t.ensureVisible(finder);
  await t.tap(finder);
  if (aguardar) {
    await t.pumpAndSettle();
  } else {
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
  }
}

Future<void> escolher(WidgetTester t, int id, {bool aguardar = true}) async {
  final seletor = find.widgetWithText(AlertDialog, 'Selecionar Sprint');
  await tocar(
    t,
    find.descendant(of: seletor, matching: find.text('Sprint Ciclo $id')),
    aguardar: aguardar,
  );
  await tocar(t, find.widgetWithText(FilledButton, 'Confirmar'));
}

Future<void> abrirDialogo(
  WidgetTester t,
  Widget dialogo,
  ThemeData tema,
) async {
  await t.pumpWidget(
    MaterialApp(
      theme: tema,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                showDialog<void>(context: context, builder: (_) => dialogo),
            child: const Text('Abrir formulário'),
          ),
        ),
      ),
    ),
  );
  await tocar(t, find.text('Abrir formulário'));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final vincular in [false, true]) {
    testWidgets('cria uma única Demanda com vínculo opcional ($vincular)', (
      t,
    ) async {
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(360, 700);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.view.resetPhysicalSize);
      final repo = FakeDemandaRepository(demandas: []);
      final vm = DemandasViewModel(repository: repo);
      final sprints = _ConflitoNoSegundoVinculo();
      final svm = SprintViewModel(repository: sprints);
      addTearDown(vm.dispose);
      addTearDown(svm.dispose);
      await abrirDialogo(
        t,
        CriarDemandaDialog(viewModel: vm, sprintViewModel: svm),
        vincular ? AppTheme.dark : AppTheme.light,
      );
      await t.enterText(
        find.byKey(const ValueKey('criar-demanda-titulo')),
        'Demanda nova',
      );
      if (vincular) {
        await tocar(t, find.text('Adicionar Sprint'));
        await escolher(t, 1);
        await tocar(t, find.text('Adicionar Sprint'));
        await escolher(t, 2);
      }
      await tocar(
        t,
        find.byKey(const ValueKey('criar-demanda')),
        aguardar: !vincular,
      );
      if (vincular) {
        expect(
          find.text('Demanda criada com pendências nas Sprints'),
          findsOneWidget,
        );
        expect(find.textContaining('Sprint Ciclo 2:'), findsOneWidget);
        await tocar(t, find.widgetWithText(TextButton, 'Fechar'));
      }
      expect(find.byType(CriarDemandaDialog), findsNothing);
      expect(repo.chamadasCriar, 1);
      expect(
        sprints.vinculosPorSprint[1]?.single.demandaId,
        vincular ? vm.demandaCriada!.id : null,
      );
      expect(sprints.vinculosPorSprint[2], isNull);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets(
    'edição troca vínculos abertos ao salvar e protege os históricos',
    (t) async {
      final repo = FakeSprintRepository(
        sprints: [
          sprint(1),
          sprint(2),
          sprint(3, b.SprintStatus.concluida),
          sprint(4, b.SprintStatus.cancelada),
        ],
        vinculosPorSprint: {
          for (final id in [1, 3, 4])
            id: [b.SprintDemanda(sprintId: id, demandaId: 10)],
        },
      );
      final vm = SprintViewModel(repository: repo);
      addTearDown(vm.dispose);
      await abrirDialogo(
        t,
        EditarDemandaDialog(
          demanda: demandaFixture(id: 10),
          sprintViewModel: vm,
          onSalvar: (_) async => true,
        ),
        AppTheme.light,
      );
      expect(find.textContaining('Histórico'), findsNWidgets(2));
      expect(find.byTooltip('Remover vínculo ao salvar'), findsOneWidget);
      await tocar(t, find.byTooltip('Remover vínculo ao salvar'));
      await tocar(t, find.text('Adicionar Sprint'));
      await escolher(t, 2);
      expect(repo.chamadasVinculo, 0);
      expect(repo.chamadasDesvinculo, 0);
      await tocar(t, find.byKey(const ValueKey('salvar-edicao-demanda')));
      expect(repo.vinculosPorSprint[1], isEmpty);
      for (final id in [2, 3, 4]) {
        expect(repo.vinculosPorSprint[id]!.single.demandaId, 10);
      }
      expect(repo.chamadasContexto, 2);
    },
  );

  testWidgets('edição parcial mostra conflito e relê os vínculos gravados', (
    t,
  ) async {
    final repo = _ConflitoNoSegundoVinculo();
    final vm = SprintViewModel(repository: repo);
    addTearDown(vm.dispose);
    var camposSalvos = 0;
    await abrirDialogo(
      t,
      EditarDemandaDialog(
        demanda: demandaFixture(id: 10),
        sprintViewModel: vm,
        onSalvar: (_) async {
          camposSalvos++;
          return true;
        },
      ),
      AppTheme.dark,
    );
    for (final id in [1, 2]) {
      await tocar(t, find.text('Adicionar Sprint'));
      await escolher(t, id);
    }
    await tocar(
      t,
      find.byKey(const ValueKey('salvar-edicao-demanda')),
      aguardar: false,
    );
    expect(
      find.text('Campos salvos com pendências nas Sprints'),
      findsOneWidget,
    );
    expect(repo.vinculosPorSprint[1]!.single.demandaId, 10);
    expect(repo.vinculosPorSprint[2], isNull);
    expect(repo.chamadasContexto, 2);
    expect(camposSalvos, 1);
    await tocar(t, find.widgetWithText(TextButton, 'Fechar'));
  });

  testWidgets(
    'painel atualiza vínculo e confirma remoção sem buscar a Demanda novamente',
    (t) async {
      final repo = FakeSprintRepository(sprints: [sprint(1)]);
      final demandas = FakeDemandaRepository(
        demandas: [demandaFixture(id: 10)],
      );
      final vm = DemandaDetalheViewModel(
        demandaRepository: demandas,
        registroTempoRepository: FakeRegistroTempoRepository(),
        anotacaoRepository: Notes(),
        sprintViewModel: SprintViewModel(repository: repo),
      );
      addTearDown(vm.dispose);
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    mostrarDetalhesDemandaDialog(context, 10, viewModel: vm),
                child: const Text('Abrir painel'),
              ),
            ),
          ),
        ),
      );
      await tocar(t, find.text('Abrir painel'));
      await tocar(t, find.text('Vincular'), aguardar: false);
      await escolher(t, 1, aguardar: false);
      expect(vm.sprints.single.id, 1);
      await tocar(t, find.text('Desvincular Sprint Ciclo 1'), aguardar: false);
      expect(repo.chamadasDesvinculo, 0);
      await tocar(t, find.widgetWithText(FilledButton, 'Desvincular'));
      expect(vm.sprints, isEmpty);
      expect(repo.chamadasDesvinculo, 1);
      expect(demandas.chamadasBuscar, 1);
    },
  );

  testWidgets(
    'lote na Lista mantém seleção em conflito e atualiza filtro Sem Sprint após sucesso',
    (t) async {
      SharedPreferences.setMockInitialValues({
        'temdas.demandas.visualizacao': 'lista',
      });
      final repo = FakeSprintRepository(sprints: [sprint(1)]);
      final vm = DemandasViewModel(
        repository: FakeDemandaRepository(
          demandas: [demandaFixture(id: 10), demandaFixture(id: 11)],
        ),
      );
      final svm = SprintViewModel(repository: repo);
      addTearDown(vm.dispose);
      addTearDown(svm.dispose);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: DemandasPage(viewModel: vm, sprintViewModel: svm),
        ),
      );
      await t.pumpAndSettle();
      await tocar(t, find.byKey(const ValueKey('abrir-filtros-demandas')));
      await tocar(t, find.byType(DropdownButtonFormField<int?>));
      await tocar(t, find.text('Sem Sprint').last);
      await tocar(t, find.widgetWithText(FilledButton, 'Concluir'));
      await tocar(t, find.byKey(const ValueKey('alternar-modo-selecao-lista')));
      await tocar(t, find.byKey(const ValueKey('selecionar-demanda-10')));
      await tocar(t, find.byKey(const ValueKey('selecionar-demanda-11')));
      repo.erroVinculo = b.SprintException(
        codigo: b.SprintErroCodigo.periodoSobreposto,
      );
      await tocar(t, find.text('Ações'));
      await tocar(t, find.text('Vincular à Sprint'));
      await escolher(t, 1);
      expect(find.text('2 selecionadas'), findsOneWidget);
      expect(repo.vinculosPorSprint, isEmpty);
      repo.erroVinculo = null;
      await tocar(t, find.text('Ações'));
      await tocar(t, find.text('Vincular à Sprint'));
      await escolher(t, 1);
      expect(repo.chamadasVinculoLote, 2);
      expect(repo.demandaIdsVinculadas, unorderedEquals([10, 11]));
      expect(find.byKey(const ValueKey('demanda-card-10')), findsNothing);
      expect(find.byKey(const ValueKey('demanda-card-11')), findsNothing);
    },
  );
}
