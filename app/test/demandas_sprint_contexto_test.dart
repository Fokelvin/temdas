import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view/widgets/densidade_demanda.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/sprint_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';
import 'support/fake_sprint_repository.dart';

void main() {
  testWidgets('voltar da Sprint completa atualiza vínculos no Board', (
    tester,
  ) async {
    final repository = FakeSprintRepository(
      sprints: [_sprint(1, backend.SprintStatus.ativa)],
      vinculosPorSprint: {
        1: [backend.SprintDemanda(sprintId: 1, demandaId: 1)],
      },
    );
    await _abrir(tester, repository);
    await tester.tap(find.byKey(const ValueKey('sprint-da-demanda-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('abrir-sprint-completa')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desvincular e voltar'));
    await tester.pumpAndSettle();
    expect(find.text('Sem Sprint'), findsNWidgets(4));
    expect(find.text('Sprint: Ciclo 1'), findsNothing);
  });

  testWidgets(
    'fechar resumo durante consulta aguarda liberação e atualiza vínculos do board',
    (tester) async {
      final repository = FakeSprintRepository(
        sprints: [_sprint(1, backend.SprintStatus.ativa)],
        vinculosPorSprint: {
          1: [backend.SprintDemanda(sprintId: 1, demandaId: 1)],
        },
      );
      await _abrir(tester, repository);
      final pending = Completer<List<backend.SprintDemanda>>();
      repository.vinculosPendentes = pending;
      await tester.tap(find.byKey(const ValueKey('sprint-da-demanda-1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Consultando Demandas vinculadas…'), findsOneWidget);
      await tester.tap(find.byTooltip('Fechar Sprint'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const ValueKey('carregando-sprints-demandas')),
        findsOneWidget,
      );
      repository.vinculosPendentes = null;
      pending.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('Sprint: Ciclo 1'), findsOneWidget);
      expect(
        find.byTooltip('Tentar consultar Sprints novamente'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'board usa somente SprintDemanda aberta, preserva compacto e abre resumo',
    (tester) async {
      final repository = FakeSprintRepository(
        sprints: [
          _sprint(1, backend.SprintStatus.ativa),
          _sprint(2, backend.SprintStatus.concluida),
          _sprint(3, backend.SprintStatus.cancelada),
          _sprint(4, backend.SprintStatus.planejada),
        ],
        vinculosPorSprint: {
          for (final id in [1, 2, 3, 4])
            id: [backend.SprintDemanda(sprintId: id, demandaId: id)],
        },
      );
      await _abrir(tester, repository);
      expect(find.text('Sprint: Ciclo 1'), findsOneWidget);
      expect(find.text('Sprint: Ciclo 4'), findsOneWidget);
      expect(find.text('Sem Sprint'), findsNWidgets(2));
      expect(repository.chamadasVinculos, 2);
      expect(
        tester.widget<DemandaCard>(find.byType(DemandaCard).first).densidade,
        DensidadeDemanda.compacta,
      );
      await tester.tap(find.byKey(const ValueKey('sprint-da-demanda-1')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('resumo-sprint-dialog')),
        findsOneWidget,
      );
      expect(find.text('Demandas vinculadas (1)'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('adicionar-demanda-sprint-resumo')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Fechar Sprint'));
      await tester.pumpAndSettle();
      expect(find.text('Sprint: Ciclo 1'), findsOneWidget);
    },
  );

  testWidgets(
    'consultando e falha de Sprint não exibem vínculo falso, permite tentar novamente',
    (tester) async {
      final pending = Completer<List<backend.Sprint>>();
      final repository = FakeSprintRepository(sprints: [])
        ..listaPendente = pending;
      await _abrir(tester, repository, aguardar: false);
      expect(
        find.byKey(const ValueKey('carregando-sprints-demandas')),
        findsOneWidget,
      );
      expect(find.text('Sem Sprint'), findsNothing);
      pending.completeError(StateError('falha interna'));
      repository.listaPendente = null;
      await tester.pumpAndSettle();
      expect(find.text('Sprint indisponível'), findsNWidgets(4));
      expect(find.text('Sem Sprint'), findsNothing);
      await tester.tap(find.byTooltip('Tentar consultar Sprints novamente'));
      await tester.pumpAndSettle();
      expect(find.text('Sem Sprint'), findsNWidgets(4));
      expect(
        find.byKey(const ValueKey('carregando-sprints-demandas')),
        findsNothing,
      );
    },
  );

  testWidgets('Sem Sprint leva à organização de Sprints', (tester) async {
    await _abrir(tester, FakeSprintRepository(sprints: []));
    await tester.tap(find.byKey(const ValueKey('sprint-da-demanda-1')));
    await tester.pumpAndSettle();
    expect(find.text('Organização de Sprints'), findsOneWidget);
  });
}

Future<void> _abrir(
  WidgetTester tester,
  FakeSprintRepository repository, {
  bool aguardar = true,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final vm = SprintViewModel(repository: repository);
  final dvm = DemandasViewModel(
    repository: FakeDemandaRepository(
      demandas: [
        for (var id = 1; id <= 4; id++)
          demandaFixture(id: id, titulo: 'Demanda $id'),
      ],
    ),
  );
  addTearDown(vm.dispose);
  addTearDown(dvm.dispose);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: DemandasPage(viewModel: dvm, sprintViewModel: vm),
      routes: {
        AppRoutes.detalheDaSprint(1): (context) => Scaffold(
          body: TextButton(
            onPressed: () {
              repository.vinculosPorSprint[1]?.clear();
              Navigator.pop(context);
            },
            child: const Text('Desvincular e voltar'),
          ),
        ),
        AppRoutes.sprint: (_) =>
            const Scaffold(body: Text('Organização de Sprints')),
      },
    ),
  );
  if (aguardar) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

backend.Sprint _sprint(int id, backend.SprintStatus status) => backend.Sprint(
  id: id,
  usuarioId: 1,
  nome: 'Ciclo $id',
  status: status,
  dataInicio: DateTime(2026, 1, 1),
  dataFim: DateTime(2026, 1, 7),
  tempoPrevistoMinutos: 60,
);
