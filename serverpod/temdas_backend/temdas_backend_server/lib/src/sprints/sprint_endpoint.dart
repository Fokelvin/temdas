import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'sprint_demanda_service.dart';
import 'sprint_indicadores_service.dart';

class SprintEndpoint extends Endpoint {
  final _demandaService = SprintDemandaService();
  final _indicadoresService = SprintIndicadoresService();

  Future<List<Sprint>> listarSprints(Session session) => Sprint.db.find(
    session,
    orderByList: (t) => [
      Order(column: t.dataInicio, orderDescending: true),
      Order(column: t.id, orderDescending: true),
    ],
  );

  Future<Sprint> buscarSprintPorId(Session session, int id) async {
    final sprint = await Sprint.db.findById(session, id);
    if (sprint == null) {
      throw SprintException(codigo: SprintErroCodigo.sprintNaoEncontrada);
    }
    return sprint;
  }

  Future<List<SprintDemanda>> listarDemandasDaSprint(
    Session session,
    int sprintId,
  ) async {
    final sprint = await Sprint.db.findById(session, sprintId);
    if (sprint == null) {
      throw SprintException(codigo: SprintErroCodigo.sprintNaoEncontrada);
    }
    return SprintDemanda.db.find(
      session,
      where: (t) => t.sprintId.equals(sprintId),
      orderBy: (t) => t.demandaId,
    );
  }

  Future<Sprint> criarSprint(
    Session session,
    SprintCreateRequest request,
  ) async {
    final nome = _normalizarNome(request.nome);
    if (nome.isEmpty) {
      throw SprintException(codigo: SprintErroCodigo.nomeObrigatorio);
    }
    if (request.tempoPrevistoMinutos case final tempo? when tempo < 0) {
      throw SprintException(codigo: SprintErroCodigo.tempoPrevistoInvalido);
    }

    final dataInicio = _normalizarDataCalendario(request.dataInicio);
    final dataFim = _normalizarDataCalendario(request.dataFim);
    if (dataInicio.isAfter(dataFim)) {
      throw SprintException(codigo: SprintErroCodigo.periodoInvalido);
    }

    return session.db.transaction((transaction) async {
      await _bloquearCicloDeVida(session, transaction);
      final nomeNormalizado = nome.toLowerCase();
      await _validarNomeUnico(session, nomeNormalizado, transaction);
      await _validarSemSobreposicao(
        session,
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: SprintStatus.planejada,
        transaction: transaction,
      );

      return Sprint.db.insertRow(
        session,
        Sprint(
          nome: nome,
          nomeNormalizado: nomeNormalizado,
          dataInicio: dataInicio,
          dataFim: dataFim,
          tempoPrevistoMinutos: request.tempoPrevistoMinutos,
          status: SprintStatus.planejada,
        ),
        transaction: transaction,
      );
    });
  }

  Future<Sprint> atualizarSprint(
    Session session,
    SprintUpdateRequest request,
  ) async {
    final nome = _normalizarNome(request.nome);
    if (nome.isEmpty) {
      throw SprintException(codigo: SprintErroCodigo.nomeObrigatorio);
    }
    if (request.tempoPrevistoMinutos case final tempo? when tempo < 0) {
      throw SprintException(codigo: SprintErroCodigo.tempoPrevistoInvalido);
    }

    final dataInicio = _normalizarDataCalendario(request.dataInicio);
    final dataFim = _normalizarDataCalendario(request.dataFim);
    if (dataInicio.isAfter(dataFim)) {
      throw SprintException(codigo: SprintErroCodigo.periodoInvalido);
    }

    return session.db.transaction((transaction) async {
      await _bloquearCicloDeVida(session, transaction);
      final sprint = await _buscarSprintBloqueada(
        session,
        request.id,
        transaction,
      );
      final nomeNormalizado = nome.toLowerCase();
      await _validarNomeUnico(
        session,
        nomeNormalizado,
        transaction,
        sprintIdIgnorada: sprint.id,
      );
      await _validarSemSobreposicao(
        session,
        dataInicio: dataInicio,
        dataFim: dataFim,
        status: sprint.status,
        transaction: transaction,
        sprintIdIgnorada: sprint.id,
      );

      return (await Sprint.db.updateById(
        session,
        sprint.id!,
        columnValues: (t) => [
          t.nome(nome),
          t.nomeNormalizado(nomeNormalizado),
          t.dataInicio(dataInicio),
          t.dataFim(dataFim),
          t.tempoPrevistoMinutos(request.tempoPrevistoMinutos),
        ],
        transaction: transaction,
      ))!;
    });
  }

  Future<Sprint> ativarSprint(Session session, int id) =>
      _transicionar(session, id, SprintStatus.ativa);

