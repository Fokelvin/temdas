import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view/widgets/demanda_card.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  testWidgets('busca exata por ID revela a hierarquia e destaca o card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(520, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final demandas = [
      demandaFixture(
        id: 10,
        titulo: 'Projeto pai',
        status: backend.DemandaStatus.concluida,
      ),
      demandaFixture(
        id: 42,
        demandaPaiId: 10,
        titulo: 'Ajustar autenticação',
        status: backend.DemandaStatus.concluida,
      ),
      for (var id = 100; id < 120; id++) demandaFixture(id: id),
    ];
    final vm = DemandasViewModel(
      repository: FakeDemandaRepository(demandas: demandas),
    );
    addTearDown(vm.dispose);
    await _abrirPagina(tester, vm);

    await tester.enterText(find.byKey(const ValueKey('buscar-demandas')), '42');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byKey(const ValueKey('demanda-card-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('demanda-card-42')), findsOneWidget);
    expect(
      tester
          .widget<DemandaCard>(
            find.byKey(const PageStorageKey('demanda-expansao-42')),
          )
          .destacado,
      isTrue,
    );
    expect(
      tester
          .widget<DemandaCard>(
            find.byKey(const PageStorageKey('demanda-expansao-10')),
          )
          .destacado,
      isFalse,
    );
    final quadro = tester.widget<SingleChildScrollView>(
      find.byKey(const ValueKey('demandas-quadro-status')),
    );
    expect(quadro.controller!.offset, greaterThan(0));

    await tester.pump(const Duration(milliseconds: 1800));
    expect(
      tester
          .widget<DemandaCard>(
            find.byKey(const PageStorageKey('demanda-expansao-42')),
          )
          .destacado,
      isFalse,
    );
  });

  testWidgets('busca com múltiplos resultados não escolhe um card', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final vm = DemandasViewModel(
      repository: FakeDemandaRepository(
        demandas: [
          demandaFixture(id: 1, titulo: 'Revisar relatório'),
          demandaFixture(id: 2, titulo: 'Publicar relatório'),
        ],
      ),
    );
    addTearDown(vm.dispose);
    await _abrirPagina(tester, vm);

    await tester.enterText(
      find.byKey(const ValueKey('buscar-demandas')),
      'relatório',
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(DemandaCard), findsNWidgets(2));
    for (final id in [1, 2]) {
      expect(
        tester
            .widget<DemandaCard>(
              find.byKey(PageStorageKey('demanda-expansao-$id')),
            )
            .destacado,
        isFalse,
      );
    }
  });

  testWidgets('limpar busca remove destaque pendente e restaura o quadro', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(520, 620));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final demandas = [
      demandaFixture(id: 1, titulo: 'Primeira'),
      demandaFixture(id: 2, titulo: 'Segunda'),
    ];
    final vm = DemandasViewModel(
      repository: FakeDemandaRepository(demandas: demandas),
    );
    addTearDown(vm.dispose);
    await _abrirPagina(tester, vm);

    await tester.enterText(find.byKey(const ValueKey('buscar-demandas')), '1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<DemandaCard>(
            find.byKey(const PageStorageKey('demanda-expansao-1')),
          )
          .destacado,
      isTrue,
    );

    await tester.tap(find.byKey(const ValueKey('limpar-filtros-demandas')));
    await tester.pump();
    expect(find.byType(DemandaCard), findsNWidgets(2));
    expect(
      tester
          .widget<DemandaCard>(
            find.byKey(const PageStorageKey('demanda-expansao-1')),
          )
          .destacado,
      isFalse,
    );
  });
}

Future<void> _abrirPagina(
  WidgetTester tester,
  DemandasViewModel viewModel,
) async {
  await tester.pumpWidget(
    MaterialApp(home: DemandasPage(viewModel: viewModel)),
  );
  await tester.pumpAndSettle();
}
