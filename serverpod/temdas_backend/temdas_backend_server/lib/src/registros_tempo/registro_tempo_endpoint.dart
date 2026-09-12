import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class RegistroTempoEndpoint extends Endpoint {
  Future<RegistroTempo> registrarTempo(
    Session session,
    RegistroTempoCreateRequest request,
  ) async {
    _validarDataUtc(request.inicioEm, 'O início do registro');

    if (request.duracaoMinutos <= 0) {
      throw Exception('A duração deve ser maior que zero.');
    }

    final registroCriado = await session.db.transaction((transaction) async {
      final demanda = await Demanda.db.findById(
        session,
        request.demandaId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (demanda == null) {
        throw Exception('Demanda não encontrada.');
      }

      final registro = RegistroTempo(
        demandaId: request.demandaId,
        inicioEm: request.inicioEm,
        duracaoMinutos: request.duracaoMinutos,
        criadoEm: DateTime.now().toUtc(),
      );

      final registroCriado = await RegistroTempo.db.insertRow(
        session,
        registro,
        transaction: transaction,
      );

      await _recalcularTempoExecutado(
        session,
        request.demandaId,
        transaction,
      );

      return registroCriado;
    });

    session.log(
      'Registro de tempo criado: id=${registroCriado.id}, '
      'demandaId=${registroCriado.demandaId}, '
      'duracaoMinutos=${registroCriado.duracaoMinutos}.',
    );
    return registroCriado;
  }

  Future<List<RegistroTempo>> listarRegistrosTempoPorPeriodo(
    Session session,
    DateTime inicio,
    DateTime fim,
  ) async {
    _validarPeriodo(inicio, fim);

    return RegistroTempo.db.find(
      session,
      where: (t) => (t.inicioEm >= inicio) & (t.inicioEm < fim),
      orderBy: (t) => t.inicioEm,
    );
  }

  Future<List<RegistroTempo>> listarRegistrosTempoDaDemanda(
    Session session,
    int demandaId,
  ) async {
    return RegistroTempo.db.find(
      session,
      where: (t) => t.demandaId.equals(demandaId),
      orderBy: (t) => t.inicioEm,
      orderDescending: true,
    );
  }

  Future<bool> excluirRegistroTempo(
    Session session,
    int id,
  ) async {
    final excluido = await session.db.transaction((transaction) async {
      final registroInicial = await RegistroTempo.db.findById(
        session,
        id,
        transaction: transaction,
      );

      if (registroInicial == null) {
        return false;
      }

      final demanda = await Demanda.db.findById(
        session,
        registroInicial.demandaId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (demanda == null) {
        return false;
      }

      final registro = await RegistroTempo.db.findById(
        session,
        id,
        transaction: transaction,
      );

      if (registro == null) {
        return false;
      }

      await RegistroTempo.db.deleteRow(
        session,
        registro,
        transaction: transaction,
      );

      await _recalcularTempoExecutado(
        session,
        registro.demandaId,
        transaction,
      );

      return true;
    });

    if (excluido) {
      session.log('Registro de tempo excluído: id=$id.');
    }
    return excluido;
  }

  Future<void> _recalcularTempoExecutado(
    Session session,
    int demandaId,
    Transaction transaction,
  ) async {
    final registros = await RegistroTempo.db.find(
      session,
      where: (t) => t.demandaId.equals(demandaId),
      transaction: transaction,
    );

    final totalMinutos = registros.fold<int>(
      0,
      (total, registro) => total + registro.duracaoMinutos,
    );

    final demandaAtualizada = await Demanda.db.updateById(
      session,
      demandaId,
      columnValues: (t) => [
        t.tempoExecutadoMinutos(totalMinutos),
        t.atualizadoEm(DateTime.now().toUtc()),
      ],
      transaction: transaction,
    );

    if (demandaAtualizada == null) {
      throw Exception('Demanda não encontrada.');
    }
  }

  void _validarPeriodo(DateTime inicio, DateTime fim) {
    _validarDataUtc(inicio, 'O início do período');
    _validarDataUtc(fim, 'O fim do período');

    if (!inicio.isBefore(fim)) {
      throw Exception('O início do período deve ser anterior ao fim.');
    }
  }

  void _validarDataUtc(DateTime data, String campo) {
    if (!data.isUtc) {
      throw Exception('$campo deve estar em UTC.');
    }
  }
}
