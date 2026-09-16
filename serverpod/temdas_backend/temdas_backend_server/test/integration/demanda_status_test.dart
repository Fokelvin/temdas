import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  final prefixo = 'teste-status-${DateTime.now().microsecondsSinceEpoch}';
  withServerpod('Transições de status', (sessionBuilder, endpoints) {
    Future<Demanda> criar(
      String titulo, {
      int? pai,
      DemandaStatus status = DemandaStatus.aberta,
      String? motivo,
    }) async {
      final demanda = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo $titulo',
          demandaPaiId: pai,
          tempoEstimadoMinutos: 60,
        ),
      );
      // Fixtures incluem dados legados e descendentes ativos sob terminais.
      return Demanda.db.updateRow(
        sessionBuilder.build(),
        demanda.copyWith(
          status: status,
          motivoCancelamento: motivo,
          concluidoEm: status == DemandaStatus.concluida
              ? DateTime.utc(2026, 1, 1)
              : null,
        ),
      );
    }

    Future<Demanda> ler(Demanda demanda) async => (await endpoints.demanda
        .buscarDemandaPorId(sessionBuilder, demanda.id!))!;

    Future<Demanda> alterar(
      Demanda demanda,
      DemandaStatus status, {
      String? motivo,
    }) => endpoints.demanda.alterarStatusDemanda(
      sessionBuilder,
      demanda.id!,
      status,
      motivoCancelamento: motivo,
    );

    Future<Demanda> editar(
      Demanda demanda,
      DemandaStatus status, {
      String? motivo,
    }) => endpoints.demanda.atualizarDemanda(
      sessionBuilder,
      DemandaUpdateRequest(
        id: demanda.id!,
        titulo: '${demanda.titulo} editada',
        descricao: demanda.descricao,
        status: status,
        motivoCancelamento: motivo,
        prioridade: demanda.prioridade,
        sprint: demanda.sprint,
        tempoEstimadoMinutos: demanda.tempoEstimadoMinutos,
        observacoes: demanda.observacoes,
      ),
    );

    TypeMatcher<TransicaoStatusException> erro(
      TransicaoStatusErroCodigo codigo,
    ) => isA<TransicaoStatusException>().having(
      (e) => e.codigo,
      'codigo',
      codigo,
    );

    tearDown(() async {
      await Demanda.db.deleteWhere(
        sessionBuilder.build(),
        where: (t) => t.titulo.like('$prefixo%'),
      );
    });

    for (final status in DemandaStatus.values) {
      for (final motivo
          in status == DemandaStatus.cancelada
              ? [null, 'Motivo original']
              : [null]) {
        test(
          'edita metadados com status $status e motivo $motivo sem alterar descendentes',
          () async {
            final original = await criar('mãe', status: status, motivo: motivo);
            final mae = await Demanda.db.updateRow(
              sessionBuilder.build(),
              original.copyWith(
                atualizadoEm: DateTime.utc(2026, 1, 1),
                tempoExecutadoMinutos: 30,
              ),
            );
            final filha = await criar('filha ativa', pai: mae.id);
            final neta = await criar(
              'neta terminal',
              pai: filha.id,
              status: DemandaStatus.concluida,
            );
            final bisneta = await criar('bisneta ativa', pai: neta.id);

            final editada = await endpoints.demanda.atualizarDemanda(
              sessionBuilder,
              DemandaUpdateRequest(
                id: mae.id!,
                titulo: ' ${mae.titulo} editada ',
                descricao: ' descrição editada ',
                status: status,
                prioridade: Prioridade.alta,
                sprint: ' sprint editada ',
                tempoEstimadoMinutos: 90,
                observacoes: ' observações editadas ',
              ),
            );

            expect(editada.atualizadoEm.isAfter(mae.atualizadoEm), isTrue);
            expect(
              editada.toJson(),
              mae
                  .copyWith(
                    titulo: '${mae.titulo} editada',
                    descricao: 'descrição editada',
                    prioridade: Prioridade.alta,
                    sprint: 'sprint editada',
                    tempoEstimadoMinutos: 90,
                    observacoes: 'observações editadas',
                    atualizadoEm: editada.atualizadoEm,
                  )
                  .toJson(),
            );
            expect((await ler(mae)).toJson(), editada.toJson());
            for (final descendente in [filha, neta, bisneta]) {
              expect((await ler(descendente)).toJson(), descendente.toJson());
            }
          },
        );
      }
    }

    test(
      'conclui folha, preserva a data ao concluir novamente e permite reabrir',
      () async {
        final folha = await criar('folha');
        final concluida = await alterar(folha, DemandaStatus.concluida);
        expect((await ler(folha)).status, DemandaStatus.concluida);
        expect(concluida.concluidoEm, isNotNull);
        expect(concluida.tempoExecutadoMinutos, folha.tempoExecutadoMinutos);
        final repetida = await alterar(folha, DemandaStatus.concluida);
        expect(repetida.concluidoEm, concluida.concluidoEm);
        final reaberta = await alterar(folha, DemandaStatus.aberta);
        expect(reaberta.concluidoEm, isNull);
        expect(reaberta.motivoCancelamento, isNull);
      },
    );

    test(
      'conclui mãe quando todos os descendentes estão concluídos ou cancelados',
      () async {
        final mae = await criar('mãe');
        final filha = await criar(
          'filha',
          pai: mae.id,
          status: DemandaStatus.concluida,
        );
        final neta = await criar(
          'neta',
          pai: filha.id,
          status: DemandaStatus.cancelada,
          motivo: 'Motivo anterior',
        );
        final concluida = await editar(mae, DemandaStatus.concluida);
        expect(concluida.status, DemandaStatus.concluida);
        expect((await ler(filha)).toJson(), filha.toJson());
        expect((await ler(neta)).toJson(), neta.toJson());
      },
    );

    for (final status in [
      DemandaStatus.aberta,
      DemandaStatus.emAndamento,
      DemandaStatus.pausada,
    ]) {
      test(
        'bloqueia conclusão simples com descendente $status, inclusive pelo update',
        () async {
          final mae = await criar('mãe');
          final pai = status == DemandaStatus.aberta
              ? mae
              : await criar(
                  'filha terminal',
                  pai: mae.id,
                  status: DemandaStatus.concluida,
                );
          final ativa = await criar('ativa', pai: pai.id, status: status);
          final esperado = throwsA(
            erro(TransicaoStatusErroCodigo.descendentesAtivos).having(
              (e) => e.podeConcluirEmCascata,
              'podeConcluirEmCascata',
              true,
            ),
          );
          await expectLater(alterar(mae, DemandaStatus.concluida), esperado);
          await expectLater(editar(mae, DemandaStatus.concluida), esperado);
          expect((await ler(mae)).toJson(), mae.toJson());
          expect((await ler(ativa)).toJson(), ativa.toJson());
        },
      );
    }

    test(
      'conclusão em cascata percorre quatro níveis e preserva terminais',
      () async {
        final mae = await criar('mãe');
        final filha = await criar(
          'filha',
          pai: mae.id,
          status: DemandaStatus.emAndamento,
        );
        final neta = await criar(
          'neta',
          pai: filha.id,
          status: DemandaStatus.pausada,
        );
        final bisneta = await criar('bisneta', pai: neta.id);
        final cancelada = await criar(
          'cancelada',
          pai: mae.id,
          status: DemandaStatus.cancelada,
          motivo: 'Original',
        );
        final concluida = await criar(
          'concluída',
          pai: mae.id,
          status: DemandaStatus.concluida,
        );
        final ativaSobTerminal = await criar(
          'ativa sob cancelada',
          pai: cancelada.id,
        );
        await endpoints.demanda.concluirDemandaEmCascata(
          sessionBuilder,
          mae.id!,
        );
        for (final demanda in [mae, filha, neta, bisneta, ativaSobTerminal]) {
          final persistida = await ler(demanda);
          expect(persistida.status, DemandaStatus.concluida);
          expect(persistida.concluidoEm, isNotNull);
          expect(persistida.demandaPaiId, demanda.demandaPaiId);
        }
        expect((await ler(cancelada)).toJson(), cancelada.toJson());
        expect((await ler(concluida)).toJson(), concluida.toJson());
      },
    );

    for (final motivo in [null, '', ' \n\t ']) {
      test(
        'rejeita cancelamento com motivo ${motivo == null ? 'ausente' : 'vazio (${motivo.length})'}',
        () async {
          final mae = await criar('mãe');
          final filha = await criar('filha', pai: mae.id);
          final esperado = throwsA(
            erro(TransicaoStatusErroCodigo.motivoCancelamentoObrigatorio),
          );
          await expectLater(
            alterar(mae, DemandaStatus.cancelada, motivo: motivo),
            esperado,
          );
          await expectLater(
            editar(mae, DemandaStatus.cancelada, motivo: motivo),
            esperado,
          );
          if (motivo != null) {
            await expectLater(
              endpoints.demanda.cancelarDemandaEmCascata(
                sessionBuilder,
                mae.id!,
                motivo,
              ),
              esperado,
            );
          }
          expect((await ler(mae)).toJson(), mae.toJson());
          expect((await ler(filha)).toJson(), filha.toJson());
        },
      );
    }

    test(
      'cancela folha, persiste motivo normalizado e preserva motivo na edição',
      () async {
        final folha = await criar('folha');
        final cancelada = await alterar(
          folha,
          DemandaStatus.cancelada,
          motivo: '  Fora de escopo  ',
        );
        expect(cancelada.status, DemandaStatus.cancelada);
        expect(cancelada.concluidoEm, isNull);
        expect((await ler(folha)).motivoCancelamento, 'Fora de escopo');
        final editada = await editar(cancelada, DemandaStatus.cancelada);
        expect(editada.motivoCancelamento, 'Fora de escopo');
        await alterar(folha, DemandaStatus.aberta);
        await expectLater(
          alterar(folha, DemandaStatus.cancelada),
          throwsA(
            erro(TransicaoStatusErroCodigo.motivoCancelamentoObrigatorio),
          ),
        );
      },
    );

    for (final via in ['status', 'update', 'cascata']) {
      test(
        'cancelamento via $via cancela toda a árvore ativa e preserva terminais',
        () async {
          final mae = await criar('mãe');
          final filha = await criar(
            'filha',
            pai: mae.id,
            status: DemandaStatus.emAndamento,
          );
          final neta = await criar(
            'neta',
            pai: filha.id,
            status: DemandaStatus.pausada,
          );
          final bisneta = await criar('bisneta', pai: neta.id);
          final concluida = await criar(
            'concluída',
            pai: mae.id,
            status: DemandaStatus.concluida,
          );
          final cancelada = await criar(
            'cancelada',
            pai: mae.id,
            status: DemandaStatus.cancelada,
            motivo: 'Anterior',
          );
          final ativaSobTerminal = await criar(
            'ativa sob concluída',
            pai: concluida.id,
          );
          const motivo = 'Mudança de planos';
          switch (via) {
            case 'status':
              await alterar(mae, DemandaStatus.cancelada, motivo: motivo);
            case 'update':
              await editar(mae, DemandaStatus.cancelada, motivo: motivo);
            default:
              await endpoints.demanda.cancelarDemandaEmCascata(
                sessionBuilder,
                mae.id!,
                motivo,
              );
          }
          for (final demanda in [mae, filha, neta, bisneta, ativaSobTerminal]) {
            final persistida = await ler(demanda);
            expect(persistida.status, DemandaStatus.cancelada);
            expect(persistida.motivoCancelamento, motivo);
            expect(persistida.concluidoEm, isNull);
            expect(persistida.demandaPaiId, demanda.demandaPaiId);
          }
          expect((await ler(concluida)).toJson(), concluida.toJson());
          expect((await ler(cancelada)).toJson(), cancelada.toJson());
        },
      );
    }

    for (final concluir in [true, false]) {
      test(
        '${concluir ? 'conclusão' : 'cancelamento'} em cascata reverte descendentes se a raiz falhar',
        () async {
          final mae = await criar('mãe rollback');
          final filha = await criar('filha', pai: mae.id);
          final neta = await criar('neta', pai: filha.id);
          final session = sessionBuilder.build();
          final constraint = 'teste_status_falha_${mae.id}';
          final destino = concluir ? 'concluida' : 'cancelada';
          await session.db.unsafeExecute(
            'ALTER TABLE "demandas" ADD CONSTRAINT "$constraint" '
            'CHECK ("id" <> ${mae.id!} OR "status" <> \'$destino\')',
          );
          try {
            await expectLater(
              concluir
                  ? endpoints.demanda.concluirDemandaEmCascata(
                      sessionBuilder,
                      mae.id!,
                    )
                  : endpoints.demanda.cancelarDemandaEmCascata(
                      sessionBuilder,
                      mae.id!,
                      'Motivo',
                    ),
              throwsA(isA<Exception>()),
            );
            for (final demanda in [mae, filha, neta]) {
              expect((await ler(demanda)).toJson(), demanda.toJson());
            }
          } finally {
            await session.db.unsafeExecute(
              'ALTER TABLE "demandas" DROP CONSTRAINT "$constraint"',
            );
          }
        },
      );
    }

    test(
      'update e cascata compartilham rollback se a edição de campos falhar',
      () async {
        final mae = await criar('mãe rollback update');
        final filha = await criar('filha', pai: mae.id);
        final session = sessionBuilder.build();
        final constraint = 'teste_status_update_${mae.id}';
        await session.db.unsafeExecute(
          'ALTER TABLE "demandas" ADD CONSTRAINT "$constraint" '
          'CHECK ("id" <> ${mae.id!} OR "titulo" NOT LIKE \'% editada\')',
        );
        try {
          await expectLater(
            editar(mae, DemandaStatus.cancelada, motivo: 'Motivo'),
            throwsA(isA<Exception>()),
          );
          expect((await ler(mae)).toJson(), mae.toJson());
          expect((await ler(filha)).toJson(), filha.toJson());
        } finally {
          await session.db.unsafeExecute(
            'ALTER TABLE "demandas" DROP CONSTRAINT "$constraint"',
          );
        }
      },
    );

    test(
      'edita cancelamento legado sem motivo e exige transição explícita para cancelar filhas',
      () async {
        final mae = await criar('legada', status: DemandaStatus.cancelada);
        final editada = await editar(mae, DemandaStatus.cancelada);
        expect(editada.motivoCancelamento, isNull);
        final filha = await criar('ativa', pai: mae.id);
        final comFilha = await editar(editada, DemandaStatus.cancelada);
        expect(comFilha.titulo, '${editada.titulo} editada');
        expect(comFilha.motivoCancelamento, isNull);
        expect((await ler(filha)).toJson(), filha.toJson());
        await expectLater(
          alterar(comFilha, DemandaStatus.cancelada),
          throwsA(
            erro(TransicaoStatusErroCodigo.motivoCancelamentoObrigatorio),
          ),
        );
        expect((await ler(filha)).status, DemandaStatus.aberta);
        await alterar(
          comFilha,
          DemandaStatus.cancelada,
          motivo: 'Cancelamento da árvore',
        );
        expect((await ler(filha)).motivoCancelamento, 'Cancelamento da árvore');
      },
    );

    test(
      'transições ativas não propagam status nem impõem novas restrições',
      () async {
        final mae = await criar(
          'mãe',
          status: DemandaStatus.cancelada,
          motivo: 'Anterior',
        );
        final filha = await criar(
          'filha',
          pai: mae.id,
          status: DemandaStatus.concluida,
        );
        for (final status in [
          DemandaStatus.aberta,
          DemandaStatus.emAndamento,
          DemandaStatus.pausada,
        ]) {
          final atualizada = await alterar(mae, status);
          expect(atualizada.status, status);
          expect(atualizada.motivoCancelamento, 'Anterior');
          expect((await ler(filha)).toJson(), filha.toJson());
        }
      },
    );
  }, rollbackDatabase: RollbackDatabase.disabled);
}
