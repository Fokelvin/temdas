import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  final prefixo = 'teste-relatorio-${DateTime.now().microsecondsSinceEpoch}';
  final inicio = DateTime.utc(2026, 9, 1);
  final fim = DateTime.utc(2026, 9, 3);

  withServerpod(
    'Relatório de demandas e tempo',
    (sessionBuilder, endpoints) {
      tearDown(() async {
        final session = sessionBuilder.build();
        await Demanda.db.deleteWhere(
          session,
          where: (t) => t.titulo.like('$prefixo%'),
        );
      });

      test('agrega período, hierarquia e total sem dupla contagem', () async {
        final raiz = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          _request('$prefixo raiz', estimativa: 300),
        );
        final filha = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          _request(
            '$prefixo filha',
            demandaPaiId: raiz.id,
            estimativa: 180,
          ),
        );
        final neta = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          _request(
            '$prefixo neta',
            demandaPaiId: filha.id,
            estimativa: 60,
          ),
        );
        final semTempo = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          _request('$prefixo sem tempo'),
        );

        await _registrar(
          endpoints,
          sessionBuilder,
          raiz.id!,
          DateTime.utc(2026, 9, 1, 0),
          60,
        );
        await _registrar(
          endpoints,
          sessionBuilder,
          raiz.id!,
          DateTime.utc(2026, 9, 1, 1, 30),
          90,
        );
        await _registrar(
          endpoints,
          sessionBuilder,
          filha.id!,
          DateTime.utc(2026, 9, 1, 4),
          180,
        );
        await _registrar(
          endpoints,
          sessionBuilder,
          neta.id!,
          DateTime.utc(2026, 9, 1, 8),
          60,
        );
        await _registrar(
          endpoints,
          sessionBuilder,
          raiz.id!,
          fim,
          30,
        );
        await _registrar(
          endpoints,
          sessionBuilder,
          semTempo.id!,
          inicio.subtract(const Duration(minutes: 1)),
          15,
        );

        final resposta = await endpoints.relatorio.gerarRelatorioDemandas(
          sessionBuilder,
          _periodo(inicio, fim),
        );

        expect(resposta.inicioEm, inicio);
        expect(resposta.fimExclusivo, fim);
        expect(resposta.tempoRealizadoTotalMinutos, 390);
        expect(resposta.quantidadeDemandasComTempo, 3);
        expect(resposta.itens.map((item) => item.demandaId), [
          raiz.id,
          filha.id,
          neta.id,
        ]);
        expect(resposta.itens[0].demandaMaeId, isNull);
        expect(resposta.itens[0].nivelHierarquico, 0);
        expect(resposta.itens[0].tempoEstimadoMinutos, 300);
        expect(resposta.itens[0].tempoRealizadoProprioMinutos, 150);
        expect(resposta.itens[0].tempoRealizadoTotalArvoreMinutos, 390);
        expect(resposta.itens[0].apenasContexto, isFalse);
        expect(resposta.itens[1].demandaMaeId, raiz.id);
        expect(resposta.itens[1].nivelHierarquico, 1);
        expect(resposta.itens[1].tempoRealizadoTotalArvoreMinutos, 240);
        expect(resposta.itens[2].demandaMaeId, filha.id);
        expect(resposta.itens[2].nivelHierarquico, 2);
        expect(resposta.itens[2].tempoRealizadoTotalArvoreMinutos, 60);
      });

      test(
        'filtros usam estado atual e preservam ancestrais como contexto',
        () async {
          final raiz = await endpoints.demanda.criarDemanda(
            sessionBuilder,
            _request('$prefixo contexto', prioridade: Prioridade.baixa),
          );
          final filha = await endpoints.demanda.criarDemanda(
            sessionBuilder,
            _request(
              '$prefixo selecionada',
              demandaPaiId: raiz.id,
              prioridade: Prioridade.alta,
            ),
          );
          final outra = await endpoints.demanda.criarDemanda(
            sessionBuilder,
            _request('$prefixo outra', prioridade: Prioridade.alta),
          );
          await endpoints.demanda.atualizarDemanda(
            sessionBuilder,
            DemandaUpdateRequest(
              id: filha.id!,
              titulo: filha.titulo,
              descricao: filha.descricao,
              status: DemandaStatus.concluida,
              motivoCancelamento: null,
              prioridade: Prioridade.alta,
              sprint: filha.sprint,
              tempoEstimadoMinutos: filha.tempoEstimadoMinutos,
              observacoes: filha.observacoes,
            ),
          );
          await _registrar(
            endpoints,
            sessionBuilder,
            raiz.id!,
            DateTime.utc(2026, 9, 1, 1),
            40,
          );
          await _registrar(
            endpoints,
            sessionBuilder,
            filha.id!,
            DateTime.utc(2026, 9, 1, 2),
            80,
          );
          await _registrar(
            endpoints,
            sessionBuilder,
            outra.id!,
            DateTime.utc(2026, 9, 1, 3),
            20,
          );

          final porStatus = await endpoints.relatorio.gerarRelatorioDemandas(
            sessionBuilder,
            _periodo(inicio, fim, status: DemandaStatus.concluida),
          );
          expect(porStatus.tempoRealizadoTotalMinutos, 80);
          expect(porStatus.quantidadeDemandasComTempo, 1);
          expect(porStatus.itens.map((item) => item.demandaId), [
            raiz.id,
            filha.id,
          ]);
          expect(porStatus.itens.first.apenasContexto, isTrue);
          expect(porStatus.itens.first.tempoRealizadoProprioMinutos, 0);
          expect(porStatus.itens.first.tempoRealizadoTotalArvoreMinutos, 80);

          final porPrioridade = await endpoints.relatorio
              .gerarRelatorioDemandas(
                sessionBuilder,
                _periodo(inicio, fim, prioridade: Prioridade.alta),
              );
          expect(porPrioridade.tempoRealizadoTotalMinutos, 100);
          expect(porPrioridade.quantidadeDemandasComTempo, 2);
          expect(
            porPrioridade.itens.map((item) => item.demandaId),
            [raiz.id, filha.id, outra.id],
          );

          final combinado = await endpoints.relatorio.gerarRelatorioDemandas(
            sessionBuilder,
            _periodo(
              inicio,
              fim,
              status: DemandaStatus.concluida,
              prioridade: Prioridade.alta,
            ),
          );
          expect(combinado.tempoRealizadoTotalMinutos, 80);
          expect(combinado.quantidadeDemandasComTempo, 1);
        },
      );

      test('valida UTC, intervalo e período sem registros', () async {
        final vazio = await endpoints.relatorio.gerarRelatorioDemandas(
          sessionBuilder,
          _periodo(inicio, fim),
        );
        expect(vazio.itens, isEmpty);
        expect(vazio.tempoRealizadoTotalMinutos, 0);
        expect(vazio.quantidadeDemandasComTempo, 0);

        await expectLater(
          endpoints.relatorio.gerarRelatorioDemandas(
            sessionBuilder,
            _periodo(fim, inicio),
          ),
          throwsA(isA<Exception>()),
        );
        await expectLater(
          endpoints.relatorio.gerarRelatorioDemandas(
            sessionBuilder,
            RelatorioDemandaRequest(
              inicioEm: DateTime(2026, 9, 1),
              fimExclusivo: fim,
              status: null,
              prioridade: null,
            ),
          ),
          throwsA(isA<Exception>()),
        );
      });
    },
    rollbackDatabase: RollbackDatabase.disabled,
    testServerOutputMode: TestServerOutputMode.verbose,
  );
}

RelatorioDemandaRequest _periodo(
  DateTime inicio,
  DateTime fim, {
  DemandaStatus? status,
  Prioridade? prioridade,
}) => RelatorioDemandaRequest(
  inicioEm: inicio,
  fimExclusivo: fim,
  status: status,
  prioridade: prioridade,
);

DemandaCreateRequest _request(
  String titulo, {
  int? demandaPaiId,
  int estimativa = 60,
  Prioridade prioridade = Prioridade.media,
}) => DemandaCreateRequest(
  demandaPaiId: demandaPaiId,
  titulo: titulo,
  prioridade: prioridade,
  tempoEstimadoMinutos: estimativa,
);

Future<void> _registrar(
  TestEndpoints endpoints,
  TestSessionBuilder sessionBuilder,
  int demandaId,
  DateTime inicioEm,
  int duracaoMinutos,
) async {
  await endpoints.registroTempo.registrarTempo(
    sessionBuilder,
    RegistroTempoCreateRequest(
      demandaId: demandaId,
      inicioEm: inicioEm,
      duracaoMinutos: duracaoMinutos,
    ),
  );
}
