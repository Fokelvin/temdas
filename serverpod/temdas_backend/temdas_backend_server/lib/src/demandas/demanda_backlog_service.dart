import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../sprints/sprint_demanda_service.dart';

class DemandaBacklogService {
  final _sprints = SprintDemandaService();

  Future<BacklogPrevia> prever(Session session, int id, int usuarioId) =>
      session.db.transaction((tx) async {
        await _sprints.bloquearCicloDeVida(session, tx);
        final arvore = await _carregarRaiz(session, tx, id, usuarioId);
        _validarEnvio(arvore.first);
        return _vinculosOperacionais(session, tx, arvore, usuarioId);
      });

  Future<void> mover(
    Session session,
    int id,
    int usuarioId,
    DemandaLocalizacao destino,
    List<int> vinculosConfirmados,
  ) => session.db.transaction((tx) async {
    await _sprints.bloquearCicloDeVida(session, tx);
    final arvore = await _carregarRaiz(session, tx, id, usuarioId);
    final raiz = arvore.first;
    if (raiz.localizacao == destino) return;

    if (destino == DemandaLocalizacao.backlog) {
      _validarEnvio(raiz);
      final previa = await _vinculosOperacionais(
        session,
        tx,
        arvore,
        usuarioId,
      );
      final atuais = previa.vinculos.map((v) => v.id!).toSet();
      final confirmados = vinculosConfirmados.toSet();
      if (atuais.length != confirmados.length ||
          !atuais.containsAll(confirmados)) {
        throw MovimentacaoDemandaException(
          codigo: MovimentacaoDemandaErroCodigo.vinculosAlterados,
          mensagem: 'Os vínculos de Sprint mudaram. Revise e tente novamente.',
        );
      }
      if (previa.vinculos.isNotEmpty) {
        await SprintDemanda.db.delete(
          session,
          previa.vinculos,
          transaction: tx,
        );
      }
    }

    final ids = arvore.map((d) => d.id!).toSet();
    await Demanda.db.updateWhere(
      session,
      where: (t) => t.id.inSet(ids),
      columnValues: (t) => [t.localizacao(destino)],
      transaction: tx,
    );
  });

  Future<List<Demanda>> _carregarRaiz(
    Session session,
    Transaction tx,
    int id,
    int usuarioId,
  ) async {
    final arvore = await _sprints.carregarArvoreBloqueadaOuNula(
      session,
      id,
      tx,
      usuarioId: usuarioId,
    );
    if (arvore == null) {
      throw MovimentacaoDemandaException(
        codigo: MovimentacaoDemandaErroCodigo.demandaNaoEncontrada,
        mensagem: 'Demanda não encontrada.',
      );
    }
    if (arvore.first.demandaPaiId != null) {
      throw MovimentacaoDemandaException(
        codigo: MovimentacaoDemandaErroCodigo.demandaFilha,
        mensagem: 'Mova a demanda raiz para incluir toda a hierarquia.',
      );
    }
    return arvore;
  }

  void _validarEnvio(Demanda raiz) {
    if (raiz.status == DemandaStatus.concluida) {
      throw MovimentacaoDemandaException(
        codigo: MovimentacaoDemandaErroCodigo.statusTerminal,
        mensagem: 'Demandas raiz concluídas não podem ir para o Backlog.',
      );
    }
  }

  Future<BacklogPrevia> _vinculosOperacionais(
    Session session,
    Transaction tx,
    List<Demanda> arvore,
    int usuarioId,
  ) async {
    final ids = arvore.map((d) => d.id!).toSet();
    final vinculos = await SprintDemanda.db.find(
      session,
      where: (t) => t.demandaId.inSet(ids),
      orderBy: (t) => t.id,
      transaction: tx,
    );
    if (vinculos.isEmpty) return BacklogPrevia(sprints: [], vinculos: []);
    final sprintIds = vinculos.map((v) => v.sprintId).toSet();
    final sprints = await Sprint.db.find(
      session,
      where: (t) =>
          t.id.inSet(sprintIds) &
          t.usuarioId.equals(usuarioId) &
          t.status.inSet({SprintStatus.ativa, SprintStatus.planejada}),
      orderBy: (t) => t.id,
      transaction: tx,
    );
    final operacionais = sprints.map((s) => s.id!).toSet();
    return BacklogPrevia(
      sprints: sprints,
      vinculos: vinculos
          .where((v) => operacionais.contains(v.sprintId))
          .toList(),
    );
  }
}
