import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class SprintIndicadoresService {
  Future<SprintIndicadores> calcular(
    Session session, {
    required Sprint sprint,
    Transaction? transaction,
  }) async {
    final demandaIds = (await SprintDemanda.db.find(
      session,
      where: (t) => t.sprintId.equals(sprint.id!),
      transaction: transaction,
    )).map((vinculo) => vinculo.demandaId).toSet();

    if (demandaIds.isEmpty) {
      return _indicadores(
        sprint,
        tempoTotalEstimadoMinutos: 0,
        tempoExecutadoMinutos: 0,
      );
    }

    final demandas = await Demanda.db.find(
      session,
      where: (t) => t.id.inSet(demandaIds),
      transaction: transaction,
    );
    final registros = await RegistroTempo.db.find(
      session,
      where: (t) =>
          t.demandaId.inSet(demandaIds) &
          (t.inicioEm >= sprint.dataInicio) &
          (t.inicioEm < sprint.dataFim.add(const Duration(days: 1))),
      transaction: transaction,
    );

    return _indicadores(
      sprint,
      tempoTotalEstimadoMinutos: demandas.fold(
        0,
        (total, demanda) => total + demanda.tempoEstimadoMinutos,
      ),
      tempoExecutadoMinutos: registros.fold(
        0,
        (total, registro) => total + registro.duracaoMinutos,
      ),
    );
  }

  Future<int> contarDemandasNaoConcluidas(
    Session session, {
    required int sprintId,
    Transaction? transaction,
  }) async {
    final demandaIds = (await SprintDemanda.db.find(
      session,
      where: (t) => t.sprintId.equals(sprintId),
      transaction: transaction,
    )).map((vinculo) => vinculo.demandaId).toSet();
    if (demandaIds.isEmpty) return 0;

    final demandas = await Demanda.db.find(
      session,
      where: (t) =>
          t.id.inSet(demandaIds) & t.status.notEquals(DemandaStatus.concluida),
      transaction: transaction,
    );
    return demandas.length;
  }

  SprintIndicadores _indicadores(
    Sprint sprint, {
    required int tempoTotalEstimadoMinutos,
    required int tempoExecutadoMinutos,
  }) => SprintIndicadores(
    tempoPrevistoMinutos: sprint.tempoPrevistoMinutos,
    tempoTotalEstimadoMinutos: tempoTotalEstimadoMinutos,
    tempoExecutadoMinutos: tempoExecutadoMinutos,
    diferencaExecutadoEstimadoMinutos:
        tempoExecutadoMinutos - tempoTotalEstimadoMinutos,
  );
}
