import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../auth/usuario_scope.dart';

class SprintDemandaService {
  Future<void> bloquearCicloDeVida(
    Session session,
    Transaction transaction,
  ) => session.db.unsafeQuery(
    "SELECT pg_advisory_xact_lock(hashtext('temdas.sprints.ciclo_vida'))",
    transaction: transaction,
  );

  Future<List<SprintDemanda>> vincularArvore(
    Session session, {
    required int sprintId,
    required int demandaId,
    required int usuarioId,
    required Transaction transaction,
  }) async {
    await bloquearCicloDeVida(session, transaction);
    final sprint = await _buscarSprintBloqueada(
      session,
      sprintId,
      transaction,
      usuarioId,
    );
    if (!_estaAberta(sprint.status)) {
      throw SprintException(codigo: SprintErroCodigo.vinculoStatusProibido);
    }

    final demandas = await _carregarArvoreBloqueada(
      session,
      demandaId,
      transaction,
      usuarioId,
    );
    _validarMesmoUsuario(sprint, demandas);
    final demandaRaiz = demandas.first;
    if (demandaRaiz.demandaPaiId case final demandaPaiId?) {
      final vinculoDaMae = await SprintDemanda.db.findFirstRow(
        session,
        where: (t) =>
            t.sprintId.equals(sprintId) & t.demandaId.equals(demandaPaiId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (vinculoDaMae == null) {
        throw SprintException(
          codigo: SprintErroCodigo.demandaFilhaSemMae,
        );
      }
    }

    final demandaIds = demandas.map((demanda) => demanda.id!).toSet();
    final vinculos = await SprintDemanda.db.find(
      session,
      where: (t) => t.demandaId.inSet(demandaIds),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    await _validarSemOutraSprintAberta(
      session,
      vinculos,
      sprintId,
      transaction,
    );

    final porDemandaNaSprint = {
      for (final vinculo in vinculos)
        if (vinculo.sprintId == sprintId) vinculo.demandaId: vinculo,
    };
    final resultado = <SprintDemanda>[];
    for (final demanda in demandas) {
      final existente = porDemandaNaSprint[demanda.id!];
      if (existente != null) {
        resultado.add(existente);
        continue;
      }
      final criado = await SprintDemanda.db.insertRow(
        session,
        SprintDemanda(sprintId: sprintId, demandaId: demanda.id!),
        transaction: transaction,
      );
      resultado.add(criado);
    }
    return resultado;
  }

  Future<List<SprintDemanda>> vincularArvores(
    Session session, {
    required int sprintId,
    required Iterable<int> demandaIds,
    required int usuarioId,
    required Transaction transaction,
  }) async {
    await bloquearCicloDeVida(session, transaction);
    await _buscarSprintBloqueada(session, sprintId, transaction, usuarioId);
    final resultado = <SprintDemanda>[];
    for (final demandaId in demandaIds.toSet()) {
      resultado.addAll(
        await vincularArvore(
          session,
          sprintId: sprintId,
          demandaId: demandaId,
          usuarioId: usuarioId,
          transaction: transaction,
        ),
      );
    }
    return resultado;
  }

  Future<bool> desvincularArvore(
    Session session, {
    required int sprintId,
    required int demandaId,
    required int usuarioId,
    required Transaction transaction,
  }) async {
    await bloquearCicloDeVida(session, transaction);
    final sprint = await _buscarSprintBloqueadaOuNula(
      session,
      sprintId,
      transaction,
      usuarioId,
    );
    if (sprint == null) return false;

    final demandas = await _carregarArvoreBloqueada(
      session,
      demandaId,
      transaction,
      usuarioId,
    );
    final demandaRaiz = demandas.first;
    final demandaIds = demandas.map((demanda) => demanda.id!).toSet();
    final vinculos = await SprintDemanda.db.find(
      session,
      where: (t) => t.sprintId.equals(sprintId) & t.demandaId.inSet(demandaIds),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (vinculos.isEmpty) return false;
    if (sprint.status == SprintStatus.concluida) {
      throw SprintException(codigo: SprintErroCodigo.vinculoStatusProibido);
    }

    if (demandaRaiz.demandaPaiId case final demandaPaiId?) {
      final vinculoDaMae = await SprintDemanda.db.findFirstRow(
        session,
        where: (t) =>
            t.sprintId.equals(sprintId) & t.demandaId.equals(demandaPaiId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (vinculoDaMae != null) {
        throw SprintException(
          codigo: SprintErroCodigo.demandaFilhaComMaeVinculada,
        );
      }
    }

    await SprintDemanda.db.delete(
      session,
      vinculos,
      transaction: transaction,
    );
    return true;
  }

  Future<void> herdarVinculoAbertoDaDemandaPai(
    Session session, {
    required int demandaPaiId,
    required int demandaFilhaId,
    required int usuarioId,
    required Transaction transaction,
  }) async {
    await bloquearCicloDeVida(session, transaction);
    final vinculosDaMae = await SprintDemanda.db.find(
      session,
      where: (t) => t.demandaId.equals(demandaPaiId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (vinculosDaMae.isEmpty) return;

    final sprintIds = vinculosDaMae.map((vinculo) => vinculo.sprintId).toSet();
    final sprintsAbertas = await Sprint.db.find(
      session,
      where: (t) =>
          t.id.inSet(sprintIds) &
          t.status.inSet({SprintStatus.planejada, SprintStatus.ativa}),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (sprintsAbertas.length > 1) {
      throw SprintException(codigo: SprintErroCodigo.demandaOutraSprintAberta);
    }
    if (sprintsAbertas.isEmpty) return;

    final demandaFilha = await UsuarioScope(usuarioId).demanda(
      session,
      demandaFilhaId,
      transaction: transaction,
      lockMode: LockMode.forKeyShare,
    );
    if (demandaFilha == null) {
      throw SprintException(codigo: SprintErroCodigo.demandaNaoEncontrada);
    }
    _validarMesmoUsuario(sprintsAbertas.single, [demandaFilha]);

    await SprintDemanda.db.insertRow(
      session,
      SprintDemanda(
        sprintId: sprintsAbertas.single.id!,
        demandaId: demandaFilhaId,
      ),
      transaction: transaction,
    );
  }

  Future<void> validarReabertura(
    Session session, {
    required int sprintId,
    required Transaction transaction,
  }) async {
    await bloquearCicloDeVida(session, transaction);
    final vinculos = await SprintDemanda.db.find(
      session,
      where: (t) => t.sprintId.equals(sprintId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    await _validarSemOutraSprintAberta(
      session,
      vinculos,
      sprintId,
      transaction,
    );
  }

  Future<void> removerTodosVinculosDaSprint(
    Session session, {
    required int sprintId,
    required Transaction transaction,
  }) async {
    await bloquearCicloDeVida(session, transaction);
    final vinculos = await SprintDemanda.db.find(
      session,
      where: (t) => t.sprintId.equals(sprintId),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (vinculos.isNotEmpty) {
      await SprintDemanda.db.delete(
        session,
        vinculos,
        transaction: transaction,
      );
    }
  }

  Future<List<Demanda>?> carregarArvoreBloqueadaOuNula(
    Session session,
    int demandaId,
    Transaction transaction, {
    required int usuarioId,
  }) async {
    final raiz = await UsuarioScope(usuarioId).demanda(
      session,
      demandaId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (raiz == null) return null;
    return _carregarDescendentesBloqueados(
      session,
      raiz,
      transaction,
      usuarioId,
    );
  }

  Future<void> validarSemHistoricoConcluido(
    Session session, {
    required Iterable<int> demandaIds,
    required Transaction transaction,
  }) async {
    final ids = demandaIds.toSet();
    if (ids.isEmpty) return;
    final vinculos = await SprintDemanda.db.find(
      session,
      where: (t) => t.demandaId.inSet(ids),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final sprintIds = vinculos.map((vinculo) => vinculo.sprintId).toSet();
    if (sprintIds.isEmpty) return;
    final historicos = await Sprint.db.find(
      session,
      where: (t) =>
          t.id.inSet(sprintIds) & t.status.equals(SprintStatus.concluida),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (historicos.isNotEmpty) {
      throw SprintException(
        codigo: SprintErroCodigo.historicoSprintConcluida,
      );
    }
  }

  Future<Sprint> _buscarSprintBloqueada(
    Session session,
    int sprintId,
    Transaction transaction,
    int usuarioId,
  ) async {
    final sprint = await _buscarSprintBloqueadaOuNula(
      session,
      sprintId,
      transaction,
      usuarioId,
    );
    if (sprint == null) {
      throw SprintException(codigo: SprintErroCodigo.sprintNaoEncontrada);
    }
    return sprint;
  }

  Future<Sprint?> _buscarSprintBloqueadaOuNula(
    Session session,
    int sprintId,
    Transaction transaction,
    int usuarioId,
  ) => UsuarioScope(usuarioId).sprint(
    session,
    sprintId,
    transaction: transaction,
    lockMode: LockMode.forUpdate,
  );

  Future<List<Demanda>> _carregarArvoreBloqueada(
    Session session,
    int demandaId,
    Transaction transaction,
    int usuarioId,
  ) async {
    final raiz = await UsuarioScope(usuarioId).demanda(
      session,
      demandaId,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (raiz == null) {
      throw SprintException(codigo: SprintErroCodigo.demandaNaoEncontrada);
    }

    return _carregarDescendentesBloqueados(
      session,
      raiz,
      transaction,
      usuarioId,
    );
  }

  Future<List<Demanda>> _carregarDescendentesBloqueados(
    Session session,
    Demanda raiz,
    Transaction transaction,
    int usuarioId,
  ) async {
    final demandas = <Demanda>[raiz];
    final visitados = <int>{raiz.id!};
    var pais = <int>{raiz.id!};
    while (pais.isNotEmpty) {
      final filhas = await Demanda.db.find(
        session,
        where: (t) =>
            t.usuarioId.equals(usuarioId) & t.demandaPaiId.inSet(pais),
        orderBy: (t) => t.id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      pais = {};
      for (final filha in filhas) {
        if (!visitados.add(filha.id!)) continue;
        demandas.add(filha);
        pais.add(filha.id!);
      }
    }
    return demandas;
  }

  Future<void> _validarSemOutraSprintAberta(
    Session session,
    List<SprintDemanda> vinculos,
    int sprintId,
    Transaction transaction,
  ) async {
    final sprintIds = vinculos
        .where((vinculo) => vinculo.sprintId != sprintId)
        .map((vinculo) => vinculo.sprintId)
        .toSet();
    if (sprintIds.isEmpty) return;

    final sprintsAbertas = await Sprint.db.find(
      session,
      where: (t) =>
          t.id.inSet(sprintIds) &
          t.status.inSet({SprintStatus.planejada, SprintStatus.ativa}),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (sprintsAbertas.isNotEmpty) {
      throw SprintException(codigo: SprintErroCodigo.demandaOutraSprintAberta);
    }
  }

  void _validarMesmoUsuario(Sprint sprint, List<Demanda> demandas) {
    for (final demanda in demandas) {
      if (demanda.usuarioId != sprint.usuarioId) {
        throw SprintException(
          codigo: SprintErroCodigo.usuarioDiferenteDaSprint,
        );
      }
    }
  }

  bool _estaAberta(SprintStatus status) =>
      status == SprintStatus.planejada || status == SprintStatus.ativa;
}
