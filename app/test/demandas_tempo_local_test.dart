import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas/view_model/tempo_executado_total.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  for (final id in [1, 2]) {
    test(
      'lançar em $id busca e substitui só esse objeto, usando o valor do backend',
      () async {
        final mae = demandaFixture(id: 1, tempoExecutadoMinutos: 0);
        final filha = demandaFixture(
          id: 2,
          demandaPaiId: 1,
          tempoExecutadoMinutos: 0,
        );
        final outra = demandaFixture(id: 3);
        final repository = FakeDemandaRepository(demandas: [mae, filha, outra]);
        final registros = FakeRegistroTempoRepository(
          demandaRepository: repository,
        );
        final vm = DemandasViewModel(
          repository: repository,
          registroTempoRepository: registros,
        );
        addTearDown(vm.dispose);
        await vm.carregarDemandas();
        final alvo = id == 1 ? mae : filha;
        final resposta = Completer<backend.Demanda?>();
        repository.respostaBuscarPendente = resposta;
        repository.erroAoListar = StateError('Não deve recarregar');
        final carregamentos = <bool>[];
        vm.addListener(() => carregamentos.add(vm.carregando));
        final operacao = vm.registrarTempo(
          demanda: alvo,
          inicioEm: DateTime.utc(2026),
          duracaoMinutos: 90,
        );
        await Future<void>.delayed(Duration.zero);
        expect(vm.demandasEmProcessamento, {id});
        expect(vm.envioGlobalEmAndamento, isFalse);
        expect(repository.idsBuscados, [id]);
        expect(vm.demandas[id - 1], same(alvo));
        expect(
          await vm.registrarTempo(
            demanda: alvo,
            inicioEm: DateTime.utc(2026),
            duracaoMinutos: 90,
          ),
          isFalse,
        );
        // O valor retornado é intencionalmente diferente da duração enviada.
        final atualizada = alvo.copyWith(tempoExecutadoMinutos: 135);
        resposta.complete(atualizada);
        expect(await operacao, isTrue);
        expect(vm.demandas[id - 1], same(atualizada));
        expect(vm.demandas[id == 1 ? 1 : 0], same(id == 1 ? filha : mae));
        expect(vm.demandas[2], same(outra));
        expect(alvo.tempoExecutadoMinutos, 0);
        expect(
          vm.demandas[id - 1].tempoEstimadoMinutos,
          alvo.tempoEstimadoMinutos,
        );
        expect(calcularTemposExecutadosTotais(vm.demandas)[1], 135);
        expect(repository.chamadasListar, 1);
        expect(repository.idsBuscados, [id]);
        expect(repository.chamadasAtualizar, 0);
        expect(registros.chamadasRegistrar, 1);
        expect(carregamentos, everyElement(isFalse));
        expect(vm.demandasEmProcessamento, isEmpty);
      },
    );
  }

  for (final ausente in [false, true]) {
    test(
      'registro salvo com ${ausente ? 'demanda ausente' : 'falha na busca'} informa atualização pendente',
      () async {
        final demanda = demandaFixture();
        final repository = FakeDemandaRepository(demandas: [demanda]);
        final registros = FakeRegistroTempoRepository();
        final vm = DemandasViewModel(
          repository: repository,
          registroTempoRepository: registros,
        );
        addTearDown(vm.dispose);
        await vm.carregarDemandas();
        final resposta = Completer<backend.Demanda?>();
        repository.respostaBuscarPendente = resposta;
        final operacao = vm.registrarTempo(
          demanda: demanda,
          inicioEm: DateTime.utc(2026),
          duracaoMinutos: 90,
        );
        await Future<void>.delayed(Duration.zero);
        if (ausente) {
          resposta.complete(null);
        } else {
          resposta.completeError(StateError('Falha na leitura'));
        }
        expect(await operacao, isTrue);
        expect(vm.erroDaDemanda(1), contains('O tempo foi registrado'));
        expect(vm.demandas.single, same(demanda));
        expect(repository.chamadasListar, 1);
        expect(repository.idsBuscados, [1]);
        expect(registros.chamadasRegistrar, 1);
        expect(vm.demandasEmProcessamento, isEmpty);
      },
    );
  }

  test(
    'falha ao registrar libera o ID e não busca nem substitui a demanda',
    () async {
      final demanda = demandaFixture();
      final repository = FakeDemandaRepository(demandas: [demanda]);
      final resposta = Completer<backend.RegistroTempo>();
      final registros = FakeRegistroTempoRepository()
        ..respostaRegistrarPendente = resposta;
      final vm = DemandasViewModel(
        repository: repository,
        registroTempoRepository: registros,
      );
      addTearDown(vm.dispose);
      await vm.carregarDemandas();
      final operacao = vm.registrarTempo(
        demanda: demanda,
        inicioEm: DateTime.utc(2026),
        duracaoMinutos: 90,
      );
      resposta.completeError(StateError('Falha ao registrar'));
      expect(await operacao, isFalse);
      expect(vm.erroDaDemanda(1), contains('Não foi possível registrar'));
      expect(repository.idsBuscados, isEmpty);
      expect(repository.chamadasListar, 1);
      expect(vm.demandas.single, same(demanda));
      expect(vm.demandasEmProcessamento, isEmpty);
    },
  );
}
