import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

const _motivo = '  Mudança de planos  ';

void main() {
  group('DemandasViewModel: operações de status', () {
    for (final operacao in [
      'alterar',
      'concluir',
      'concluir em cascata',
      'cancelar em cascata',
    ]) {
      for (final resultado in ['sucesso', 'erro tipado', 'erro genérico']) {
        test('$operacao encaminha a operação e trata $resultado', () async {
          final mae = demandaFixture();
          final filha = demandaFixture(id: 2, demandaPaiId: mae.id);
          final terminal = demandaFixture(
            id: 3,
            demandaPaiId: mae.id,
            status: backend.DemandaStatus.concluida,
          );
          final originais = [mae, filha, terminal];
          final repository = FakeDemandaRepository(demandas: originais);
          final resposta = Completer<backend.Demanda>();
          _configurarResposta(repository, operacao, resposta);
          final viewModel = DemandasViewModel(repository: repository);
          addTearDown(viewModel.dispose);
          await viewModel.carregarDemandas();
          final estados = <bool>[];
          viewModel.addListener(() => estados.add(viewModel.enviando));

          final mutacao = _executar(viewModel, operacao, mae);
          expect(viewModel.enviando, isTrue);
          expect(viewModel.demandas, originais);
          expect(await _executar(viewModel, operacao, mae), isFalse);
          _verificarChamada(repository, operacao, mae.id!);
          expect(repository.chamadasAtualizar, 0);
          expect(repository.chamadasListar, 1);

          final status = switch (operacao) {
            'alterar' => backend.DemandaStatus.emAndamento,
            'cancelar em cascata' => backend.DemandaStatus.cancelada,
            _ => backend.DemandaStatus.concluida,
          };
          final retornada = mae.copyWith(
            titulo: 'Título retornado pelo backend',
            status: status,
            motivoCancelamento: operacao == 'cancelar em cascata'
                ? 'Mudança de planos'
                : null,
          );
          final filhaRetornada = operacao.endsWith('em cascata')
              ? filha.copyWith(status: status)
              : filha;
          final erro = backend.TransicaoStatusException(
            codigo: operacao == 'cancelar em cascata'
                ? backend
                      .TransicaoStatusErroCodigo
                      .motivoCancelamentoObrigatorio
                : backend.TransicaoStatusErroCodigo.descendentesAtivos,
            mensagem: 'Recusa recebida do backend',
            podeConcluirEmCascata: operacao != 'cancelar em cascata',
          );

          switch (resultado) {
            case 'sucesso':
              if (operacao.endsWith('em cascata')) {
                repository.respostasListarPendentes.add(
                  Completer<List<backend.Demanda>>()
                    ..complete([retornada, filhaRetornada, terminal]),
                );
              }
              resposta.complete(retornada);
            case 'erro tipado':
              resposta.completeError(erro);
            default:
              resposta.completeError(StateError('Falha na conexão'));
          }

          expect(await mutacao, resultado == 'sucesso');
          expect(viewModel.enviando, isFalse);
          expect(viewModel.carregando, isFalse);
          expect(estados.first, isTrue);
          expect(estados.last, isFalse);
          if (resultado == 'sucesso') {
            expect(
              repository.chamadasListar,
              operacao.endsWith('em cascata') ? 2 : 1,
            );
            expect(viewModel.demandas, [retornada, filhaRetornada, terminal]);
            expect(viewModel.demandas.first, same(retornada));
            expect(viewModel.erro, isNull);
            expect(viewModel.erroTransicaoStatus, isNull);
            // O fake aplica só a resposta configurada, sem inferir cascatas.
            expect(await repository.buscarDemandaPorId(filha.id!), same(filha));
          } else {
            expect(repository.chamadasListar, 1);
            expect(viewModel.demandas, originais);
            expect(await repository.buscarDemandaPorId(mae.id!), same(mae));
            if (resultado == 'erro tipado') {
              expect(viewModel.erro, erro.mensagem);
              expect(viewModel.erroTransicaoStatus, same(erro));
              expect(viewModel.erroTransicaoStatus?.codigo, erro.codigo);
              expect(
                viewModel.erroTransicaoStatus?.podeConcluirEmCascata,
                erro.podeConcluirEmCascata,
              );
            } else {
              expect(
                viewModel.erro,
                'Não foi possível alterar o status da demanda. Tente novamente.',
              );
              expect(viewModel.erroTransicaoStatus, isNull);
            }
          }
        });
      }

      test('$operacao não envia demanda sem ID', () async {
        final repository = FakeDemandaRepository();
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);

        expect(
          await _executar(viewModel, operacao, demandaFixture(id: null)),
          isFalse,
        );
        expect(viewModel.erro, 'A demanda não possui um ID válido.');
        expect(viewModel.erroTransicaoStatus, isNull);
        expect(repository.chamadasAlterarStatus, 0);
        expect(repository.chamadasConcluirEmCascata, 0);
        expect(repository.chamadasCancelarEmCascata, 0);
        expect(repository.chamadasListar, 0);
      });

      test(
        '$operacao ignora resposta e novas operações após dispose',
        () async {
          final mae = demandaFixture();
          final repository = FakeDemandaRepository(demandas: [mae]);
          final resposta = Completer<backend.Demanda>();
          _configurarResposta(repository, operacao, resposta);
          final viewModel = DemandasViewModel(repository: repository);
          await viewModel.carregarDemandas();
          var notificacoes = 0;
          viewModel.addListener(() => notificacoes++);

          final mutacao = _executar(viewModel, operacao, mae);
          viewModel.dispose();
          resposta.complete(
            mae.copyWith(status: backend.DemandaStatus.concluida),
          );

          expect(await mutacao, isTrue);
          expect(await _executar(viewModel, operacao, mae), isFalse);
          expect(notificacoes, 1);
          expect(viewModel.demandas, [mae]);
          expect(repository.chamadasListar, 1);
          _verificarChamada(repository, operacao, mae.id!);
        },
      );
    }

    test(
      'alteração normal encaminha cancelamento e motivo sem validar',
      () async {
        final mae = demandaFixture();
        final repository = FakeDemandaRepository(demandas: [mae]);
        final resposta = Completer<backend.Demanda>();
        repository.respostaAlterarStatusPendente = resposta;
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        final mutacao = viewModel.alterarStatusDemanda(
          demanda: mae,
          status: backend.DemandaStatus.cancelada,
          motivoCancelamento: ' ',
        );
        final erro = backend.TransicaoStatusException(
          codigo:
              backend.TransicaoStatusErroCodigo.motivoCancelamentoObrigatorio,
          mensagem: 'Informe o motivo do cancelamento.',
        );
        resposta.completeError(erro);

        expect(await mutacao, isFalse);
        expect(repository.chamadasAlterarStatus, 1);
        expect(repository.ultimaAlteracaoStatus?.id, mae.id);
        expect(
          repository.ultimaAlteracaoStatus?.status,
          backend.DemandaStatus.cancelada,
        );
        expect(repository.ultimaAlteracaoStatus?.motivoCancelamento, ' ');
        expect(viewModel.erroTransicaoStatus, same(erro));
      },
    );

    test('limpa erro tipado ao iniciar uma nova operação de status', () async {
      final mae = demandaFixture();
      final repository = FakeDemandaRepository(demandas: [mae]);
      final resposta = Completer<backend.Demanda>();
      repository.respostaAlterarStatusPendente = resposta;
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      final conclusao = viewModel.concluirDemanda(mae);
      resposta.completeError(
        backend.TransicaoStatusException(
          codigo: backend.TransicaoStatusErroCodigo.descendentesAtivos,
          mensagem: 'Conclua em cascata.',
          podeConcluirEmCascata: true,
        ),
      );
      expect(await conclusao, isFalse);
      expect(viewModel.erroTransicaoStatus, isNotNull);

      final respostaCascata = Completer<backend.Demanda>();
      repository.respostaConcluirEmCascataPendente = respostaCascata;
      final cascata = viewModel.concluirDemandaEmCascata(mae);
      expect(viewModel.erro, isNull);
      expect(viewModel.erroTransicaoStatus, isNull);
      respostaCascata.complete(
        mae.copyWith(status: backend.DemandaStatus.concluida),
      );
      expect(await cascata, isTrue);
      expect(viewModel.erroTransicaoStatus, isNull);
    });

    test(
      'preserva confirmação e demandaCriada quando o refresh da cascata falha',
      () async {
        final repository = FakeDemandaRepository();
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.criarDemanda(titulo: 'Criada', tempoEstimadoHoras: 1);
        final criada = viewModel.demandaCriada!;
        final retornada = criada.copyWith(
          status: backend.DemandaStatus.concluida,
        );
        repository.respostaConcluirEmCascataPendente =
            Completer<backend.Demanda>()..complete(retornada);
        repository.erroAoListar = StateError('Falha no refresh');

        expect(await viewModel.concluirDemandaEmCascata(criada), isTrue);
        expect(viewModel.demandas.single, same(retornada));
        expect(viewModel.demandaCriada, same(retornada));
        expect(viewModel.enviando, isFalse);
        expect(viewModel.carregando, isFalse);
        expect(viewModel.erroTransicaoStatus, isNull);
        expect(
          viewModel.erro,
          'A alteração foi salva, mas não foi possível atualizar a lista. '
          'Recarregue as demandas.',
        );
      },
    );

    test(
      'sincroniza demandaCriada quando ela é afetada pela cascata',
      () async {
        final mae = demandaFixture();
        final repository = FakeDemandaRepository(demandas: [mae]);
        final viewModel = DemandasViewModel(repository: repository);
        addTearDown(viewModel.dispose);
        await viewModel.carregarDemandas();
        await viewModel.criarDemanda(
          titulo: 'Filha criada',
          tempoEstimadoHoras: 1,
          demandaPaiId: mae.id,
        );
        final maeConcluida = mae.copyWith(
          status: backend.DemandaStatus.concluida,
        );
        final filhaConcluida = viewModel.demandaCriada!.copyWith(
          status: backend.DemandaStatus.concluida,
        );
        repository.respostaConcluirEmCascataPendente =
            Completer<backend.Demanda>()..complete(maeConcluida);
        repository.respostasListarPendentes.add(
          Completer<List<backend.Demanda>>()
            ..complete([maeConcluida, filhaConcluida]),
        );

        expect(await viewModel.concluirDemandaEmCascata(mae), isTrue);
        expect(viewModel.demandaCriada, same(filhaConcluida));
        expect(viewModel.filhasDe(mae).single, same(filhaConcluida));
      },
    );

    test('uma carga anterior não desfaz o status confirmado', () async {
      final mae = demandaFixture();
      final repository = FakeDemandaRepository(demandas: [mae]);
      final viewModel = DemandasViewModel(repository: repository);
      addTearDown(viewModel.dispose);
      await viewModel.carregarDemandas();
      final respostaAntiga = Completer<List<backend.Demanda>>();
      repository.respostasListarPendentes.add(respostaAntiga);
      final cargaAntiga = viewModel.carregarDemandas();
      final retornada = mae.copyWith(status: backend.DemandaStatus.concluida);
      repository.respostaAlterarStatusPendente = Completer<backend.Demanda>()
        ..complete(retornada);

      expect(await viewModel.concluirDemanda(mae), isTrue);
      respostaAntiga.complete([mae]);
      await cargaAntiga;

      expect(viewModel.demandas.single, same(retornada));
      expect(repository.chamadasListar, 2);
      expect(viewModel.carregando, isFalse);
    });
  });
}

