import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  group('DemandasViewModel', () {
    test(
      'encaminha motivo e sincroniza descendentes após cancelamento no backend',
      () async {
        final mae = demandaFixture();
        final filha = demandaFixture(id: 2, demandaPaiId: 1);
        final cancelada = mae.copyWith(
          status: backend.DemandaStatus.cancelada,
          motivoCancelamento: 'Mudança de planos',
        );
        final filhaCancelada = filha.copyWith(
          status: backend.DemandaStatus.cancelada,
          motivoCancelamento: 'Mudança de planos',
        );
        final repository = FakeDemandaRepository(demandas: [mae, filha]);
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.carregarDemandas();
        repository.respostaAtualizarPendente = Completer<backend.Demanda>()
          ..complete(cancelada);
        repository.respostasListarPendentes.add(
          Completer<List<backend.Demanda>>()
            ..complete([cancelada, filhaCancelada]),
        );
        expect(
          await viewModel.atualizarDemanda(
            demanda: mae,
            titulo: mae.titulo,
            tempoEstimadoHoras: 1,
            status: backend.DemandaStatus.cancelada,
            motivoCancelamento: 'Mudança de planos',
            prioridade: mae.prioridade,
          ),
          isTrue,
        );
        expect(
          repository.ultimaAtualizacao?.motivoCancelamento,
          'Mudança de planos',
        );
        expect(repository.chamadasListar, 2);
        expect(viewModel.demandas, [cancelada, filhaCancelada]);
      },
    );

    test(
      'preserva dados e apresenta a recusa de transição recebida do backend',
      () async {
        final mae = demandaFixture();
        final repository = FakeDemandaRepository(demandas: [mae]);
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.carregarDemandas();
        final resposta = Completer<backend.Demanda>();
        repository.respostaAtualizarPendente = resposta;
        final atualizacao = viewModel.atualizarDemanda(
          demanda: mae,
          titulo: mae.titulo,
          tempoEstimadoHoras: 1,
          status: backend.DemandaStatus.concluida,
          prioridade: mae.prioridade,
        );
        final erro = backend.TransicaoStatusException(
          codigo: backend.TransicaoStatusErroCodigo.descendentesAtivos,
          mensagem: 'A demanda possui descendentes ativos.',
          podeConcluirEmCascata: true,
        );
        resposta.completeError(erro);
        expect(await atualizacao, isFalse);
        expect(viewModel.demandas, [mae]);
        expect(viewModel.erro, 'A demanda possui descendentes ativos.');
        expect(viewModel.erroTransicaoStatus, same(erro));
        expect(
          viewModel.erroTransicaoStatus?.codigo,
          backend.TransicaoStatusErroCodigo.descendentesAtivos,
        );
        expect(viewModel.erroTransicaoStatus?.podeConcluirEmCascata, isTrue);
        expect(viewModel.enviando, isFalse);
      },
    );

    test(
      'substitui somente a demanda atualizada, preservando ordem e campos',
      () async {
        final mae = demandaFixture(id: 2, titulo: 'Mãe');
        final original = demandaFixture(demandaPaiId: mae.id);
        final repository = FakeDemandaRepository(demandas: [original, mae]);
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
        expect(repository.chamadasListar, 1);
        expect(repository.ultimaAtualizacao?.tempoEstimadoMinutos, 90);
        expect(repository.ultimaAtualizacao?.sprint, original.sprint);
        expect(repository.ultimaAtualizacao?.observacoes, original.observacoes);
        expect(viewModel.demandas.map((item) => item.id), [1, 2]);
        expect(viewModel.demandas.last, same(mae));
        expect(viewModel.demandas.first.titulo, 'Demanda atualizada');
        expect(
          viewModel.demandas.first.status,
          backend.DemandaStatus.concluida,
        );
        expect(viewModel.demandas.first.tempoExecutadoMinutos, 30);
        expect(viewModel.demandas.first.criadoEm, original.criadoEm);
        expect(viewModel.filhasDe(mae).single, same(viewModel.demandas.first));
        expect(viewModel.demandasRaiz, [mae]);
        expect(viewModel.carregando, isFalse);
      },
    );

    test('adiciona a filha retornada na árvore local com mãe fixa', () async {
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
      expect(repository.chamadasListar, 1);
      expect(viewModel.filhasDe(mae).single.titulo, 'Filha');
      expect(viewModel.filhasDe(mae).single, same(viewModel.demandaCriada));
      expect(viewModel.demandas.map((item) => item.id), [2, 1]);
      expect(viewModel.demandasRaiz, hasLength(1));
    });

    test(
      'insere a demanda retornada em ordem sem depender de refresh',
      () async {
        final antiga = demandaFixture();
        final maisRecente = demandaFixture(
          id: 2,
        ).copyWith(criadoEm: DateTime.utc(2026, 9, 10));
        final repository = FakeDemandaRepository(
          demandas: [maisRecente, antiga],
        );
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
        expect(repository.chamadasListar, 1);
        expect(viewModel.demandaCriada?.titulo, 'Criada no backend');
        expect(viewModel.demandas.map((item) => item.id), [2, 3, 1]);
        expect(viewModel.demandas[1], same(viewModel.demandaCriada));
        expect(viewModel.demandas.first, same(maisRecente));
        expect(viewModel.demandas.last, same(antiga));
        expect(viewModel.erro, isNull);
        expect(viewModel.carregando, isFalse);
      },
    );

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

    for (final operacao in [
      'criar',
      'atualizar',
      'excluir',
      'excluir árvore',
    ]) {
      for (final resultado in [
        'sucesso',
        'erro',
        if (operacao.startsWith('excluir')) 'não encontrada',
      ]) {
        test(
          '$operacao aguarda confirmação, bloqueia duplicação e trata $resultado',
          () async {
            final mae = demandaFixture(id: 1, titulo: 'Mãe');
            final filha = demandaFixture(id: 2, demandaPaiId: 1);
            final neta = demandaFixture(id: 3, demandaPaiId: 2);
            final independente = demandaFixture(id: 4, titulo: 'Independente');
            final originais = [mae, filha, neta, independente];
            final repository = FakeDemandaRepository(demandas: originais);
            final respostaDemanda = Completer<backend.Demanda>();
            final respostaExclusao = Completer<bool>();
            switch (operacao) {
              case 'criar':
                repository.respostaCriarPendente = respostaDemanda;
              case 'atualizar':
                repository.respostaAtualizarPendente = respostaDemanda;
              case 'excluir':
                repository.respostaExcluirPendente = respostaExclusao;
              case 'excluir árvore':
                repository.respostaExcluirArvorePendente = respostaExclusao;
            }
            final viewModel = DemandasViewModel(repository: repository);
            addTearDown(viewModel.dispose);
            await viewModel.carregarDemandas();
            final estadosEnvio = <bool>[];
            viewModel.addListener(() => estadosEnvio.add(viewModel.enviando));
            final alvo = operacao == 'excluir' ? neta : mae;

            final mutacao = _executarMutacao(viewModel, operacao, alvo);
            expect(viewModel.enviando, isTrue);
            expect(viewModel.carregando, isFalse);
            expect(viewModel.demandas, originais);
            expect(viewModel.demandaCriada, isNull);
            expect(await _executarMutacao(viewModel, operacao, alvo), isFalse);
            expect(
              repository.chamadasCriar +
                  repository.chamadasAtualizar +
                  repository.chamadasExcluir +
                  repository.chamadasExcluirArvore,
              1,
            );

            final retornada = mae.copyWith(
              id: operacao == 'criar' ? 5 : mae.id,
              titulo: 'Título confirmado pelo backend',
            );
            if (resultado == 'erro') {
              if (operacao.startsWith('excluir')) {
                respostaExclusao.completeError(StateError('Falha da mutação'));
              } else {
                respostaDemanda.completeError(StateError('Falha da mutação'));
              }
            } else if (operacao.startsWith('excluir')) {
              respostaExclusao.complete(resultado == 'sucesso');
            } else {
              respostaDemanda.complete(retornada);
            }

            expect(await mutacao, resultado == 'sucesso');
            expect(viewModel.enviando, isFalse);
            expect(viewModel.carregando, isFalse);
            expect(estadosEnvio, [true, false]);
            expect(repository.chamadasListar, 1);
            if (resultado != 'sucesso') {
              expect(viewModel.demandas, originais);
              expect(viewModel.demandaCriada, isNull);
              expect(viewModel.erro, isNotNull);
            } else {
              expect(viewModel.erro, isNull);
              switch (operacao) {
                case 'criar':
                  expect(viewModel.demandas, [...originais, retornada]);
                  expect(viewModel.demandaCriada, same(retornada));
                case 'atualizar':
                  expect(viewModel.demandas, [
                    retornada,
                    filha,
                    neta,
                    independente,
                  ]);
                  expect(viewModel.demandas.first, same(retornada));
                case 'excluir':
                  expect(viewModel.demandas, [mae, filha, independente]);
                case 'excluir árvore':
                  expect(viewModel.demandas, [independente]);
                  expect(viewModel.demandasRaiz, [independente]);
              }
            }
          },
        );
      }
    }

    test(
      'uma carga pendente não desfaz a atualização local confirmada',
      () async {
        final original = demandaFixture();
        final repository = FakeDemandaRepository(demandas: [original]);
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.carregarDemandas();
        final respostaAntiga = Completer<List<backend.Demanda>>();
        repository.respostasListarPendentes.add(respostaAntiga);
        final refresh = viewModel.carregarDemandas();

        expect(
          await _executarMutacao(viewModel, 'atualizar', original),
          isTrue,
        );
        respostaAntiga.complete([original]);
        await refresh;

        expect(viewModel.demandas.single.titulo, 'Título enviado');
        expect(viewModel.carregando, isFalse);
        expect(repository.chamadasListar, 2);
      },
    );

    test(
      'mantém demandaCriada atualizada e a limpa ao excluir sua árvore',
      () async {
        final mae = demandaFixture();
        final repository = FakeDemandaRepository(demandas: [mae]);
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.carregarDemandas();
        await viewModel.criarDemanda(
          titulo: 'Filha',
          tempoEstimadoHoras: 1,
          demandaPaiId: mae.id,
        );
        final filha = viewModel.demandaCriada!;

        await _executarMutacao(viewModel, 'atualizar', filha);
        expect(viewModel.demandaCriada, same(viewModel.filhasDe(mae).single));
        expect(viewModel.demandaCriada!.titulo, 'Título enviado');
        await viewModel.excluirArvoreDemanda(mae);

        expect(viewModel.demandaCriada, isNull);
        expect(viewModel.demandas, isEmpty);
        expect(repository.chamadasListar, 1);
      },
    );

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

    test('remove somente a folha confirmada pelo endpoint simples', () async {
      final mae = demandaFixture(id: 2, titulo: 'Mãe');
      final original = demandaFixture(demandaPaiId: 2);
      final irma = demandaFixture(id: 3, demandaPaiId: 2);
      final repository = FakeDemandaRepository(demandas: [original, irma, mae]);
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);

      await viewModel.carregarDemandas();
      final excluida = await viewModel.excluirDemanda(original);

      expect(excluida, isTrue);
      expect(repository.chamadasExcluir, 1);
      expect(repository.chamadasExcluirArvore, 0);
      expect(repository.ultimoIdExcluido, original.id);
      expect(repository.chamadasListar, 1);
      expect(viewModel.demandas, [irma, mae]);
      expect(viewModel.filhasDe(mae), [irma]);
    });

    test(
      'exclui mãe e todos os descendentes pelo endpoint de árvore',
      () async {
        final mae = demandaFixture(id: 1, titulo: 'Mãe');
        final filha = demandaFixture(id: 2, demandaPaiId: 1, titulo: 'Filha');
        final neta = demandaFixture(id: 3, demandaPaiId: 2, titulo: 'Neta');
        final independente = demandaFixture(id: 4, titulo: 'Independente');
        final bisneta = demandaFixture(
          id: 5,
          demandaPaiId: 3,
          titulo: 'Bisneta',
        );
        final repository = FakeDemandaRepository(
          demandas: [mae, filha, neta, bisneta, independente],
        );
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        await viewModel.carregarDemandas();
        final excluida = await viewModel.excluirArvoreDemanda(mae);

        expect(excluida, isTrue);
        expect(repository.chamadasExcluir, 0);
        expect(repository.chamadasExcluirArvore, 1);
        expect(repository.ultimoIdArvoreExcluida, mae.id);
        expect(repository.chamadasListar, 1);
        expect(viewModel.demandas, hasLength(1));
        expect(viewModel.demandas.single.id, independente.id);
        expect(viewModel.demandasRaiz, [independente]);
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

Future<bool> _executarMutacao(
  DemandasViewModel viewModel,
  String operacao,
  backend.Demanda demanda,
) => switch (operacao) {
  'criar' => viewModel.criarDemanda(
    titulo: 'Título enviado',
    tempoEstimadoHoras: 1,
  ),
  'atualizar' => viewModel.atualizarDemanda(
    demanda: demanda,
    titulo: 'Título enviado',
    tempoEstimadoHoras: 1,
    status: demanda.status,
    prioridade: demanda.prioridade,
  ),
  'excluir' => viewModel.excluirDemanda(demanda),
  'excluir árvore' => viewModel.excluirArvoreDemanda(demanda),
  _ => throw ArgumentError.value(operacao),
};