  Future<Sprint> cancelarSprint(Session session, int id) =>
      _transicionar(session, id, SprintStatus.cancelada);

  Future<SprintConclusaoResponse> concluirSprint(
    Session session,
    int id,
  ) => session.db.transaction((transaction) async {
    await _bloquearCicloDeVida(session, transaction);
    final sprint = await _buscarSprintBloqueada(session, id, transaction);
    if (!_transicaoPermitida(sprint.status, SprintStatus.concluida)) {
      throw SprintException(
        codigo: SprintErroCodigo.transicaoStatusInvalida,
      );
    }

    final indicadores = await _indicadoresService.calcular(
      session,
      sprint: sprint,
      transaction: transaction,
    );
    final naoConcluidas = await _indicadoresService.contarDemandasNaoConcluidas(
      session,
      sprintId: sprint.id!,
      transaction: transaction,
    );
    final sprintConcluida = (await Sprint.db.updateById(
      session,
      sprint.id!,
      columnValues: (t) => [t.status(SprintStatus.concluida)],
      transaction: transaction,
    ))!;
    return SprintConclusaoResponse(
      sprint: sprintConcluida,
      quantidadeDemandasNaoConcluidas: naoConcluidas,
      indicadores: indicadores,
    );
  });

  Future<SprintConclusaoResponse> obterResumoConclusaoSprint(
    Session session,
    int id,
  ) => session.db.transaction((transaction) async {
    await _bloquearCicloDeVida(session, transaction);
    final sprint = await _buscarSprintBloqueada(session, id, transaction);
    final indicadores = await _indicadoresService.calcular(
      session,
      sprint: sprint,
      transaction: transaction,
    );
    final naoConcluidas = await _indicadoresService.contarDemandasNaoConcluidas(
      session,
      sprintId: sprint.id!,
      transaction: transaction,
    );
    return SprintConclusaoResponse(
      sprint: sprint,
      quantidadeDemandasNaoConcluidas: naoConcluidas,
      indicadores: indicadores,
    );
  });

  Future<SprintIndicadores> calcularIndicadoresSprint(
    Session session,
    int id,
  ) async {
    final sprint = await Sprint.db.findById(session, id);
    if (sprint == null) {
      throw SprintException(codigo: SprintErroCodigo.sprintNaoEncontrada);
    }
    return _indicadoresService.calcular(session, sprint: sprint);
  }

  Future<bool> excluirSprint(Session session, int id) =>
      session.db.transaction((transaction) async {
        await _bloquearCicloDeVida(session, transaction);
        final sprint = await Sprint.db.findById(
          session,
          id,
          transaction: transaction,
          lockMode: LockMode.forUpdate,
        );
        if (sprint == null) return false;
        await _demandaService.removerTodosVinculosDaSprint(
          session,
          sprintId: id,
          transaction: transaction,
        );
        await Sprint.db.deleteRow(session, sprint, transaction: transaction);
        return true;
      });

  Future<Sprint> reabrirSprint(Session session, int id) =>
      _transicionar(session, id, SprintStatus.planejada);

  Future<List<SprintDemanda>> vincularDemanda(
    Session session,
    int sprintId,
    int demandaId,
  ) => session.db.transaction(
    (transaction) => _demandaService.vincularArvore(
      session,
      sprintId: sprintId,
      demandaId: demandaId,
      transaction: transaction,
    ),
  );

  /// Vincula várias Demandas como uma única operação atômica.
  ///
  /// A propagação da árvore, os locks e as validações continuam
  /// concentrados no serviço. Qualquer falha aborta a transação inteira.
  Future<List<SprintDemanda>> vincularDemandas(
    Session session,
    int sprintId,
    List<int> demandaIds,
  ) async => session.db.transaction((transaction) async {
    return _demandaService.vincularArvores(
      session,
      sprintId: sprintId,
      demandaIds: demandaIds,
      transaction: transaction,
    );
  });

  Future<bool> desvincularDemanda(
    Session session,
    int sprintId,
    int demandaId,
  ) => session.db.transaction(
    (transaction) => _demandaService.desvincularArvore(
      session,
      sprintId: sprintId,
      demandaId: demandaId,
      transaction: transaction,
    ),
  );