Future<bool> _executar(
  DemandasViewModel viewModel,
  String operacao,
  backend.Demanda demanda,
) => switch (operacao) {
  'alterar' => viewModel.alterarStatusDemanda(
    demanda: demanda,
    status: backend.DemandaStatus.emAndamento,
    motivoCancelamento: _motivo,
  ),
  'concluir' => viewModel.concluirDemanda(demanda),
  'concluir em cascata' => viewModel.concluirDemandaEmCascata(demanda),
  'cancelar em cascata' => viewModel.cancelarDemandaEmCascata(demanda, _motivo),
  _ => throw ArgumentError.value(operacao),
};

void _configurarResposta(
  FakeDemandaRepository repository,
  String operacao,
  Completer<backend.Demanda> resposta,
) {
  switch (operacao) {
    case 'alterar':
    case 'concluir':
      repository.respostaAlterarStatusPendente = resposta;
    case 'concluir em cascata':
      repository.respostaConcluirEmCascataPendente = resposta;
    case 'cancelar em cascata':
      repository.respostaCancelarEmCascataPendente = resposta;
    default:
      throw ArgumentError.value(operacao);
  }
}

void _verificarChamada(
  FakeDemandaRepository repository,
  String operacao,
  int id,
) {
  expect(
    repository.chamadasAlterarStatus +
        repository.chamadasConcluirEmCascata +
        repository.chamadasCancelarEmCascata,
    1,
  );
  switch (operacao) {
    case 'alterar':
    case 'concluir':
      expect(repository.ultimaAlteracaoStatus?.id, id);
      expect(
        repository.ultimaAlteracaoStatus?.status,
        operacao == 'alterar'
            ? backend.DemandaStatus.emAndamento
            : backend.DemandaStatus.concluida,
      );
      expect(
        repository.ultimaAlteracaoStatus?.motivoCancelamento,
        operacao == 'alterar' ? _motivo : isNull,
      );
    case 'concluir em cascata':
      expect(repository.ultimoIdConclusaoEmCascata, id);
    case 'cancelar em cascata':
      expect(repository.ultimoCancelamentoEmCascata, (id: id, motivo: _motivo));
  }
}
