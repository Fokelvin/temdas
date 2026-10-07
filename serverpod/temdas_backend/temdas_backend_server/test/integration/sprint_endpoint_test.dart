import 'package:temdas_backend_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';
import 'test_tools/authenticated_test_user.dart';

Matcher throwsSprint(SprintErroCodigo codigo) => throwsA(
  isA<SprintException>().having((erro) => erro.codigo, 'codigo', codigo),
);

void main() {
  final prefixo = 'teste-sprint-${DateTime.now().microsecondsSinceEpoch}';

  withServerpod('Base de domínio de sprint', (sessionBuilder, endpoints) {
    setUp(() => installAal2TestUser(sessionBuilder, 'sprint-regression-owner'));
    tearDown(clearAal2TestUser);
    tearDown(() async {
      final session = sessionBuilder.build();
      await Sprint.db.deleteWhere(
        session,
        where: (t) => t.nome.like('$prefixo%'),
      );
      await Demanda.db.deleteWhere(
        session,
        where: (t) => t.titulo.like('$prefixo%'),
      );
    });

    test(
      'cria planejada com nome e datas de calendário normalizados',
      () async {
        final sprint = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '  Sprint $prefixo planejamento  ',
            dataInicio: DateTime(2026, 10, 5, 16),
            dataFim: DateTime(2026, 10, 16, 9),
          ),
        );

        expect(sprint.nome, '$prefixo planejamento');
        expect(sprint.nomeNormalizado, '$prefixo planejamento');
        expect(sprint.dataInicio, DateTime.utc(2026, 10, 5));
        expect(sprint.dataFim, DateTime.utc(2026, 10, 16));
        expect(sprint.tempoPrevistoMinutos, isNull);
        expect(sprint.status, SprintStatus.planejada);
      },
    );

    test('lista sprints por início mais recente e desempata por ID', () async {
      Future<Sprint> criar(String nome, DateTime inicio, DateTime fim) =>
          endpoints.sprint.criarSprint(
            sessionBuilder,
            SprintCreateRequest(
              nome: '$prefixo $nome',
              dataInicio: inicio,
              dataFim: fim,
            ),
          );

      final antiga = await criar(
        'lista antiga',
        DateTime.utc(2300, 1, 1),
        DateTime.utc(2300, 1, 2),
      );
      final recente = await criar(
        'lista recente',
        DateTime.utc(2300, 2, 1),
        DateTime.utc(2300, 2, 2),
      );
      final empateMaisAntiga = await criar(
        'lista empate antiga',
        DateTime.utc(2300, 3, 1),
        DateTime.utc(2300, 3, 2),
      );
      final empateMaisNova = await criar(
        'lista empate nova',
        DateTime.utc(2300, 3, 3),
        DateTime.utc(2300, 3, 4),
      );
      await endpoints.sprint.cancelarSprint(
        sessionBuilder,
        empateMaisAntiga.id!,
      );
      await endpoints.sprint.cancelarSprint(
        sessionBuilder,
        empateMaisNova.id!,
      );
      final session = sessionBuilder.build();
      for (final sprint in [empateMaisAntiga, empateMaisNova]) {
        await Sprint.db.updateById(
          session,
          sprint.id!,
          columnValues: (t) => [
            t.dataInicio(DateTime.utc(2300, 3, 1)),
            t.dataFim(DateTime.utc(2300, 3, 2)),
          ],
        );
      }

      final idsListados = (await endpoints.sprint.listarSprints(sessionBuilder))
          .where((sprint) => sprint.nome.startsWith('$prefixo lista'))
          .map((sprint) => sprint.id)
          .toList();
      expect(idsListados, [
        empateMaisNova.id,
        empateMaisAntiga.id,
        recente.id,
        antiga.id,
      ]);
    });

    test('busca por ID e lista somente vínculos atuais da sprint', () async {
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo leitura vínculos',
          dataInicio: DateTime.utc(2301, 1, 1),
          dataFim: DateTime.utc(2301, 1, 5),
        ),
      );
      final demanda = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo leitura demanda',
          tempoEstimadoMinutos: 30,
        ),
      );

      expect(
        (await endpoints.sprint.buscarSprintPorId(
          sessionBuilder,
          sprint.id!,
        )).id,
        sprint.id,
      );
      await expectLater(
        endpoints.sprint.buscarSprintPorId(sessionBuilder, -1),
        throwsSprint(SprintErroCodigo.sprintNaoEncontrada),
      );

      await endpoints.sprint.vincularDemanda(
        sessionBuilder,
        sprint.id!,
        demanda.id!,
      );
      final atuais = await endpoints.sprint.listarDemandasDaSprint(
        sessionBuilder,
        sprint.id!,
      );
      expect(atuais.map((vinculo) => vinculo.demandaId), [demanda.id]);

      await endpoints.sprint.desvincularDemanda(
        sessionBuilder,
        sprint.id!,
        demanda.id!,
      );
      expect(
        await endpoints.sprint.listarDemandasDaSprint(
          sessionBuilder,
          sprint.id!,
        ),
        isEmpty,
      );
      await expectLater(
        endpoints.sprint.listarDemandasDaSprint(sessionBuilder, -1),
        throwsSprint(SprintErroCodigo.sprintNaoEncontrada),
      );
    });

    test(
      'valida nome, período, tempo e unicidade sem diferenciar maiúsculas',
      () async {
        final nome = '$prefixo única';
        await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: nome,
            dataInicio: DateTime.utc(2026, 10, 5),
            dataFim: DateTime.utc(2026, 10, 16),
            tempoPrevistoMinutos: 480,
          ),
        );

        await expectLater(
          endpoints.sprint.criarSprint(
            sessionBuilder,
            SprintCreateRequest(
              nome: ' ${nome.toUpperCase()} ',
              dataInicio: DateTime.utc(2026, 10, 20),
              dataFim: DateTime.utc(2026, 10, 24),
            ),
          ),
          throwsSprint(SprintErroCodigo.nomeDuplicado),
        );
        await expectLater(
          endpoints.sprint.criarSprint(
            sessionBuilder,
            SprintCreateRequest(
              nome: '   ',
              dataInicio: DateTime.utc(2026, 10, 5),
              dataFim: DateTime.utc(2026, 10, 16),
            ),
          ),
          throwsSprint(SprintErroCodigo.nomeObrigatorio),
        );
        await expectLater(
          endpoints.sprint.criarSprint(
            sessionBuilder,
            SprintCreateRequest(
              nome: '$prefixo período inválido',
              dataInicio: DateTime.utc(2026, 10, 17),
              dataFim: DateTime.utc(2026, 10, 16),
            ),
          ),
          throwsSprint(SprintErroCodigo.periodoInvalido),
        );
        await expectLater(
          endpoints.sprint.criarSprint(
            sessionBuilder,
            SprintCreateRequest(
              nome: '$prefixo tempo inválido',
              dataInicio: DateTime.utc(2026, 10, 5),
              dataFim: DateTime.utc(2026, 10, 16),
              tempoPrevistoMinutos: -1,
            ),
          ),
          throwsSprint(SprintErroCodigo.tempoPrevistoInvalido),
        );
      },
    );

    test('impede associação duplicada entre a sprint e a demanda', () async {
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo associação',
          dataInicio: DateTime.utc(2026, 10, 5),
          dataFim: DateTime.utc(2026, 10, 16),
        ),
      );
      final demanda = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo demanda',
          tempoEstimadoMinutos: 60,
        ),
      );
      final session = sessionBuilder.build();
      await SprintDemanda.db.insertRow(
        session,
        SprintDemanda(sprintId: sprint.id!, demandaId: demanda.id!),
      );

      await expectLater(
        SprintDemanda.db.insertRow(
          session,
          SprintDemanda(sprintId: sprint.id!, demandaId: demanda.id!),
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('permite o ciclo planejada, ativa, cancelada e planejada', () async {
      final hoje = _hojeUtc();
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo ciclo',
          dataInicio: hoje,
          dataFim: hoje.add(const Duration(days: 5)),
          tempoPrevistoMinutos: 60,
        ),
      );

      final ativa = await endpoints.sprint.ativarSprint(
        sessionBuilder,
        sprint.id!,
      );
      expect(ativa.status, SprintStatus.ativa);

      final cancelada = await endpoints.sprint.cancelarSprint(
        sessionBuilder,
        sprint.id!,
      );
      expect(cancelada.status, SprintStatus.cancelada);

      final reaberta = await endpoints.sprint.reabrirSprint(
        sessionBuilder,
        sprint.id!,
      );
      expect(reaberta.status, SprintStatus.planejada);
    });

    test(
      'recusa ativação antes do início ou sem tempo previsto positivo',
      () async {
        final hoje = _hojeUtc();
        final futura = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo futura',
            dataInicio: hoje.add(const Duration(days: 10)),
            dataFim: hoje.add(const Duration(days: 15)),
            tempoPrevistoMinutos: 60,
          ),
        );
        final semTempo = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo sem tempo',
            dataInicio: hoje,
            dataFim: hoje.add(const Duration(days: 5)),
          ),
        );

        await expectLater(
          endpoints.sprint.ativarSprint(sessionBuilder, futura.id!),
          throwsSprint(SprintErroCodigo.inicioAntesDataInicio),
        );
        await expectLater(
          endpoints.sprint.ativarSprint(sessionBuilder, semTempo.id!),
          throwsSprint(SprintErroCodigo.tempoPrevistoInvalido),
        );
      },
    );

    test('não reabre sprint concluída', () async {
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo concluída',
          dataInicio: DateTime.utc(2026, 12, 1),
          dataFim: DateTime.utc(2026, 12, 5),
        ),
      );
      final session = sessionBuilder.build();
      await Sprint.db.updateById(
        session,
        sprint.id!,
        columnValues: (t) => [t.status(SprintStatus.concluida)],
      );

      await expectLater(
        endpoints.sprint.reabrirSprint(sessionBuilder, sprint.id!),
        throwsSprint(SprintErroCodigo.transicaoStatusInvalida),
      );
    });

    test(
      'trata limites iguais como sobreposição e cancelada não bloqueia',
      () async {
        final primeira = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo primeira inclusiva',
            dataInicio: DateTime.utc(2026, 11, 5),
            dataFim: DateTime.utc(2026, 11, 10),
          ),
        );

        await expectLater(
          endpoints.sprint.criarSprint(
            sessionBuilder,
            SprintCreateRequest(
              nome: '$prefixo segunda inclusiva',
              dataInicio: DateTime.utc(2026, 11, 10),
              dataFim: DateTime.utc(2026, 11, 12),
            ),
          ),
          throwsSprint(SprintErroCodigo.periodoSobreposto),
        );

        await endpoints.sprint.cancelarSprint(sessionBuilder, primeira.id!);
        final segunda = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo segunda inclusiva',
            dataInicio: DateTime.utc(2026, 11, 10),
            dataFim: DateTime.utc(2026, 11, 12),
          ),
        );
        expect(segunda.status, SprintStatus.planejada);
      },
    );

    test(
      'valida sobreposição na edição e ao reabrir sprint cancelada',
      () async {
        await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo base',
            dataInicio: DateTime.utc(2026, 11, 5),
            dataFim: DateTime.utc(2026, 11, 10),
          ),
        );
        final cancelada = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo editável',
            dataInicio: DateTime.utc(2026, 11, 11),
            dataFim: DateTime.utc(2026, 11, 15),
          ),
        );

        await expectLater(
          endpoints.sprint.atualizarSprint(
            sessionBuilder,
            SprintUpdateRequest(
              id: cancelada.id!,
              nome: cancelada.nome,
              dataInicio: DateTime.utc(2026, 11, 10),
              dataFim: DateTime.utc(2026, 11, 15),
              tempoPrevistoMinutos: null,
            ),
          ),
          throwsA(isA<Exception>()),
        );

        await endpoints.sprint.cancelarSprint(sessionBuilder, cancelada.id!);
        final editada = await endpoints.sprint.atualizarSprint(
          sessionBuilder,
          SprintUpdateRequest(
            id: cancelada.id!,
            nome: cancelada.nome,
            dataInicio: DateTime.utc(2026, 11, 10),
            dataFim: DateTime.utc(2026, 11, 15),
            tempoPrevistoMinutos: null,
          ),
        );
        expect(editada.status, SprintStatus.cancelada);
        await expectLater(
          endpoints.sprint.reabrirSprint(sessionBuilder, editada.id!),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('impede mais de uma sprint ativa', () async {
      final hoje = _hojeUtc();
      final primeira = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo ativa um',
          dataInicio: hoje.subtract(const Duration(days: 20)),
          dataFim: hoje.subtract(const Duration(days: 15)),
          tempoPrevistoMinutos: 60,
        ),
      );
      final segunda = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo ativa dois',
          dataInicio: hoje.subtract(const Duration(days: 10)),
          dataFim: hoje.subtract(const Duration(days: 5)),
          tempoPrevistoMinutos: 60,
        ),
      );

      await endpoints.sprint.ativarSprint(sessionBuilder, primeira.id!);
      await expectLater(
        endpoints.sprint.ativarSprint(sessionBuilder, segunda.id!),
        throwsSprint(SprintErroCodigo.sprintAtivaExistente),
      );
    });

    test('serializa ativações concorrentes', () async {
      final hoje = _hojeUtc();
      final primeira = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo concorrente um',
          dataInicio: hoje.subtract(const Duration(days: 20)),
          dataFim: hoje.subtract(const Duration(days: 15)),
          tempoPrevistoMinutos: 60,
        ),
      );
      final segunda = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo concorrente dois',
          dataInicio: hoje.subtract(const Duration(days: 10)),
          dataFim: hoje.subtract(const Duration(days: 5)),
          tempoPrevistoMinutos: 60,
        ),
      );

      Future<Object> tentarAtivar(int id) async {
        try {
          return await endpoints.sprint.ativarSprint(sessionBuilder, id);
        } catch (erro) {
          return erro;
        }
      }

      final resultados = await Future.wait([
        tentarAtivar(primeira.id!),
        tentarAtivar(segunda.id!),
      ]);
      expect(resultados.whereType<Sprint>(), hasLength(1));

      final ativas = await Sprint.db.find(
        sessionBuilder.build(),
        where: (t) => t.status.equals(SprintStatus.ativa),
      );
      expect(ativas, hasLength(1));
    });

    test('constraints do banco protegem período e sprint ativa', () async {
      final session = sessionBuilder.build();
      final usuario = await Usuario.db.findFirstRow(
        session,
        where: (t) => t.supabaseUserId.equals('sprint-regression-owner'),
      );
      Future<Sprint> inserir({
        required String sufixo,
        required DateTime inicio,
        required DateTime fim,
        required SprintStatus status,
      }) => Sprint.db.insertRow(
        session,
        Sprint(
          usuarioId: usuario!.id!,
          nome: '$prefixo banco $sufixo',
          nomeNormalizado: '$prefixo banco $sufixo'.toLowerCase(),
          dataInicio: inicio,
          dataFim: fim,
          status: status,
        ),
      );

      await inserir(
        sufixo: 'base',
        inicio: DateTime.utc(2026, 12, 1),
        fim: DateTime.utc(2026, 12, 5),
        status: SprintStatus.planejada,
      );
      await expectLater(
        inserir(
          sufixo: 'sobreposta',
          inicio: DateTime.utc(2026, 12, 5),
          fim: DateTime.utc(2026, 12, 8),
          status: SprintStatus.planejada,
        ),
        throwsA(isA<Exception>()),
      );
      await inserir(
        sufixo: 'ativa um',
        inicio: DateTime.utc(2027, 1, 1),
        fim: DateTime.utc(2027, 1, 5),
        status: SprintStatus.ativa,
      );
      await expectLater(
        inserir(
          sufixo: 'ativa dois',
          inicio: DateTime.utc(2027, 1, 10),
          fim: DateTime.utc(2027, 1, 15),
          status: SprintStatus.ativa,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('triggers do banco protegem vínculo aberto e reabertura', () async {
      final session = sessionBuilder.build();
      final demanda = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo trigger demanda',
          tempoEstimadoMinutos: 60,
        ),
      );
      Future<Sprint> inserirSprint(
        String sufixo,
        DateTime inicio,
        DateTime fim,
        SprintStatus status,
      ) => Sprint.db.insertRow(
        session,
        Sprint(
          usuarioId: demanda.usuarioId,
          nome: '$prefixo trigger $sufixo',
          nomeNormalizado: '$prefixo trigger $sufixo'.toLowerCase(),
          dataInicio: inicio,
          dataFim: fim,
          status: status,
        ),
      );

      final cancelada = await inserirSprint(
        'cancelada',
        DateTime.utc(2027, 1, 20),
        DateTime.utc(2027, 1, 25),
        SprintStatus.planejada,
      );
      await SprintDemanda.db.insertRow(
        session,
        SprintDemanda(sprintId: cancelada.id!, demandaId: demanda.id!),
      );
      await Sprint.db.updateById(
        session,
        cancelada.id!,
        columnValues: (t) => [t.status(SprintStatus.cancelada)],
      );

      final aberta = await inserirSprint(
        'aberta',
        DateTime.utc(2027, 2, 1),
        DateTime.utc(2027, 2, 5),
        SprintStatus.planejada,
      );
      await SprintDemanda.db.insertRow(
        session,
        SprintDemanda(sprintId: aberta.id!, demandaId: demanda.id!),
      );
      final outraAberta = await inserirSprint(
        'outra aberta',
        DateTime.utc(2027, 2, 6),
        DateTime.utc(2027, 2, 10),
        SprintStatus.planejada,
      );

      await expectLater(
        SprintDemanda.db.insertRow(
          session,
          SprintDemanda(sprintId: outraAberta.id!, demandaId: demanda.id!),
        ),
        throwsA(isA<Exception>()),
      );
      await expectLater(
        Sprint.db.updateById(
          session,
          cancelada.id!,
          columnValues: (t) => [t.status(SprintStatus.planejada)],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('vincula e desvincula uma árvore inteira de demandas', () async {
      final raiz = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo árvore raiz',
          tempoEstimadoMinutos: 60,
        ),
      );
      final filha = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          demandaPaiId: raiz.id,
          titulo: '$prefixo árvore filha',
          tempoEstimadoMinutos: 60,
        ),
      );
      final neta = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          demandaPaiId: filha.id,
          titulo: '$prefixo árvore neta',
          tempoEstimadoMinutos: 60,
        ),
      );
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo árvore',
          dataInicio: DateTime.utc(2027, 2, 1),
          dataFim: DateTime.utc(2027, 2, 5),
        ),
      );

      final vinculos = await endpoints.sprint.vincularDemanda(
        sessionBuilder,
        sprint.id!,
        raiz.id!,
      );
      expect(
        vinculos.map((vinculo) => vinculo.demandaId).toSet(),
        {raiz.id, filha.id, neta.id},
      );

      await expectLater(
        endpoints.sprint.desvincularDemanda(
          sessionBuilder,
          sprint.id!,
          filha.id!,
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        await endpoints.sprint.desvincularDemanda(
          sessionBuilder,
          sprint.id!,
          raiz.id!,
        ),
        isTrue,
      );
      expect(
        await SprintDemanda.db.find(
          sessionBuilder.build(),
          where: (t) => t.sprintId.equals(sprint.id!),
        ),
        isEmpty,
      );
    });

    test('vincula várias Demandas em uma transação única', () async {
      final primeira = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo lote primeira',
          tempoEstimadoMinutos: 30,
        ),
      );
      final segunda = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo lote segunda',
          tempoEstimadoMinutos: 60,
        ),
      );
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo lote',
          dataInicio: DateTime.utc(2027, 2, 10),
          dataFim: DateTime.utc(2027, 2, 12),
        ),
      );

      final vinculos = await endpoints.sprint.vincularDemandas(
        sessionBuilder,
        sprint.id!,
        [primeira.id!, segunda.id!],
      );
      expect(
        vinculos.map((vinculo) => vinculo.demandaId).toSet(),
        {primeira.id, segunda.id},
      );

      final sprintComRollback = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo lote rollback',
          dataInicio: DateTime.utc(2027, 2, 20),
          dataFim: DateTime.utc(2027, 2, 22),
        ),
      );
      final demandaRollback = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo lote rollback demanda',
          tempoEstimadoMinutos: 30,
        ),
      );
      await expectLater(
        endpoints.sprint.vincularDemandas(
          sessionBuilder,
          sprintComRollback.id!,
          [demandaRollback.id!, -999999],
        ),
        throwsSprint(SprintErroCodigo.demandaNaoEncontrada),
      );
      expect(
        await SprintDemanda.db.find(
          sessionBuilder.build(),
          where: (t) => t.sprintId.equals(sprintComRollback.id!),
        ),
        isEmpty,
      );
    });

    test('bloqueia vínculo direto de filha sem a mãe na sprint', () async {
      final raiz = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo direta raiz',
          tempoEstimadoMinutos: 60,
        ),
      );
      final filha = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          demandaPaiId: raiz.id,
          titulo: '$prefixo direta filha',
          tempoEstimadoMinutos: 60,
        ),
      );
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo direta',
          dataInicio: DateTime.utc(2027, 3, 1),
          dataFim: DateTime.utc(2027, 3, 5),
        ),
      );

      await expectLater(
        endpoints.sprint.vincularDemanda(
          sessionBuilder,
          sprint.id!,
          filha.id!,
        ),
        throwsSprint(SprintErroCodigo.demandaFilhaSemMae),
      );
    });

    test('nova filha herda a sprint aberta da demanda mãe', () async {
      final raiz = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo herança raiz',
          tempoEstimadoMinutos: 60,
        ),
      );
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo herança',
          dataInicio: DateTime.utc(2027, 4, 1),
          dataFim: DateTime.utc(2027, 4, 5),
        ),
      );
      await endpoints.sprint.vincularDemanda(
        sessionBuilder,
        sprint.id!,
        raiz.id!,
      );

      final filha = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          demandaPaiId: raiz.id,
          titulo: '$prefixo herança filha',
          tempoEstimadoMinutos: 60,
        ),
      );
      final vinculo = await SprintDemanda.db.findFirstRow(
        sessionBuilder.build(),
        where: (t) =>
            t.sprintId.equals(sprint.id!) & t.demandaId.equals(filha.id!),
      );
      expect(vinculo, isNotNull);
    });

    test(
      'preserva histórico concluído e impede duas sprints abertas',
      () async {
        final demanda = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          DemandaCreateRequest(
            titulo: '$prefixo histórico demanda',
            tempoEstimadoMinutos: 60,
          ),
        );
        final concluida = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo histórico concluída',
            dataInicio: DateTime.utc(2027, 5, 1),
            dataFim: DateTime.utc(2027, 5, 5),
          ),
        );
        await endpoints.sprint.vincularDemanda(
          sessionBuilder,
          concluida.id!,
          demanda.id!,
        );
        await Sprint.db.updateById(
          sessionBuilder.build(),
          concluida.id!,
          columnValues: (t) => [t.status(SprintStatus.concluida)],
        );

        final aberta = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo histórico aberta',
            dataInicio: DateTime.utc(2027, 5, 10),
            dataFim: DateTime.utc(2027, 5, 15),
          ),
        );
        await endpoints.sprint.vincularDemanda(
          sessionBuilder,
          aberta.id!,
          demanda.id!,
        );
        await expectLater(
          endpoints.sprint.desvincularDemanda(
            sessionBuilder,
            concluida.id!,
            demanda.id!,
          ),
          throwsSprint(SprintErroCodigo.vinculoStatusProibido),
        );
      },
    );

    test(
      'serializa vínculos concorrentes em sprints abertas distintas',
      () async {
        final demanda = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          DemandaCreateRequest(
            titulo: '$prefixo concorrência demanda',
            tempoEstimadoMinutos: 60,
          ),
        );
        final primeira = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo concorrência um',
            dataInicio: DateTime.utc(2027, 6, 1),
            dataFim: DateTime.utc(2027, 6, 5),
          ),
        );
        final segunda = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo concorrência dois',
            dataInicio: DateTime.utc(2027, 6, 10),
            dataFim: DateTime.utc(2027, 6, 15),
          ),
        );

        Future<Object> tentarVincular(int sprintId) async {
          try {
            return await endpoints.sprint.vincularDemanda(
              sessionBuilder,
              sprintId,
              demanda.id!,
            );
          } catch (erro) {
            return erro;
          }
        }

        final resultados = await Future.wait([
          tentarVincular(primeira.id!),
          tentarVincular(segunda.id!),
        ]);
        expect(resultados.whereType<List<SprintDemanda>>(), hasLength(1));
        final vinculos = await SprintDemanda.db.find(
          sessionBuilder.build(),
          where: (t) => t.demandaId.equals(demanda.id!),
        );
        expect(vinculos, hasLength(1));
      },
    );

    test('informa código ao vincular Demanda em outra Sprint aberta', () async {
      final demanda = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo conflito sprint aberta',
          tempoEstimadoMinutos: 60,
        ),
      );
      final primeira = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo conflito primeira',
          dataInicio: DateTime.utc(2027, 6, 20),
          dataFim: DateTime.utc(2027, 6, 22),
        ),
      );
      final segunda = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo conflito segunda',
          dataInicio: DateTime.utc(2027, 6, 23),
          dataFim: DateTime.utc(2027, 6, 25),
        ),
      );
      await endpoints.sprint.vincularDemanda(
        sessionBuilder,
        primeira.id!,
        demanda.id!,
      );
      await expectLater(
        endpoints.sprint.vincularDemanda(
          sessionBuilder,
          segunda.id!,
          demanda.id!,
        ),
        throwsSprint(SprintErroCodigo.demandaOutraSprintAberta),
      );
    });

    test(
      'conclui manualmente, preserva histórico e calcula indicadores dinâmicos',
      () async {
        final hoje = _hojeUtc();
        final sprint = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo conclusão e indicadores',
            dataInicio: hoje,
            dataFim: hoje.add(const Duration(days: 1)),
            tempoPrevistoMinutos: 120,
          ),
        );
        final raiz = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          DemandaCreateRequest(
            titulo: '$prefixo indicador raiz',
            tempoEstimadoMinutos: 60,
          ),
        );
        final filha = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          DemandaCreateRequest(
            demandaPaiId: raiz.id,
            titulo: '$prefixo indicador filha',
            tempoEstimadoMinutos: 30,
          ),
        );
        await endpoints.sprint.vincularDemanda(
          sessionBuilder,
          sprint.id!,
          raiz.id!,
        );

        final session = sessionBuilder.build();
        await RegistroTempo.db.insertRow(
          session,
          RegistroTempo(
            demandaId: raiz.id!,
            inicioEm: hoje.add(const Duration(hours: 9)),
            duracaoMinutos: 45,
            criadoEm: hoje,
          ),
        );
        await RegistroTempo.db.insertRow(
          session,
          RegistroTempo(
            demandaId: filha.id!,
            inicioEm: hoje.add(const Duration(days: 1, hours: 10)),
            duracaoMinutos: 30,
            criadoEm: hoje,
          ),
        );
        await RegistroTempo.db.insertRow(
          session,
          RegistroTempo(
            demandaId: filha.id!,
            inicioEm: hoje.add(const Duration(days: 2, hours: 9)),
            duracaoMinutos: 90,
            criadoEm: hoje,
          ),
        );

        await endpoints.sprint.ativarSprint(sessionBuilder, sprint.id!);
        final resumo = await endpoints.sprint.obterResumoConclusaoSprint(
          sessionBuilder,
          sprint.id!,
        );
        expect(resumo.quantidadeDemandasNaoConcluidas, 2);
        expect(resumo.indicadores.tempoExecutadoMinutos, 75);
        final conclusao = await endpoints.sprint.concluirSprint(
          sessionBuilder,
          sprint.id!,
        );

        expect(conclusao.sprint.status, SprintStatus.concluida);
        expect(conclusao.quantidadeDemandasNaoConcluidas, 2);
        expect(conclusao.indicadores.tempoPrevistoMinutos, 120);
        expect(conclusao.indicadores.tempoTotalEstimadoMinutos, 90);
        expect(conclusao.indicadores.tempoExecutadoMinutos, 75);
        expect(conclusao.indicadores.diferencaExecutadoEstimadoMinutos, -15);
        expect(
          await SprintDemanda.db.find(
            sessionBuilder.build(),
            where: (t) => t.sprintId.equals(sprint.id!),
          ),
          hasLength(2),
        );

        await RegistroTempo.db.insertRow(
          session,
          RegistroTempo(
            demandaId: raiz.id!,
            inicioEm: hoje.add(const Duration(hours: 14)),
            duracaoMinutos: 15,
            criadoEm: hoje,
          ),
        );
        final dinamicos = await endpoints.sprint.calcularIndicadoresSprint(
          sessionBuilder,
          sprint.id!,
        );
        expect(dinamicos.tempoExecutadoMinutos, 90);
      },
    );

    test('só permite concluir sprint ativa', () async {
      final hoje = _hojeUtc();
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo conclusão inválida',
          dataInicio: hoje,
          dataFim: hoje,
          tempoPrevistoMinutos: 60,
        ),
      );

      await expectLater(
        endpoints.sprint.concluirSprint(sessionBuilder, sprint.id!),
        throwsSprint(SprintErroCodigo.transicaoStatusInvalida),
      );
    });

    test(
      'cancelamento remove vínculos sem alterar demandas ou registros',
      () async {
        final demanda = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          DemandaCreateRequest(
            titulo: '$prefixo cancelamento demanda',
            tempoEstimadoMinutos: 60,
          ),
        );
        final sprint = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo cancelamento',
            dataInicio: DateTime.utc(2027, 7, 1),
            dataFim: DateTime.utc(2027, 7, 5),
          ),
        );
        await endpoints.sprint.vincularDemanda(
          sessionBuilder,
          sprint.id!,
          demanda.id!,
        );
        final registro = await RegistroTempo.db.insertRow(
          sessionBuilder.build(),
          RegistroTempo(
            demandaId: demanda.id!,
            inicioEm: DateTime.utc(2027, 7, 1, 9),
            duracaoMinutos: 30,
            criadoEm: DateTime.utc(2027, 7, 1),
          ),
        );

        final cancelada = await endpoints.sprint.cancelarSprint(
          sessionBuilder,
          sprint.id!,
        );

        final sprintSeguinte = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo cancelamento seguinte',
            dataInicio: DateTime.utc(2027, 7, 6),
            dataFim: DateTime.utc(2027, 7, 10),
          ),
        );
        await endpoints.sprint.vincularDemanda(
          sessionBuilder,
          sprintSeguinte.id!,
          demanda.id!,
        );

        expect(cancelada.status, SprintStatus.cancelada);
        expect(
          await SprintDemanda.db.find(
            sessionBuilder.build(),
            where: (t) => t.sprintId.equals(sprint.id!),
          ),
          isEmpty,
        );
        expect(
          await Demanda.db.findById(sessionBuilder.build(), demanda.id!),
          isNotNull,
        );
        expect(
          await RegistroTempo.db.findById(sessionBuilder.build(), registro.id!),
          isNotNull,
        );
        expect(
          await SprintDemanda.db.find(
            sessionBuilder.build(),
            where: (t) =>
                t.sprintId.equals(sprintSeguinte.id!) &
                t.demandaId.equals(demanda.id!),
          ),
          hasLength(1),
        );
      },
    );

    test(
      'calcula somente registros no período inclusivo da sprint',
      () async {
        final inicio = DateTime.utc(2027, 9, 10);
        final fim = DateTime.utc(2027, 9, 12);
        final sprint = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo período inclusivo',
            dataInicio: inicio,
            dataFim: fim,
          ),
        );
        final demanda = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          DemandaCreateRequest(
            titulo: '$prefixo período inclusivo demanda',
            tempoEstimadoMinutos: 60,
          ),
        );
        await endpoints.sprint.vincularDemanda(
          sessionBuilder,
          sprint.id!,
          demanda.id!,
        );

        final session = sessionBuilder.build();
        for (final registro in [
          RegistroTempo(
            demandaId: demanda.id!,
            inicioEm: inicio.subtract(const Duration(minutes: 1)),
            duracaoMinutos: 1,
            criadoEm: inicio,
          ),
          RegistroTempo(
            demandaId: demanda.id!,
            inicioEm: inicio,
            duracaoMinutos: 10,
            criadoEm: inicio,
          ),
          RegistroTempo(
            demandaId: demanda.id!,
            inicioEm: fim.add(const Duration(hours: 23, minutes: 59)),
            duracaoMinutos: 20,
            criadoEm: fim,
          ),
          RegistroTempo(
            demandaId: demanda.id!,
            inicioEm: fim.add(const Duration(days: 1)),
            duracaoMinutos: 40,
            criadoEm: fim,
          ),
        ]) {
          await RegistroTempo.db.insertRow(session, registro);
        }

        final indicadores = await endpoints.sprint.calcularIndicadoresSprint(
          sessionBuilder,
          sprint.id!,
        );
        expect(indicadores.tempoExecutadoMinutos, 30);
      },
    );

    test('exclusão explícita da sprint preserva as demandas', () async {
      final demanda = await endpoints.demanda.criarDemanda(
        sessionBuilder,
        DemandaCreateRequest(
          titulo: '$prefixo excluir sprint demanda',
          tempoEstimadoMinutos: 60,
        ),
      );
      final sprint = await endpoints.sprint.criarSprint(
        sessionBuilder,
        SprintCreateRequest(
          nome: '$prefixo excluir sprint',
          dataInicio: DateTime.utc(2027, 8, 1),
          dataFim: DateTime.utc(2027, 8, 5),
        ),
      );
      await endpoints.sprint.vincularDemanda(
        sessionBuilder,
        sprint.id!,
        demanda.id!,
      );

      expect(
        await endpoints.sprint.excluirSprint(sessionBuilder, sprint.id!),
        isTrue,
      );
      expect(
        await Sprint.db.findById(sessionBuilder.build(), sprint.id!),
        isNull,
      );
      expect(
        await Demanda.db.findById(sessionBuilder.build(), demanda.id!),
        isNotNull,
      );
      expect(
        await SprintDemanda.db.find(
          sessionBuilder.build(),
          where: (t) => t.demandaId.equals(demanda.id!),
        ),
        isEmpty,
      );
    });

    test(
      'bloqueia exclusão de folha e árvore com histórico concluído',
      () async {
        final hoje = _hojeUtc();
        final raiz = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          DemandaCreateRequest(
            titulo: '$prefixo histórico exclusão raiz',
            tempoEstimadoMinutos: 60,
          ),
        );
        final filha = await endpoints.demanda.criarDemanda(
          sessionBuilder,
          DemandaCreateRequest(
            demandaPaiId: raiz.id,
            titulo: '$prefixo histórico exclusão filha',
            tempoEstimadoMinutos: 60,
          ),
        );
        final sprint = await endpoints.sprint.criarSprint(
          sessionBuilder,
          SprintCreateRequest(
            nome: '$prefixo histórico exclusão',
            dataInicio: hoje.subtract(const Duration(days: 4)),
            dataFim: hoje.subtract(const Duration(days: 2)),
            tempoPrevistoMinutos: 60,
          ),
        );
        await endpoints.sprint.vincularDemanda(
          sessionBuilder,
          sprint.id!,
          raiz.id!,
        );
        await endpoints.sprint.ativarSprint(sessionBuilder, sprint.id!);
        await endpoints.sprint.concluirSprint(sessionBuilder, sprint.id!);

        await expectLater(
          endpoints.demanda.excluirDemanda(sessionBuilder, filha.id!),
          throwsSprint(SprintErroCodigo.historicoSprintConcluida),
        );
        await expectLater(
          endpoints.demanda.excluirArvoreDemanda(sessionBuilder, raiz.id!),
          throwsSprint(SprintErroCodigo.historicoSprintConcluida),
        );
        expect(
          await Demanda.db.findById(sessionBuilder.build(), raiz.id!),
          isNotNull,
        );
        expect(
          await Demanda.db.findById(sessionBuilder.build(), filha.id!),
          isNotNull,
        );
        await expectLater(
          Demanda.db.deleteRow(sessionBuilder.build(), filha),
          throwsA(isA<Exception>()),
        );
      },
    );
  });
}

DateTime _hojeUtc() {
  final agora = DateTime.now().toUtc();
  return DateTime.utc(agora.year, agora.month, agora.day);
}
