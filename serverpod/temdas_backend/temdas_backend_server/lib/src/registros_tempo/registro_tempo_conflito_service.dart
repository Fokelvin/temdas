import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class RegistroTempoConflitoService {
  Future<void> validarAusenciaDeConflito(
    Session session,
    RegistroTempo intervalo,
    Transaction transaction,
  ) async {
    final fim = intervalo.inicioEm.add(
      Duration(minutes: intervalo.duracaoMinutos),
    );
    final candidatos = await RegistroTempo.db.find(
      session,
      where: (t) {
        final filtro =
            t.demandaId.notEquals(intervalo.demandaId) & (t.inicioEm < fim);
        return intervalo.id == null
            ? filtro
            : filtro & t.id.notEquals(intervalo.id!);
      },
      orderBy: (t) => t.id,
      transaction: transaction,
    );

    for (final registro in candidatos) {
      final fimExistente = registro.inicioEm.add(
        Duration(minutes: registro.duracaoMinutos),
      );
      // [início, fim): igualdade em qualquer limite permite adjacência.
      if (intervalo.inicioEm.isBefore(fimExistente)) {
        throw ConflitoHorarioException(
          mensagem:
              'Conflito de horário: o intervalo se sobrepõe ao lançamento '
              '${registro.id} da demanda ${registro.demandaId}.',
          demandaConflitanteId: registro.demandaId,
          registroConflitanteId: registro.id!,
        );
      }
    }
  }
}
