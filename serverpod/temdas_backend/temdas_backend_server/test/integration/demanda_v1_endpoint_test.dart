import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  final prefixo = 'teste-v1-${DateTime.now().microsecondsSinceEpoch}';

  withServerpod(
    'Fluxos V1 de demandas e registros de tempo',
    (sessionBuilder, endpoints) {
      tearDown(() async {
        final session = sessionBuilder.build();
        await Demanda.db.deleteWhere(
          session,
          where: (t) => t.titulo.like('$prefixo%'),
        );
      });

      test(
        'preserva hierarquia e exclui a árvore somente pelo endpoint próprio',
        () async {
          final raiz = await endpoints.demanda.criarDemanda(
            sessionBuilder,
            _request('$prefixo raiz'),
          );
          final filha = await endpoints.demanda.criarDemanda(
            sessionBuilder,
            _request('$prefixo filha', demandaPaiId: raiz.id),
          );
          final neta = await endpoints.demanda.criarDemanda(
            sessionBuilder,
            _request('$prefixo neta', demandaPaiId: filha.id),
          );

          expect(filha.demandaPaiId, raiz.id);
          expect(neta.demandaPaiId, filha.id);
          await expectLater(
            endpoints.demanda.excluirDemanda(sessionBuilder, raiz.id!),
            throwsA(isA<Exception>()),
          );
          expect(
            await endpoints.demanda.buscarDemandaPorId(
              sessionBuilder,
              raiz.id!,
            ),
            isNotNull,
          );

          expect(
            await endpoints.demanda.excluirArvoreDemanda(
              sessionBuilder,
              raiz.id!,
            ),
            isTrue,
          );
          expect(
            await endpoints.demanda.buscarDemandaPorId(
              sessionBuilder,
              filha.id!,
            ),
            isNull,
          );
          expect(
            await endpoints.demanda.buscarDemandaPorId(
              sessionBuilder,
              neta.id!,
            ),
            isNull,
          );
        },
      );

      test(
        'conclui, reabre e preserva campos que o update não controla',
        () async {
          final raiz = await endpoints.demanda.criarDemanda(
            sessionBuilder,
            _request('$prefixo update'),
          );

          final concluida = await endpoints.demanda.atualizarDemanda(
            sessionBuilder,
            DemandaUpdateRequest(
              id: raiz.id!,
              titulo: ' $prefixo atualizada ',
              descricao: ' descrição ',
              status: DemandaStatus.concluida,
              prioridade: Prioridade.alta,
              sprint: ' sprint ',
              tempoEstimadoMinutos: 90,
              observacoes: ' observação ',
            ),
          );
          expect(concluida.concluidoEm, isNotNull);
          expect(concluida.tempoExecutadoMinutos, 0);
          expect(concluida.criadoEm, raiz.criadoEm);
          expect(concluida.demandaPaiId, raiz.demandaPaiId);

          final reaberta = await endpoints.demanda.atualizarDemanda(
            sessionBuilder,
            DemandaUpdateRequest(
              id: raiz.id!,
              titulo: concluida.titulo,
              descricao: concluida.descricao,
              status: DemandaStatus.aberta,
              prioridade: concluida.prioridade,
              sprint: concluida.sprint,
              tempoEstimadoMinutos: concluida.tempoEstimadoMinutos,
              observacoes: concluida.observacoes,
            ),
          );
          expect(reaberta.concluidoEm, isNull);
        },
      );

      test(
        'registros são a fonte do total e respeitam período semiaberto',
        () async {
          final demanda = await endpoints.demanda.criarDemanda(
            sessionBuilder,
            _request('$prefixo tempo'),
          );
          final inicio = DateTime.utc(2026, 9, 8);
          final fim = DateTime.utc(2026, 9, 10);

          final primeiro = await endpoints.registroTempo.registrarTempo(
            sessionBuilder,
            RegistroTempoCreateRequest(
              demandaId: demanda.id!,
              inicioEm: inicio,
              duracaoMinutos: 25,
            ),
          );
          await endpoints.registroTempo.registrarTempo(
            sessionBuilder,
            RegistroTempoCreateRequest(
              demandaId: demanda.id!,
              inicioEm: fim.subtract(const Duration(minutes: 1)),
              duracaoMinutos: 35,
            ),
          );
          await endpoints.registroTempo.registrarTempo(
            sessionBuilder,
            RegistroTempoCreateRequest(
              demandaId: demanda.id!,
              inicioEm: fim,
              duracaoMinutos: 15,
            ),
          );

          final persistida = await endpoints.demanda.buscarDemandaPorId(
            sessionBuilder,
            demanda.id!,
          );
          // O terceiro intervalo está contido no segundo e é absorvido.
          expect(persistida?.tempoExecutadoMinutos, 60);

          final periodo = await endpoints.registroTempo
              .listarRegistrosTempoPorPeriodo(sessionBuilder, inicio, fim);
          expect(periodo, hasLength(2));
          expect(periodo.first.inicioEm, inicio);

          expect(
            await endpoints.registroTempo.excluirRegistroTempo(
              sessionBuilder,
              primeiro.id!,
            ),
            isTrue,
          );
          final aposExclusao = await endpoints.demanda.buscarDemandaPorId(
            sessionBuilder,
            demanda.id!,
          );
          expect(aposExclusao?.tempoExecutadoMinutos, 35);
        },
      );
    },
    rollbackDatabase: RollbackDatabase.disabled,
    testServerOutputMode: TestServerOutputMode.verbose,
  );
}

DemandaCreateRequest _request(String titulo, {int? demandaPaiId}) {
  return DemandaCreateRequest(
    demandaPaiId: demandaPaiId,
    titulo: titulo,
    prioridade: Prioridade.media,
    tempoEstimadoMinutos: 60,
  );
}
