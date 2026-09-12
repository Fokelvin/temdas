import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/demanda_detalhe_page.dart';
import 'package:temdas/view_model/demanda_detalhe_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  test(
    'carrega mãe, filhas e histórico da demanda em ordem cronológica',
    () async {
      final mae = demandaFixture(id: 1, titulo: 'Demanda mãe');
      final demanda = demandaFixture(
        id: 2,
        demandaPaiId: 1,
        titulo: 'Demanda detalhada',
        tempoEstimadoMinutos: 60,
        tempoExecutadoMinutos: 90,
      );
      final filha = demandaFixture(
        id: 3,
        demandaPaiId: 2,
        titulo: 'Demanda filha',
      );
      final registroMaisNovo = _registro(
        id: 2,
        demandaId: 2,
        inicioEm: DateTime.utc(2026, 9, 9, 15),
        duracaoMinutos: 60,
      );
      final registroMaisAntigo = _registro(
        id: 1,
        demandaId: 2,
        inicioEm: DateTime.utc(2026, 9, 9, 9),
        duracaoMinutos: 30,
      );
      final viewModel = DemandaDetalheViewModel(
        demandaRepository: FakeDemandaRepository(
          demandas: [filha, demanda, mae],
        ),
        registroTempoRepository: FakeRegistroTempoRepository(
          registros: [registroMaisNovo, registroMaisAntigo],
        ),
      );
      addTearDown(viewModel.dispose);

      await viewModel.carregar(2);

      expect(viewModel.erro, isNull);
      expect(viewModel.demanda?.id, 2);
      expect(viewModel.demandaMae?.id, 1);
      expect(viewModel.filhas.map((item) => item.id), [3]);
      expect(viewModel.registros.map((item) => item.id), [1, 2]);
      expect(viewModel.tempoExecutadoMinutos, 90);
    },
  );

  testWidgets('mostra dados completos e comparação estimado x executado', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final mae = demandaFixture(id: 1, titulo: 'Demanda mãe');
    final demanda = demandaFixture(
      id: 2,
      demandaPaiId: 1,
      titulo: 'Demanda detalhada',
      tempoEstimadoMinutos: 60,
      tempoExecutadoMinutos: 90,
    );
    final filha = demandaFixture(
      id: 3,
      demandaPaiId: 2,
      titulo: 'Demanda filha',
    );
    final viewModel = DemandaDetalheViewModel(
      demandaRepository: FakeDemandaRepository(demandas: [mae, demanda, filha]),
      registroTempoRepository: FakeRegistroTempoRepository(
        registros: [
          _registro(
            id: 1,
            demandaId: 2,
            inicioEm: DateTime.utc(2026, 9, 9, 9),
            duracaoMinutos: 90,
          ),
        ],
      ),
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(home: DemandaDetalhePage(demandaId: 2, viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Demanda detalhada'), findsOneWidget);
    expect(find.text('Estimado: 1 h'), findsOneWidget);
    expect(find.text('Executado: 1 h 30 min'), findsOneWidget);
    expect(find.text('Excedido em 30 min'), findsOneWidget);
    expect(find.text('Demanda mãe'), findsNWidgets(2));
    expect(find.text('Demandas filhas (1)'), findsOneWidget);
    expect(find.text('Demanda filha'), findsOneWidget);
    expect(find.text('Histórico de tempo (1)'), findsOneWidget);
  });
}

backend.RegistroTempo _registro({
  required int id,
  required int demandaId,
  required DateTime inicioEm,
  required int duracaoMinutos,
}) => backend.RegistroTempo(
  id: id,
  demandaId: demandaId,
  inicioEm: inicioEm,
  duracaoMinutos: duracaoMinutos,
  criadoEm: DateTime.utc(2026, 9, 9, 18),
);
