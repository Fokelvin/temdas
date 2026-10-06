import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// All user supplied IDs are resolved with the owner predicate in SQL.
class UsuarioScope {
  const UsuarioScope(this.usuarioId);

  final int usuarioId;

  Future<Demanda?> demanda(
    Session session,
    int id, {
    Transaction? transaction,
    LockMode? lockMode,
  }) => Demanda.db.findFirstRow(
    session,
    where: (t) => t.id.equals(id) & t.usuarioId.equals(usuarioId),
    transaction: transaction,
    lockMode: lockMode,
  );

  Future<Sprint?> sprint(
    Session session,
    int id, {
    Transaction? transaction,
    LockMode? lockMode,
  }) => Sprint.db.findFirstRow(
    session,
    where: (t) => t.id.equals(id) & t.usuarioId.equals(usuarioId),
    transaction: transaction,
    lockMode: lockMode,
  );

  Future<Set<int>> demandaIds(
    Session session, {
    Transaction? transaction,
  }) async {
    final demandas = await Demanda.db.find(
      session,
      where: (t) => t.usuarioId.equals(usuarioId),
      transaction: transaction,
    );
    return demandas.map((demanda) => demanda.id!).toSet();
  }
}