  Future<Sprint> _transicionar(
    Session session,
    int id,
    SprintStatus destino,
  ) => session.db.transaction((transaction) async {
    await _bloquearCicloDeVida(session, transaction);
    final sprint = await _buscarSprintBloqueada(session, id, transaction);
    if (!_transicaoPermitida(sprint.status, destino)) {
      throw SprintException(codigo: SprintErroCodigo.transicaoStatusInvalida);
    }

    if (destino == SprintStatus.planejada) {
      await _demandaService.validarReabertura(
        session,
        sprintId: sprint.id!,
        transaction: transaction,
      );
    }

    if (destino == SprintStatus.ativa) {
      final hoje = _hojeUtc();
      if (hoje.isBefore(sprint.dataInicio)) {
        throw SprintException(
          codigo: SprintErroCodigo.inicioAntesDataInicio,
        );
      }
      if ((sprint.tempoPrevistoMinutos ?? 0) <= 0) {
        throw SprintException(codigo: SprintErroCodigo.tempoPrevistoInvalido);
      }
    }

    if (destino == SprintStatus.cancelada) {
      await _demandaService.removerTodosVinculosDaSprint(
        session,
        sprintId: sprint.id!,
        transaction: transaction,
      );
    }

    await _validarSemSobreposicao(
      session,
      dataInicio: sprint.dataInicio,
      dataFim: sprint.dataFim,
      status: destino,
      transaction: transaction,
      sprintIdIgnorada: sprint.id,
    );

    if (destino == SprintStatus.ativa) {
      final ativa = await Sprint.db.findFirstRow(
        session,
        where: (t) => t.status.equals(SprintStatus.ativa),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (ativa != null && ativa.id != sprint.id) {
        throw SprintException(codigo: SprintErroCodigo.sprintAtivaExistente);
      }
    }

    return (await Sprint.db.updateById(
      session,
      sprint.id!,
      columnValues: (t) => [t.status(destino)],
      transaction: transaction,
    ))!;
  });

  Future<void> _bloquearCicloDeVida(
    Session session,
    Transaction transaction,
  ) => session.db.unsafeQuery(
    "SELECT pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'))",
    transaction: transaction,
  );

  Future<Sprint> _buscarSprintBloqueada(
    Session session,
    int id,
    Transaction transaction,
  ) async {
    final sprint = await Sprint.db.findById(
      session,
      id,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (sprint == null) {
      throw SprintException(codigo: SprintErroCodigo.sprintNaoEncontrada);
    }
    return sprint;
  }

  Future<void> _validarNomeUnico(
    Session session,
    String nomeNormalizado,
    Transaction transaction, {
    int? sprintIdIgnorada,
  }) async {
    final existente = await Sprint.db.findFirstRow(
      session,
      where: (t) => sprintIdIgnorada == null
          ? t.nomeNormalizado.equals(nomeNormalizado)
          : t.nomeNormalizado.equals(nomeNormalizado) &
                t.id.notEquals(sprintIdIgnorada),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (existente != null) {
      throw SprintException(codigo: SprintErroCodigo.nomeDuplicado);
    }
  }

  Future<void> _validarSemSobreposicao(
    Session session, {
    required DateTime dataInicio,
    required DateTime dataFim,
    required SprintStatus status,
    required Transaction transaction,
    int? sprintIdIgnorada,
  }) async {
    if (!_bloqueiaSobreposicao(status)) return;

    final candidatas = await Sprint.db.find(
      session,
      where: (t) {
        final periodo = (t.dataInicio <= dataFim) & (t.dataFim >= dataInicio);
        final statusBloqueador = t.status.inSet({
          SprintStatus.planejada,
          SprintStatus.ativa,
          SprintStatus.concluida,
        });
        final ignorarAtual = sprintIdIgnorada == null
            ? periodo & statusBloqueador
            : periodo & statusBloqueador & t.id.notEquals(sprintIdIgnorada);
        return ignorarAtual;
      },
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (candidatas.isNotEmpty) {
      throw SprintException(codigo: SprintErroCodigo.periodoSobreposto);
    }
  }

  bool _transicaoPermitida(SprintStatus origem, SprintStatus destino) =>
      (origem == SprintStatus.planejada &&
          (destino == SprintStatus.ativa ||
              destino == SprintStatus.cancelada)) ||
      (origem == SprintStatus.ativa &&
          (destino == SprintStatus.cancelada ||
              destino == SprintStatus.concluida)) ||
      (origem == SprintStatus.cancelada && destino == SprintStatus.planejada);

  bool _bloqueiaSobreposicao(SprintStatus status) =>
      status == SprintStatus.planejada ||
      status == SprintStatus.ativa ||
      status == SprintStatus.concluida;

  DateTime _hojeUtc() {
    final agora = DateTime.now().toUtc();
    return DateTime.utc(agora.year, agora.month, agora.day);
  }

  DateTime _normalizarDataCalendario(DateTime data) =>
      DateTime.utc(data.year, data.month, data.day);

  String _normalizarNome(String valor) => valor
      .trim()
      .replaceFirst(RegExp(r'^sprint(?:\s+|$)', caseSensitive: false), '')
      .trim();
}
