import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../auth/supabase_auth_service.dart';
import '../auth/usuario_scope.dart';
import 'registro_tempo_conflito_service.dart';
import 'registro_tempo_normalizacao_service.dart';

class RegistroTempoEndpoint extends Endpoint {
  Future<int> _owner(Session session) async =>
      (await requireAal2Usuario(session)).usuario.id!;

  Future<RegistroTempo> registrarTempo(
    Session session,
    RegistroTempoCreateRequest request,
  ) async {
    final usuarioId = await _owner(session);
    _validarDataUtc(request.inicioEm, 'O início do registro');

    if (request.duracaoMinutos <= 0) {
      throw Exception('A duração deve ser maior que zero.');
    }

    final registroCriado = await session.db.transaction((transaction) async {
      await _bloquearAgenda(session, transaction);
      final demanda = await UsuarioScope(usuarioId).demanda(
        session,
        request.demandaId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (demanda == null) {
        throw RegistroTempoException(codigo: 'demandaNaoEncontrada');
      }

      final registro = RegistroTempo(
        demandaId: request.demandaId,
        inicioEm: request.inicioEm,
        duracaoMinutos: request.duracaoMinutos,
        criadoEm: DateTime.now().toUtc(),
      );

      return _normalizarEPersistir(session, registro, transaction, usuarioId);
    });

    session.log(
      'Registro de tempo salvo: id=${registroCriado.id}, '
      'demandaId=${registroCriado.demandaId}, '
      'duracaoMinutos=${registroCriado.duracaoMinutos}.',
    );
    return registroCriado;
  }

  Future<RegistroTempo> editarRegistroTempo(
    Session session,
    RegistroTempoUpdateRequest request,
  ) async {
    final usuarioId = await _owner(session);
    _validarDataUtc(request.inicioEm, 'O início do registro');
    if (request.duracaoMinutos <= 0) {
      throw Exception('A duração deve ser maior que zero.');
    }

    final atualizado = await session.db.transaction((transaction) async {
      await _bloquearAgenda(session, transaction);
      final ownedIds = await UsuarioScope(
        usuarioId,
      ).demandaIds(session, transaction: transaction);
      final registroInicial = await RegistroTempo.db.findFirstRow(
        session,
        where: (t) => t.id.equals(request.id) & t.demandaId.inSet(ownedIds),
        transaction: transaction,
      );
      if (registroInicial == null) {
        throw RegistroTempoException(codigo: 'registroNaoEncontrado');
      }

      // Mantém a ordem demanda -> registro, usada também na exclusão,
      // evitando inversão de locks com operações concorrentes.
      final demanda = await UsuarioScope(usuarioId).demanda(
        session,
        registroInicial.demandaId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (demanda == null) {
        throw RegistroTempoException(codigo: 'registroNaoEncontrado');
      }
      final registro = await RegistroTempo.db.findFirstRow(
        session,
        where: (t) =>
            t.id.equals(request.id) &
            t.demandaId.equals(registroInicial.demandaId),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (registro == null) {
        throw RegistroTempoException(codigo: 'registroNaoEncontrado');
      }

      // ID, demandaId e criadoEm vêm exclusivamente do registro bloqueado.
      final desejado = registro.copyWith(
        inicioEm: request.inicioEm,
        duracaoMinutos: request.duracaoMinutos,
      );
      return _normalizarEPersistir(session, desejado, transaction, usuarioId);
    });

    session.log(
      'Registro de tempo editado: id=${atualizado.id}, '
      'demandaId=${atualizado.demandaId}, '
      'duracaoMinutos=${atualizado.duracaoMinutos}.',
    );
    return atualizado;
  }

  Future<List<RegistroTempo>> listarRegistrosTempoPorPeriodo(
    Session session,
    DateTime inicio,
    DateTime fim,
  ) async {
    final usuarioId = await _owner(session);
    _validarPeriodo(inicio, fim);
    final ownedIds = await UsuarioScope(usuarioId).demandaIds(session);
    if (ownedIds.isEmpty) return [];
    return RegistroTempo.db.find(
      session,
      where: (t) =>
          t.demandaId.inSet(ownedIds) &
          (t.inicioEm >= inicio) &
          (t.inicioEm < fim),
      orderBy: (t) => t.inicioEm,
    );
  }

  Future<List<RegistroTempo>> listarRegistrosTempoDaDemanda(
    Session session,
    int demandaId,
  ) async {
    final usuarioId = await _owner(session);
    final demanda = await UsuarioScope(usuarioId).demanda(session, demandaId);
    if (demanda == null) {
      throw RegistroTempoException(codigo: 'demandaNaoEncontrada');
    }
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
    final usuarioId = await _owner(session);
    final excluido = await session.db.transaction((transaction) async {
      final ownedIds = await UsuarioScope(
        usuarioId,
      ).demandaIds(session, transaction: transaction);
      final registroInicial = await RegistroTempo.db.findFirstRow(
        session,
        where: (t) => t.id.equals(id) & t.demandaId.inSet(ownedIds),
        transaction: transaction,
      );

      if (registroInicial == null) {
        return false;
      }

      final demanda = await UsuarioScope(usuarioId).demanda(
        session,
        registroInicial.demandaId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (demanda == null) {
        return false;
      }

      final registro = await RegistroTempo.db.findFirstRow(
        session,
        where: (t) =>
            t.id.equals(id) & t.demandaId.equals(registroInicial.demandaId),
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

  Future<void> _bloquearAgenda(Session session, Transaction transaction) async {
    // A agenda pessoal compartilha o lock entre criação e edição, inclusive
    // entre demandas distintas. Ele é liberado no commit ou rollback.
    await session.db.unsafeQuery(
      "SELECT pg_advisory_xact_lock(hashtext('temdas.registros_tempo'))",
      transaction: transaction,
    );
  }

  Future<RegistroTempo> _normalizarEPersistir(
    Session session,
    RegistroTempo registro,
    Transaction transaction,
    int usuarioId,
  ) async {
    final existentes = await RegistroTempo.db.find(
      session,
      where: (t) {
        final filtro = t.demandaId.equals(registro.demandaId);
        return registro.id == null
            ? filtro
            : filtro & t.id.notEquals(registro.id!);
      },
      transaction: transaction,
    );
    final normalizacao = RegistroTempoNormalizacaoService().normalizar(
      registro,
      existentes,
    );
    final resultante = normalizacao.resultante;
    // Valida os limites finais antes de qualquer gravação ou remoção.
    await RegistroTempoConflitoService().validarAusenciaDeConflito(
      session,
      resultante,
      transaction,
      usuarioId,
    );
    final salvo = resultante.id == null
        ? await RegistroTempo.db.insertRow(
            session,
            resultante,
            transaction: transaction,
          )
        : await RegistroTempo.db.updateRow(
            session,
            resultante,
            transaction: transaction,
          );
    if (normalizacao.absorvidos.isNotEmpty) {
      await RegistroTempo.db.delete(
        session,
        normalizacao.absorvidos,
        transaction: transaction,
      );
    }
    await _recalcularTempoExecutado(session, registro.demandaId, transaction);
    return salvo;
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
      throw RegistroTempoException(codigo: 'demandaNaoEncontrada');
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
