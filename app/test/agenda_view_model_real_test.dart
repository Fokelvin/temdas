import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view_model/agenda_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_agenda_repositories.dart';

void main() {
  group('AgendaViewModel', () {
    test('consulta o dia local como intervalo UTC com fim exclusivo', () async {
      final registroRepository = FakeRegistroTempoRepository();
      final viewModel = AgendaViewModel(
        demandaRepository: FakeAgendaDemandaRepository(),
        registroTempoRepository: registroRepository,
        hoje: DateTime(2026, 9, 9),
      );
      addTearDown(viewModel.dispose);

      await viewModel.carregarAgenda();

      final periodo = registroRepository.periodosConsultados.single;
      expect(periodo.inicio, DateTime(2026, 9, 9).toUtc());
      expect(periodo.fim, DateTime(2026, 9, 10).toUtc());
      expect(periodo.inicio.isUtc, isTrue);
      expect(periodo.fim.isUtc, isTrue);
    });

    test('consulta segunda a segunda no modo semanal', () async {
      final registroRepository = FakeRegistroTempoRepository();
      final viewModel = AgendaViewModel(
        demandaRepository: FakeAgendaDemandaRepository(),
        registroTempoRepository: registroRepository,
        hoje: DateTime(2026, 9, 9),
      );
      addTearDown(viewModel.dispose);

      await viewModel.setMode(AgendaMode.semana);

      final periodo = registroRepository.periodosConsultados.single;
      expect(periodo.inicio, DateTime(2026, 9, 7).toUtc());
      expect(periodo.fim, DateTime(2026, 9, 14).toUtc());
      expect(viewModel.diasDaSemana.first.weekday, DateTime.monday);
      expect(viewModel.diasDaSemana.last.weekday, DateTime.sunday);
    });

    test('agrupa pelo início local e calcula os resumos persistidos', () async {
      final registroRepository = FakeRegistroTempoRepository(
        registros: [
          registroTempoFixture(
            id: 2,
            inicioLocal: DateTime(2026, 9, 9, 15),
            duracaoMinutos: 45,
          ),
          registroTempoFixture(
            id: 1,
            inicioLocal: DateTime(2026, 9, 9, 9, 30),
            duracaoMinutos: 30,
          ),
        ],
      );
      final viewModel = AgendaViewModel(
        demandaRepository: FakeAgendaDemandaRepository(
          demandas: [demandaAgendaFixture()],
        ),
        registroTempoRepository: registroRepository,
        hoje: DateTime(2026, 9, 9),
      );
      addTearDown(viewModel.dispose);

      await viewModel.carregarAgenda();

      expect(viewModel.lancamentosDoPeriodo, 2);
      expect(viewModel.executadoDoPeriodo, const Duration(minutes: 75));
      expect(
        viewModel.registrosDoDia(DateTime(2026, 9, 9)).map((item) => item.id),
        [1, 2],
      );
      expect(viewModel.demandaPorId(1)?.titulo, 'Demanda da agenda');
      expect(viewModel.tempoExecutadoMinutosDaDemandaNoPeriodo(1), 75);
    });

    test('ignora resposta antiga após navegar para outro período', () async {
      final registroRepository = FakeRegistroTempoRepository();
      final respostaDiaAtual = Completer<List<backend.RegistroTempo>>();
      final respostaDiaSeguinte = Completer<List<backend.RegistroTempo>>();
      registroRepository.respostasPendentes
        ..add(respostaDiaAtual)
        ..add(respostaDiaSeguinte);
      final viewModel = AgendaViewModel(
        demandaRepository: FakeAgendaDemandaRepository(
          demandas: [demandaAgendaFixture()],
        ),
        registroTempoRepository: registroRepository,
        hoje: DateTime(2026, 9, 9),
      );
      addTearDown(viewModel.dispose);

      final carregamentoDiaAtual = viewModel.carregarAgenda();
      final carregamentoDiaSeguinte = viewModel.proximoPeriodo();
      respostaDiaSeguinte.complete([
        registroTempoFixture(id: 2, inicioLocal: DateTime(2026, 9, 10, 10)),
      ]);
      await carregamentoDiaSeguinte;
      respostaDiaAtual.complete([
        registroTempoFixture(id: 1, inicioLocal: DateTime(2026, 9, 9, 10)),
      ]);
      await carregamentoDiaAtual;

      expect(viewModel.dataSelecionada, DateTime(2026, 9, 10));
      expect(viewModel.registros.single.id, 2);
      expect(viewModel.carregando, isFalse);
    });

    test('converte horas em minutos e envia o início em UTC', () async {
      final registroRepository = FakeRegistroTempoRepository();
      final viewModel = AgendaViewModel(
        demandaRepository: FakeAgendaDemandaRepository(
          demandas: [demandaAgendaFixture()],
        ),
        registroTempoRepository: registroRepository,
        hoje: DateTime(2026, 9, 9),
      );
      addTearDown(viewModel.dispose);
      await viewModel.carregarAgenda();

      final salvo = await viewModel.registrarTempo(
        demandaId: 1,
        data: DateTime(2026, 9, 9),
        hora: const TimeOfDay(hour: 13, minute: 45),
        duracaoHoras: 1.25,
      );

      expect(salvo, isTrue);
      final chamada = registroRepository.registrosCriados.single;
      expect(chamada.duracaoMinutos, 75);
      expect(chamada.inicioEm, DateTime(2026, 9, 9, 13, 45).toUtc());
      expect(chamada.inicioEm.isUtc, isTrue);
      expect(viewModel.executadoDoPeriodo, const Duration(minutes: 75));
    });

    test(
      'recusa hora que não pode ser representada em minutos inteiros',
      () async {
        final registroRepository = FakeRegistroTempoRepository();
        final viewModel = AgendaViewModel(
          demandaRepository: FakeAgendaDemandaRepository(
            demandas: [demandaAgendaFixture()],
          ),
          registroTempoRepository: registroRepository,
          hoje: DateTime(2026, 9, 9),
        );
        addTearDown(viewModel.dispose);
        await viewModel.carregarAgenda();

        final salvo = await viewModel.registrarTempo(
          demandaId: 1,
          data: DateTime(2026, 9, 9),
          hora: const TimeOfDay(hour: 9, minute: 0),
          duracaoHoras: 0.01,
        );

        expect(salvo, isFalse);
        expect(registroRepository.registrosCriados, isEmpty);
        expect(viewModel.erro, contains('minutos inteiros'));
      },
    );
  });
}
