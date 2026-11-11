import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;

import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

class _RepositorioComSprint extends FakeDemandaRepository {
  _RepositorioComSprint() : super(demandas: [demandaFixture(id: 1)]);

  List<int>? confirmados;

  @override
  Future<b.BacklogPrevia> preverEnvioAoBacklog(int id) async => b.BacklogPrevia(
    sprints: [
      b.Sprint(
        id: 5,
        usuarioId: 1,
        nome: 'Ciclo planejado',
        dataInicio: DateTime.utc(2026, 11, 12),
        dataFim: DateTime.utc(2026, 11, 30),
        status: b.SprintStatus.planejada,
      ),
    ],
    vinculos: [b.SprintDemanda(id: 6, sprintId: 5, demandaId: id)],
  );

  @override
  Future<void> alterarLocalizacao(
    int id,
    b.DemandaLocalizacao destino,
    List<int> vinculosConfirmados,
  ) {
    confirmados = vinculosConfirmados;
    return super.alterarLocalizacao(id, destino, vinculosConfirmados);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'cancelar preserva o item e confirmar envia os vínculos exibidos',
    (tester) async {
      final repo = _RepositorioComSprint();
      final vm = DemandasViewModel(repository: repo);
      final sprints = SprintViewModel(
        repository: FakeSprintRepository(sprints: []),
      );
      addTearDown(vm.dispose);
      addTearDown(sprints.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: DemandasPage(viewModel: vm, sprintViewModel: sprints),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> abrirConfirmacao() async {
        await tester.tap(find.byKey(const ValueKey('acoes-demanda-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Enviar para Backlog'));
        await tester.pumpAndSettle();
      }

      await abrirConfirmacao();
      expect(find.textContaining('Ciclo planejado'), findsOneWidget);
      expect(
        find.textContaining('horas registradas serão preservados'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.confirmados, isNull);
      expect(vm.demandas.single.id, 1);

      await abrirConfirmacao();
      await tester.tap(
        find.widgetWithText(FilledButton, 'Enviar para Backlog'),
      );
      await tester.pumpAndSettle();
      expect(repo.confirmados, [6]);
      expect(vm.demandas, isEmpty);
      expect(
        (await repo.listarDemandas(
          localizacao: b.DemandaLocalizacao.backlog,
        )).single.id,
        1,
      );
    },
  );

  testWidgets(
    'Backlog usa somente Lista e a busca global abre a rota do resultado',
    (tester) async {
      final repo = FakeDemandaRepository(
        demandas: [
          demandaFixture(id: 1, titulo: 'Projeto operacional'),
          demandaFixture(
            id: 2,
            titulo: 'Projeto pendente',
          ).copyWith(localizacao: b.DemandaLocalizacao.backlog),
        ],
      );
      final vm = DemandasViewModel(
        repository: repo,
        localizacao: b.DemandaLocalizacao.backlog,
      );
      final sprints = SprintViewModel(
        repository: FakeSprintRepository(sprints: []),
      );
      addTearDown(vm.dispose);
      addTearDown(sprints.dispose);
      RouteSettings? destino;
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            destino = settings;
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const Scaffold(body: Text('Rota de destino')),
            );
          },
          home: DemandasPage(
            localizacao: b.DemandaLocalizacao.backlog,
            viewModel: vm,
            sprintViewModel: sprints,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Backlog'), findsWidgets);
      expect(find.text('Kanban'), findsNothing);
      expect(vm.demandas.single.id, 2);

      await tester.tap(find.byTooltip('Buscar em Demandas e Backlog'));
      await tester.pumpAndSettle();
      final dialogo = find.byType(AlertDialog);
      await tester.enterText(
        find.descendant(of: dialogo, matching: find.byType(TextField)),
        'Projeto',
      );
      await tester.tap(
        find.descendant(of: dialogo, matching: find.byTooltip('Buscar')),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ListTile, 'Demandas'), findsOneWidget);
      expect(find.widgetWithText(ListTile, 'Backlog'), findsOneWidget);
      expect(vm.demandas.single.id, 2);

      await tester.tap(find.text('1 - Projeto operacional'));
      await tester.pumpAndSettle();
      expect(destino?.name, AppRoutes.demandas);
      expect(destino?.arguments, 1);
    },
  );
}
