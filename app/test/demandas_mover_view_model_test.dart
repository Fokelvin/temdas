import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  test('move uma raiz para outra posição sem mover suas filhas', () async {
    final primeira = demandaFixture(id: 1, titulo: 'Primeira');
    final segunda = demandaFixture(id: 2, titulo: 'Segunda');
    final filha = demandaFixture(id: 3, titulo: 'Filha', demandaPaiId: 2);
    final terceira = demandaFixture(id: 4, titulo: 'Terceira');
    final repository = FakeDemandaRepository(
      demandas: [primeira, segunda, filha, terceira],
    );
    final viewModel = DemandasViewModel(repository: repository);
    addTearDown(viewModel.dispose);
    await viewModel.carregarDemandas();

    final resposta = Completer<backend.Demanda>();
    repository.respostaMoverPendente = resposta;
    final movimento = viewModel.moverDemanda(
      demanda: segunda,
      statusDestino: backend.DemandaStatus.aberta,
      posicaoDestino: 0,
    );

    expect(repository.ultimaMovimentacao?.demandaId, 2);
    expect(
      repository.ultimaMovimentacao?.statusDestino,
      backend.DemandaStatus.aberta,
    );
    expect(repository.ultimaMovimentacao?.posicaoDestino, 0);

    resposta.complete(segunda.copyWith(ordem: 0));
    expect(await movimento, isTrue);
    expect(viewModel.demandas.map((demanda) => demanda.id), [2, 1, 4, 3]);
    expect(viewModel.demandas.last.demandaPaiId, 2);
  });

  test(
    'move uma raiz entre colunas ativas e atualiza o estado local',
    () async {
      final demanda = demandaFixture(id: 1, titulo: 'A');
      final outra = demandaFixture(id: 2, titulo: 'B');
      final repository = FakeDemandaRepository(demandas: [demanda, outra]);
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.carregarDemandas();

      final resposta = Completer<backend.Demanda>();
      repository.respostaMoverPendente = resposta;
      final movimento = viewModel.moverDemanda(
        demanda: demanda,
        statusDestino: backend.DemandaStatus.emAndamento,
        posicaoDestino: 0,
      );
      resposta.complete(
        demanda.copyWith(status: backend.DemandaStatus.emAndamento, ordem: 0),
      );

      expect(await movimento, isTrue);
      expect(repository.ultimaMovimentacao?.demandaId, 1);
      expect(
        repository.ultimaMovimentacao?.statusDestino,
        backend.DemandaStatus.emAndamento,
      );
      expect(viewModel.demandas.map((item) => item.id), [2, 1]);
      expect(viewModel.demandas[1].status, backend.DemandaStatus.emAndamento);
    },
  );

  test(
    'recusa movimentação para status terminal sem alterar a demanda',
    () async {
      final demanda = demandaFixture(id: 1, titulo: 'A');
      final repository = FakeDemandaRepository(demandas: [demanda]);
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.carregarDemandas();

      final resposta = Completer<backend.Demanda>();
      repository.respostaMoverPendente = resposta;
      final movimento = viewModel.moverDemanda(
        demanda: demanda,
        statusDestino: backend.DemandaStatus.concluida,
        posicaoDestino: 0,
      );
      final erro = backend.MovimentacaoDemandaException(
        codigo: backend.MovimentacaoDemandaErroCodigo.statusTerminal,
        mensagem: 'Status terminal.',
      );
      resposta.completeError(erro);

      expect(await movimento, isFalse);
      expect(viewModel.demandas.single.status, backend.DemandaStatus.aberta);
      expect(viewModel.erroMovimentacao, same(erro));
      expect(viewModel.enviando, isFalse);
    },
  );
}
