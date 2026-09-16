import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  for (final anterior in [
    backend.DemandaStatus.concluida,
    backend.DemandaStatus.cancelada,
  ]) {
    for (final status in [
      backend.DemandaStatus.aberta,
      backend.DemandaStatus.emAndamento,
      backend.DemandaStatus.pausada,
    ]) {
      test('reabre $anterior para $status alterando apenas a filha', () async {
        final mae = demandaFixture(id: 1);
        final filha = demandaFixture(id: 2, demandaPaiId: 1, status: anterior);
        final irma = demandaFixture(id: 3, demandaPaiId: 1);
        final repository = FakeDemandaRepository(demandas: [mae, filha, irma]);
        final vm = DemandasViewModel(repository: repository);
        addTearDown(vm.dispose);
        await vm.carregarDemandas();
        final retornada = filha.copyWith(status: status, concluidoEm: null);
        repository.respostaAlterarStatusPendente = Completer<backend.Demanda>()
          ..complete(retornada);
        repository.erroAoListar = StateError('Não deve fazer refresh');

        expect(
          await vm.alterarStatusDemanda(demanda: filha, status: status),
          isTrue,
        );
        expect(repository.chamadasListar, 1);
        expect(vm.demandas.map((item) => item.id), [1, 2, 3]);
        expect(vm.demandas[0], same(mae));
        expect(vm.demandas[1], same(retornada));
        expect(vm.demandas[2], same(irma));
        expect(vm.demandasRaiz.single, same(mae));
        expect(vm.filhasDe(mae), [retornada, irma]);
        expect(vm.erro, isNull);
        expect(vm.carregando, isFalse);
      });
    }
  }

  test(
    'edita metadados de cancelada sem reload e sincroniza demandaCriada',
    () async {
      final mae = demandaFixture();
      final repository = FakeDemandaRepository(demandas: [mae]);
      final vm = DemandasViewModel(repository: repository);
      addTearDown(vm.dispose);
      await vm.carregarDemandas();
      await vm.criarDemanda(
        titulo: 'Filha',
        tempoEstimadoHoras: 1,
        demandaPaiId: 1,
      );
      final criada = vm.demandaCriada!;
      final cancelada = criada.copyWith(
        status: backend.DemandaStatus.cancelada,
        motivoCancelamento: 'Motivo mantido',
      );
      repository.respostasListarPendentes.add(
        Completer<List<backend.Demanda>>()..complete([cancelada, mae]),
      );
      await vm.carregarDemandas();
      final retornada = cancelada.copyWith(titulo: 'Título corrigido');
      final resposta = Completer<backend.Demanda>();
      repository.respostaAtualizarPendente = resposta;

      // O objeto de um diálogo antigo não deve prevalecer sobre a lista atual.
      final mutacao = _editar(
        vm,
        criada,
        status: backend.DemandaStatus.cancelada,
      );
      expect(vm.demandasEmProcessamento, {criada.id});
      expect(vm.envioGlobalEmAndamento, isFalse);
      expect(vm.carregando, isFalse);
      resposta.complete(retornada);

      expect(await mutacao, isTrue);
      expect(repository.chamadasListar, 2); // Apenas as duas cargas explícitas.
      expect(vm.demandas.first, same(retornada));
      expect(vm.demandas.last, same(mae));
      expect(vm.demandaCriada, same(retornada));
      expect(vm.demandaCriada!.motivoCancelamento, 'Motivo mantido');
      expect(vm.demandasEmProcessamento, isEmpty);
    },
  );

  test('editar cancelada com o mesmo status faz somente patch local', () async {
    final alvo = demandaFixture(status: backend.DemandaStatus.cancelada);
    final filha = demandaFixture(id: 2, demandaPaiId: 1);
    final repository = FakeDemandaRepository(demandas: [alvo, filha]);
    final vm = DemandasViewModel(repository: repository);
    addTearDown(vm.dispose);
    await vm.carregarDemandas();

    expect(await _editar(vm, alvo), isTrue);
    expect(repository.chamadasListar, 1);
    expect(vm.demandas.first.titulo, 'Editada');
    expect(vm.demandas.first.status, backend.DemandaStatus.cancelada);
    expect(vm.demandas.last, same(filha));
  });

  for (final anterior in [
    backend.DemandaStatus.aberta,
    backend.DemandaStatus.cancelada,
  ]) {
    test(
      'endpoint de status mantém reload ao cancelar alvo $anterior',
      () async {
        final alvo = demandaFixture(status: anterior);
        final filha = demandaFixture(id: 2, demandaPaiId: 1);
        final cancelada = alvo.copyWith(
          status: backend.DemandaStatus.cancelada,
        );
        final filhaCancelada = filha.copyWith(
          status: backend.DemandaStatus.cancelada,
        );
        final repository = FakeDemandaRepository(demandas: [alvo, filha]);
        final vm = DemandasViewModel(repository: repository);
        addTearDown(vm.dispose);
        await vm.carregarDemandas();
        repository.respostaAlterarStatusPendente = Completer<backend.Demanda>()
          ..complete(cancelada);
        repository.respostasListarPendentes.add(
          Completer<List<backend.Demanda>>()
            ..complete([cancelada, filhaCancelada]),
        );

        expect(
          await vm.alterarStatusDemanda(
            demanda: alvo,
            status: backend.DemandaStatus.cancelada,
            motivoCancelamento: 'Motivo',
          ),
          isTrue,
        );
        expect(repository.chamadasListar, 2);
        expect(vm.demandas, [cancelada, filhaCancelada]);
      },
    );
  }

  test(
    'edição e status de IDs distintos terminam fora de ordem sem se bloquear',
    () async {
      final a = demandaFixture(id: 1);
      final b = demandaFixture(id: 2);
      final c = demandaFixture(id: 3);
      final repository = FakeDemandaRepository(demandas: [a, b, c]);
      final vm = DemandasViewModel(repository: repository);
      addTearDown(vm.dispose);
      await vm.carregarDemandas();
      final respostaA = Completer<backend.Demanda>();
      final respostaB = Completer<backend.Demanda>();
      repository.respostaAtualizarPendente = respostaA;
      repository.respostaAlterarStatusPendente = respostaB;

      final mutacaoA = _editar(vm, a);
      expect(vm.demandasEmProcessamento, {1});
      expect(vm.demandaEmProcessamento(2), isFalse);
      expect(vm.envioGlobalEmAndamento, isFalse);
      expect(await vm.concluirDemanda(a), isFalse);
      final mutacaoB = vm.alterarStatusDemanda(
        demanda: b,
        status: backend.DemandaStatus.emAndamento,
      );
      expect(vm.demandasEmProcessamento, {1, 2});
      expect(() => vm.demandasEmProcessamento.add(3), throwsUnsupportedError);
      expect(await _editar(vm, b), isFalse);
      expect(repository.chamadasAtualizar, 1);
      expect(repository.chamadasAlterarStatus, 1);
      expect(vm.carregando, isFalse);

      final atualizadaB = b.copyWith(status: backend.DemandaStatus.emAndamento);
      respostaB.complete(atualizadaB);
      expect(await mutacaoB, isTrue);
      expect(vm.demandasEmProcessamento, {1});
      expect(vm.enviando, isTrue);
      expect(vm.demandas[0], same(a));
      expect(vm.demandas[1], same(atualizadaB));
      final atualizadaA = a.copyWith(titulo: 'Confirmada');
      respostaA.complete(atualizadaA);
      expect(await mutacaoA, isTrue);
      expect(vm.demandas[0], same(atualizadaA));
      expect(vm.demandas[1], same(atualizadaB));
      expect(vm.demandas[2], same(c));
      expect(vm.demandas.map((item) => item.id), [1, 2, 3]);
      expect(vm.demandasEmProcessamento, isEmpty);
      expect(vm.enviando, isFalse);
      expect(repository.chamadasListar, 1);
    },
  );

  test(
    'recusas simultâneas preservam os objetos e o erro de cada demanda',
    () async {
      final a = demandaFixture(id: 1);
      final b = demandaFixture(id: 2);
      final repository = FakeDemandaRepository(demandas: [a, b]);
      final vm = DemandasViewModel(repository: repository);
      addTearDown(vm.dispose);
      await vm.carregarDemandas();
      final respostaA = Completer<backend.Demanda>();
      final respostaB = Completer<backend.Demanda>();
      repository.respostaAlterarStatusPendente = respostaA;
      final mutacaoA = vm.concluirDemanda(a);
      repository.respostaAlterarStatusPendente = respostaB;
      final mutacaoB = vm.concluirDemanda(b);
      final erroA = backend.TransicaoStatusException(
        codigo: backend.TransicaoStatusErroCodigo.descendentesAtivos,
        mensagem: 'A precisa de cascata.',
        podeConcluirEmCascata: true,
      );
      respostaA.completeError(erroA);
      expect(await mutacaoA, isFalse);
      expect(vm.demandasEmProcessamento, {2});
      respostaB.completeError(StateError('Falha de B'));
      expect(await mutacaoB, isFalse);

      expect(vm.demandas.first, same(a));
      expect(vm.demandas.last, same(b));
      expect(vm.erroTransicaoDaDemanda(1), same(erroA));
      expect(vm.erroDaDemanda(1), erroA.mensagem);
      expect(vm.erroTransicaoDaDemanda(2), isNull);
      expect(vm.erroDaDemanda(2), contains('Não foi possível alterar'));
      expect(vm.erroTransicaoStatus, isNull);
      expect(repository.chamadasListar, 1);
      expect(vm.demandasEmProcessamento, isEmpty);

      repository.respostaAlterarStatusPendente = Completer<backend.Demanda>()
        ..complete(a.copyWith(status: backend.DemandaStatus.pausada));
      expect(
        await vm.alterarStatusDemanda(
          demanda: a,
          status: backend.DemandaStatus.pausada,
        ),
        isTrue,
      );
      expect(vm.erroDaDemanda(1), isNull);
      expect(vm.erroTransicaoDaDemanda(1), isNull);
    },
  );

  test('fluxos globais não se sobrepõem a um patch ainda pendente', () async {
    final a = demandaFixture(id: 1);
    final b = demandaFixture(id: 2);
    final repository = FakeDemandaRepository(demandas: [a, b]);
    final vm = DemandasViewModel(repository: repository);
    addTearDown(vm.dispose);
    await vm.carregarDemandas();
    final resposta = Completer<backend.Demanda>();
    repository.respostaAlterarStatusPendente = resposta;
    final mutacao = vm.concluirDemanda(a);

    expect(await vm.concluirDemandaEmCascata(b), isFalse);
    expect(await vm.cancelarDemandaEmCascata(b, 'Motivo'), isFalse);
    expect(await vm.excluirArvoreDemanda(b), isFalse);
    expect(repository.chamadasConcluirEmCascata, 0);
    expect(repository.chamadasCancelarEmCascata, 0);
    expect(repository.chamadasExcluirArvore, 0);
    expect(vm.demandasEmProcessamento, {1});

    resposta.complete(a.copyWith(status: backend.DemandaStatus.concluida));
    expect(await mutacao, isTrue);
    expect(await vm.excluirArvoreDemanda(b), isTrue);
    expect(repository.chamadasExcluirArvore, 1);
  });

  test('edição pendente não aplica patch nem notifica após dispose', () async {
    final alvo = demandaFixture();
    final repository = FakeDemandaRepository(demandas: [alvo]);
    final resposta = Completer<backend.Demanda>();
    repository.respostaAtualizarPendente = resposta;
    final vm = DemandasViewModel(repository: repository);
    await vm.carregarDemandas();
    var notificacoes = 0;
    vm.addListener(() => notificacoes++);
    final mutacao = _editar(vm, alvo);
    vm.dispose();
    resposta.complete(alvo.copyWith(titulo: 'Salva'));

    expect(await mutacao, isTrue);
    expect(await _editar(vm, alvo), isFalse);
    expect(vm.demandas.single, same(alvo));
    expect(notificacoes, 1);
    expect(repository.chamadasAtualizar, 1);
    expect(repository.chamadasListar, 1);
  });
}

Future<bool> _editar(
  DemandasViewModel vm,
  backend.Demanda demanda, {
  backend.DemandaStatus? status,
}) => vm.atualizarDemanda(
  demanda: demanda,
  titulo: 'Editada',
  tempoEstimadoHoras: 1,
  status: status ?? demanda.status,
  prioridade: demanda.prioridade,
);
