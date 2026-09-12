import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  group('DemandasViewModel', () {
    test(
      'atualiza, preserva campos ocultos, converte horas e recarrega a lista',
      () async {
        final original = demandaFixture();
        final repository = FakeDemandaRepository(demandas: [original]);
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        await viewModel.carregarDemandas();
        final atualizada = await viewModel.atualizarDemanda(
          demanda: original,
          titulo: 'Demanda atualizada',
          descricao: 'Descrição atualizada',
          tempoEstimadoHoras: 1.5,
          status: backend.DemandaStatus.concluida,
          prioridade: backend.Prioridade.alta,
        );

        expect(atualizada, isTrue);
        expect(repository.chamadasAtualizar, 1);
        expect(repository.chamadasListar, 2);
        expect(repository.ultimaAtualizacao?.tempoEstimadoMinutos, 90);
        expect(repository.ultimaAtualizacao?.sprint, original.sprint);
        expect(repository.ultimaAtualizacao?.observacoes, original.observacoes);
        expect(viewModel.demandas.single.titulo, 'Demanda atualizada');
        expect(
          viewModel.demandas.single.status,
          backend.DemandaStatus.concluida,
        );
        expect(viewModel.demandas.single.tempoExecutadoMinutos, 30);
        expect(viewModel.demandas.single.criadoEm, original.criadoEm);
      },
    );

    test('cria demanda filha com mãe fixa e recarrega a árvore', () async {
      final mae = demandaFixture();
      final repository = FakeDemandaRepository(demandas: [mae]);
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.carregarDemandas();
      final criada = await viewModel.criarDemanda(
        titulo: 'Filha',
        descricao: 'Trabalho menor',
        tempoEstimadoHoras: 0.5,
        prioridade: backend.Prioridade.alta,
        demandaPaiId: mae.id,
      );

      expect(criada, isTrue);
      expect(repository.chamadasCriar, 1);
      expect(repository.ultimaCriacao?.demandaPaiId, mae.id);
      expect(repository.ultimaCriacao?.tempoEstimadoMinutos, 30);
      expect(repository.chamadasListar, 2);
      expect(viewModel.filhasDe(mae).single.titulo, 'Filha');
      expect(viewModel.demandasRaiz, hasLength(1));
    });

    test('mantém sucesso da criação quando apenas o refresh falha', () async {
      final repository = FakeDemandaRepository();
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.carregarDemandas();
      repository.erroAoListar = StateError('Falha no refresh');

      final criada = await viewModel.criarDemanda(
        titulo: 'Criada no backend',
        tempoEstimadoHoras: 1,
      );

      expect(criada, isTrue);
      expect(repository.chamadasCriar, 1);
      expect(repository.chamadasListar, 2);
      expect(viewModel.demandaCriada?.titulo, 'Criada no backend');
      expect(
        viewModel.erro,
        'A alteração foi salva, mas não foi possível atualizar a lista. '
        'Recarregue as demandas.',
      );
    });

    test('mantém apenas a resposta da carga mais recente', () async {
      final repository = FakeDemandaRepository();
      final respostaAntiga = Completer<List<backend.Demanda>>();
      final respostaRecente = Completer<List<backend.Demanda>>();
      repository.respostasListarPendentes
        ..add(respostaAntiga)
        ..add(respostaRecente);
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      final cargaAntiga = viewModel.carregarDemandas();
      final cargaRecente = viewModel.carregarDemandas();
      respostaRecente.complete([
        demandaFixture(id: 2, titulo: 'Resposta recente'),
      ]);
      await cargaRecente;
      respostaAntiga.complete([
        demandaFixture(id: 1, titulo: 'Resposta antiga'),
      ]);
      await cargaAntiga;

      expect(viewModel.demandas.single.titulo, 'Resposta recente');
      expect(viewModel.carregando, isFalse);
    });

    test('ignora conclusão de carga depois do dispose', () async {
      final repository = FakeDemandaRepository();
      final resposta = Completer<List<backend.Demanda>>();
      repository.respostasListarPendentes.add(resposta);
      final viewModel = DemandasViewModel(repository: repository);
      var notificacoes = 0;
      viewModel.addListener(() => notificacoes++);

      final carga = viewModel.carregarDemandas();
      expect(notificacoes, 1);
      viewModel.dispose();
      resposta.complete([demandaFixture()]);

      await expectLater(carga, completes);
      expect(notificacoes, 1);
    });

    test('encontra descendentes em qualquer profundidade', () async {
      final mae = demandaFixture(id: 1, titulo: 'Mãe');
      final filha = demandaFixture(id: 2, demandaPaiId: 1, titulo: 'Filha');
      final neta = demandaFixture(id: 3, demandaPaiId: 2, titulo: 'Neta');
      final bisneta = demandaFixture(id: 4, demandaPaiId: 3, titulo: 'Bisneta');
      final repository = FakeDemandaRepository(
        demandas: [bisneta, neta, filha, mae],
      );
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.carregarDemandas();

      expect(viewModel.possuiDescendentes(mae), isTrue);
      expect(
        viewModel.descendentesDe(mae).map((demanda) => demanda.id),
        containsAll(<int>[2, 3, 4]),
      );
      expect(viewModel.descendentesDe(mae), hasLength(3));
      expect(viewModel.possuiDescendentes(bisneta), isFalse);
    });

    test(
      'exclui uma folha pelo endpoint simples e recarrega a lista',
      () async {
        final original = demandaFixture();
        final repository = FakeDemandaRepository(demandas: [original]);
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        await viewModel.carregarDemandas();
        final excluida = await viewModel.excluirDemanda(original);

        expect(excluida, isTrue);
        expect(repository.chamadasExcluir, 1);
        expect(repository.chamadasExcluirArvore, 0);
        expect(repository.ultimoIdExcluido, original.id);
        expect(repository.chamadasListar, 2);
        expect(viewModel.demandas, isEmpty);
      },
    );

    test(
      'exclui mãe e todos os descendentes pelo endpoint de árvore',
      () async {
        final mae = demandaFixture(id: 1, titulo: 'Mãe');
        final filha = demandaFixture(id: 2, demandaPaiId: 1, titulo: 'Filha');
        final neta = demandaFixture(id: 3, demandaPaiId: 2, titulo: 'Neta');
        final independente = demandaFixture(id: 4, titulo: 'Independente');
        final repository = FakeDemandaRepository(
          demandas: [mae, filha, neta, independente],
        );
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        await viewModel.carregarDemandas();
        final excluida = await viewModel.excluirArvoreDemanda(mae);

        expect(excluida, isTrue);
        expect(repository.chamadasExcluir, 0);
        expect(repository.chamadasExcluirArvore, 1);
        expect(repository.ultimoIdArvoreExcluida, mae.id);
        expect(viewModel.demandas, hasLength(1));
        expect(viewModel.demandas.single.id, independente.id);
      },
    );

    test('informa quando o backend não exclui a demanda', () async {
      final original = demandaFixture();
      final repository = FakeDemandaRepository(demandas: [original])
        ..resultadoExclusao = false;
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.carregarDemandas();
      final excluida = await viewModel.excluirDemanda(original);

      expect(excluida, isFalse);
      expect(
        viewModel.erro,
        'A demanda não foi encontrada ou já foi excluída.',
      );
      expect(repository.chamadasListar, 1);
      expect(viewModel.demandas, hasLength(1));
    });

    test('registra tempo em UTC e recarrega o total executado', () async {
      final original = demandaFixture(tempoExecutadoMinutos: 0);
      final repository = FakeDemandaRepository(demandas: [original]);
      final registroRepository = FakeRegistroTempoRepository(
        demandaRepository: repository,
      );
      final viewModel = DemandasViewModel(
        repository: repository,
        registroTempoRepository: registroRepository,
      );
      addTearDown(viewModel.dispose);

      await viewModel.carregarDemandas();
      final inicioLocal = DateTime(2026, 9, 9, 10, 15);
      final registrado = await viewModel.registrarTempo(
        demanda: original,
        inicioEm: inicioLocal,
        duracaoMinutos: 75,
      );

      expect(registrado, isTrue);
      expect(registroRepository.chamadasRegistrar, 1);
      expect(registroRepository.ultimaDemandaId, original.id);
      expect(registroRepository.ultimoInicioEm, inicioLocal.toUtc());
      expect(registroRepository.ultimaDuracaoMinutos, 75);
      expect(repository.chamadasListar, 2);
      expect(viewModel.demandas.single.tempoExecutadoMinutos, 75);
    });

    test('não envia operações para demanda sem ID', () async {
      final original = demandaFixture(id: null);
      final repository = FakeDemandaRepository(demandas: [original]);
      final registroRepository = FakeRegistroTempoRepository();
      final viewModel = DemandasViewModel(
        repository: repository,
        registroTempoRepository: registroRepository,
      );
      addTearDown(viewModel.dispose);

      final atualizada = await viewModel.atualizarDemanda(
        demanda: original,
        titulo: original.titulo,
        tempoEstimadoHoras: 1,
        status: original.status,
        prioridade: original.prioridade,
      );
      final excluida = await viewModel.excluirDemanda(original);
      final arvoreExcluida = await viewModel.excluirArvoreDemanda(original);
      final tempoRegistrado = await viewModel.registrarTempo(
        demanda: original,
        inicioEm: DateTime.now(),
        duracaoMinutos: 30,
      );

      expect(atualizada, isFalse);
      expect(excluida, isFalse);
      expect(arvoreExcluida, isFalse);
      expect(tempoRegistrado, isFalse);
      expect(repository.chamadasAtualizar, 0);
      expect(repository.chamadasExcluir, 0);
      expect(repository.chamadasExcluirArvore, 0);
      expect(registroRepository.chamadasRegistrar, 0);
      expect(viewModel.erro, 'A demanda não possui um ID válido.');
    });
  });
}
