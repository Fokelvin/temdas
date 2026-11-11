import 'package:serverpod/serverpod.dart';
import 'package:temdas_backend_server/src/auth/supabase_auth_service.dart';
import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:temdas_backend_server/src/sprints/sprint_custom_schema.dart';
import 'package:test/test.dart';

import 'test_tools/authenticated_test_user.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  registerSprintCustomIndexes();
  withServerpod('Backlog de Demandas', (builder, endpoints) {
    const owner = 'backlog-owner';
    const backlog = DemandaLocalizacao.backlog;
    const demandas = DemandaLocalizacao.demandas;

    setUp(() => installAal2TestUser(builder, owner));
    tearDown(clearAal2TestUser);

    Future<Demanda> criar(
      String titulo, {
      Demanda? pai,
      DemandaLocalizacao? local,
    }) => endpoints.demanda.criarDemanda(
      builder,
      DemandaCreateRequest(
        titulo: titulo,
        demandaPaiId: pai?.id,
        localizacao: local,
        tempoEstimadoMinutos: 30,
      ),
    );

    Future<Sprint> vincularSprint(Demanda raiz, int mes) async {
      final sprint = await endpoints.sprint.criarSprint(
        builder,
        SprintCreateRequest(
          nome: 'Sprint $mes',
          dataInicio: DateTime.utc(2025, mes, 1),
          dataFim: DateTime.utc(2025, mes, 15),
          tempoPrevistoMinutos: 60,
        ),
      );
      await endpoints.sprint.vincularDemanda(builder, sprint.id!, raiz.id!);
      return sprint;
    }

    Future<void> mover(
      Demanda raiz,
      DemandaLocalizacao local, [
      List<int> ids = const [],
    ]) => endpoints.demanda.alterarLocalizacao(builder, raiz.id!, local, ids);

    Future<List<Demanda>> listar(DemandaLocalizacao local) =>
        endpoints.demanda.listarDemandas(builder, localizacao: local);

    Matcher erroMovimento(MovimentacaoDemandaErroCodigo codigo) => throwsA(
      isA<MovimentacaoDemandaException>().having(
        (e) => e.codigo,
        'codigo',
        codigo,
      ),
    );

    test(
      'move árvore inteira, preserva status e volta ao concluir a raiz',
      () async {
        final raiz = await criar('Mãe');
        final filha = await criar('Filha', pai: raiz);
        final neta = await criar('Neta', pai: filha);
        await endpoints.demanda.alterarStatusDemanda(
          builder,
          neta.id!,
          DemandaStatus.concluida,
        );
        await endpoints.demanda.cancelarDemandaEmCascata(
          builder,
          raiz.id!,
          'Adiada',
        );
        await expectLater(
          mover(filha, backlog),
          erroMovimento(MovimentacaoDemandaErroCodigo.demandaFilha),
        );
        await mover(raiz, backlog);
        await mover(raiz, backlog);
        expect(await listar(demandas), isEmpty);
        final arvore = await listar(backlog);
        expect(
          arvore.map((d) => d.id),
          unorderedEquals([raiz.id, filha.id, neta.id]),
        );
        expect(
          arvore.map((d) => d.status),
          unorderedEquals([
            DemandaStatus.cancelada,
            DemandaStatus.cancelada,
            DemandaStatus.concluida,
          ]),
        );

        final nova = await criar('Nova filha', pai: filha, local: demandas);
        expect(nova.localizacao, backlog);
        await mover(raiz, demandas);
        await mover(raiz, demandas);
        expect(await listar(backlog), isEmpty);
        await mover(raiz, backlog);
        final concluida = await endpoints.demanda.concluirDemandaEmCascata(
          builder,
          raiz.id!,
        );
        expect(concluida.localizacao, demandas);
        expect(await listar(backlog), isEmpty);
        expect(
          (await listar(demandas)).map((d) => d.id),
          unorderedEquals([raiz.id, filha.id, neta.id, nova.id]),
        );
        await expectLater(
          mover(raiz, backlog),
          erroMovimento(MovimentacaoDemandaErroCodigo.statusTerminal),
        );
      },
    );

    test(
      'confirma vínculos exatos e preserva Sprints históricas e horas',
      () async {
        final raiz = await criar('Projeto');
        final filha = await criar('Trabalho', pai: raiz);
        final concluida = await vincularSprint(raiz, 1);
        await Sprint.db.updateById(
          builder.build(),
          concluida.id!,
          columnValues: (t) => [t.status(SprintStatus.concluida)],
        );
        final cancelada = await vincularSprint(raiz, 2);
        await endpoints.sprint.cancelarSprint(builder, cancelada.id!);
        final ativa = await vincularSprint(raiz, 3);
        await Sprint.db.updateById(
          builder.build(),
          ativa.id!,
          columnValues: (t) => [t.status(SprintStatus.ativa)],
        );
        final antiga = await endpoints.demanda.preverEnvioAoBacklog(
          builder,
          raiz.id!,
        );
        final planejada = await vincularSprint(raiz, 4);
        final registro = await endpoints.registroTempo.registrarTempo(
          builder,
          RegistroTempoCreateRequest(
            demandaId: filha.id!,
            inicioEm: DateTime.utc(2025, 5),
            duracaoMinutos: 30,
          ),
        );

        await expectLater(
          mover(raiz, backlog, antiga.vinculos.map((v) => v.id!).toList()),
          erroMovimento(MovimentacaoDemandaErroCodigo.vinculosAlterados),
        );
        expect(await listar(backlog), isEmpty);
        final previa = await endpoints.demanda.preverEnvioAoBacklog(
          builder,
          raiz.id!,
        );
        expect(
          previa.sprints.map((s) => s.id),
          unorderedEquals([ativa.id, planejada.id]),
        );
        expect(previa.vinculos, hasLength(4));

        await mover(raiz, backlog, previa.vinculos.map((v) => v.id!).toList());
        final vinculos = await SprintDemanda.db.find(builder.build());
        expect(
          vinculos.where((v) => v.demandaId == filha.id).map((v) => v.sprintId),
          unorderedEquals([concluida.id, cancelada.id]),
        );
        expect(
          vinculos.where((v) => v.demandaId == raiz.id).map((v) => v.sprintId),
          unorderedEquals([concluida.id, cancelada.id]),
        );
        expect(
          (await endpoints.registroTempo.listarRegistrosTempoDaDemanda(
            builder,
            filha.id!,
          )).single.id,
          registro.id,
        );
        await expectLater(
          endpoints.sprint.vincularDemandas(builder, planejada.id!, [raiz.id!]),
          throwsA(
            isA<SprintException>().having(
              (e) => e.codigo,
              'codigo',
              SprintErroCodigo.demandaNoBacklog,
            ),
          ),
        );
        await expectLater(
          endpoints.sprint.reabrirSprint(builder, cancelada.id!),
          throwsA(
            isA<SprintException>().having(
              (e) => e.codigo,
              'codigo',
              SprintErroCodigo.demandaNoBacklog,
            ),
          ),
        );
      },
    );

    test(
      'reverte remoção de vínculos se a atualização da árvore falhar',
      () async {
        final session = builder.build();
        // A atualização falha depois do DELETE na mesma transação.
        await session.db.unsafeExecute(
          "ALTER TABLE demandas ADD CONSTRAINT teste_backlog_rollback "
          "CHECK (titulo <> 'Filha do rollback' OR localizacao = 'demandas')",
        );
        final raiz = await criar('Raiz');
        final filha = await criar('Filha do rollback', pai: raiz);
        await vincularSprint(raiz, 5);
        final previa = await endpoints.demanda.preverEnvioAoBacklog(
          builder,
          raiz.id!,
        );
        await expectLater(
          mover(raiz, backlog, previa.vinculos.map((v) => v.id!).toList()),
          throwsA(isA<DatabaseQueryException>()),
        );
        expect(await listar(backlog), isEmpty);
        expect(
          (await listar(demandas)).map((d) => d.id),
          unorderedEquals([raiz.id, filha.id]),
        );
        expect(
          (await endpoints.demanda.preverEnvioAoBacklog(
            builder,
            raiz.id!,
          )).vinculos.map((v) => v.id),
          orderedEquals(previa.vinculos.map((v) => v.id)),
        );
      },
    );

    test(
      'busca por título e ID nas duas páginas com isolamento e AAL2',
      () async {
        final ativa = await criar('Entrega 100%');
        final pendente = await criar('Entrega futura', local: backlog);
        final ambas = await endpoints.demanda.buscarDemandasGlobalmente(
          builder,
          'entrega',
        );
        expect(
          ambas.map((d) => d.id),
          unorderedEquals([ativa.id, pendente.id]),
        );
        expect(
          (await endpoints.demanda.buscarDemandasGlobalmente(
            builder,
            '%',
          )).single.id,
          ativa.id,
        );
        expect(
          (await endpoints.demanda.buscarDemandasGlobalmente(
            builder,
            '${pendente.id}',
          )).first.localizacao,
          backlog,
        );
        await installAal2TestUser(builder, 'backlog-outro');
        expect(
          await endpoints.demanda.buscarDemandasGlobalmente(builder, 'entrega'),
          isEmpty,
        );
        expect(await listar(backlog), isEmpty);
        await expectLater(
          mover(pendente, demandas),
          erroMovimento(MovimentacaoDemandaErroCodigo.demandaNaoEncontrada),
        );

        final usuario = (await Usuario.db.findFirstRow(
          builder.build(),
          where: (t) => t.supabaseUserId.equals(owner),
        ))!;
        setUsuarioResolverForTesting(
          (_) async => AuthenticatedUsuario(usuario, owner, 'aal1'),
        );
        await expectLater(
          endpoints.demanda.buscarDemandasGlobalmente(builder, 'entrega'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.codigo,
              'codigo',
              'aal2Required',
            ),
          ),
        );
      },
    );
  });
}
