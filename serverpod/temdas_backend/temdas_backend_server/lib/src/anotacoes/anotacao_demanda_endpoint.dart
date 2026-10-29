import 'package:serverpod/serverpod.dart';

import '../auth/supabase_auth_service.dart';
import '../auth/usuario_scope.dart';
import '../generated/protocol.dart';

/// Acesso pessoal, sem permissões colaborativas. O autor nunca vem do cliente.
class AnotacaoDemandaEndpoint extends Endpoint {
  Future<List<AnotacaoDemanda>> listar(Session session, int demandaId) async {
    final usuarioId = (await requireAal2Usuario(session)).usuario.id!;
    if (await UsuarioScope(usuarioId).demanda(session, demandaId) == null) {
      throw Exception('Demanda não encontrada.');
    }
    return AnotacaoDemanda.db.find(
      session,
      where: (t) => t.demandaId.equals(demandaId) & t.excluidoEm.equals(null),
      orderByList: (t) => [
        Order(column: t.criadoEm, orderDescending: true),
        Order(column: t.id, orderDescending: true),
      ],
    );
  }

  Future<AnotacaoDemanda> criar(
    Session session,
    int demandaId,
    String conteudo,
  ) async {
    final usuarioId = (await requireAal2Usuario(session)).usuario.id!;
    final texto = _validar(conteudo);
    return session.db.transaction((transaction) async {
      if (await UsuarioScope(usuarioId).demanda(
            session,
            demandaId,
            transaction: transaction,
            lockMode: LockMode.forKeyShare,
          ) ==
          null) {
        throw Exception('Demanda não encontrada.');
      }
      return AnotacaoDemanda.db.insertRow(
        session,
        AnotacaoDemanda(
          demandaId: demandaId,
          autorId: usuarioId,
          conteudo: texto,
          criadoEm: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
    });
  }

  Future<AnotacaoDemanda> editar(
    Session session,
    int id,
    String conteudo,
  ) async {
    final texto = _validar(conteudo);
    return _alterar(session, id, conteudo: texto);
  }

  Future<void> excluir(Session session, int id) async {
    await _alterar(session, id, excluir: true);
  }

  Future<AnotacaoDemanda> _alterar(
    Session session,
    int id, {
    String? conteudo,
    bool excluir = false,
  }) async {
    final usuarioId = (await requireAal2Usuario(session)).usuario.id!;
    return session.db.transaction((transaction) async {
      final ids = await UsuarioScope(
        usuarioId,
      ).demandaIds(session, transaction: transaction);
      final anotacao = await AnotacaoDemanda.db.findFirstRow(
        session,
        where: (t) =>
            t.id.equals(id) &
            t.autorId.equals(usuarioId) &
            t.demandaId.inSet(ids) &
            t.excluidoEm.equals(null),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (anotacao == null) {
        throw Exception('Anotação não encontrada ou sem permissão.');
      }
      final agora = DateTime.now().toUtc();
      return AnotacaoDemanda.db.updateRow(
        session,
        excluir
            ? anotacao.copyWith(excluidoEm: agora)
            : anotacao.copyWith(conteudo: conteudo, editadoEm: agora),
        transaction: transaction,
      );
    });
  }

  String _validar(String conteudo) {
    if (conteudo.trim().isEmpty) {
      throw Exception('Informe o conteúdo da anotação.');
    }
    return conteudo;
  }
}
