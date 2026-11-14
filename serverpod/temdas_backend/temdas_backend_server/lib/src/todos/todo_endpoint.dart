import 'package:serverpod/serverpod.dart';

import '../auth/supabase_auth_service.dart';
import '../auth/usuario_scope.dart';
import '../generated/protocol.dart';

class TodoEndpoint extends Endpoint {
  Future<List<Todo>> listar(Session session) async {
    final usuarioId = await _usuario(session);
    return _listar(session, usuarioId);
  }

  Future<Todo> criar(
    Session session,
    String conteudo,
    int? demandaId,
  ) async {
    final usuarioId = await _usuario(session);
    _validarConteudo(conteudo);
    return session.db.transaction((transaction) async {
      await _validarDemanda(session, usuarioId, demandaId, transaction);
      await _bloquearOrdem(session, usuarioId, transaction);
      final primeiro = await Todo.db.findFirstRow(
        session,
        where: (t) => t.usuarioId.equals(usuarioId) & t.posicao.notEquals(null),
        orderBy: (t) => t.posicao,
        transaction: transaction,
      );
      return Todo.db.insertRow(
        session,
        Todo(
          usuarioId: usuarioId,
          demandaId: demandaId,
          conteudo: conteudo,
          criadoEm: DateTime.now().toUtc(),
          posicao: primeiro == null ? null : primeiro.posicao! - 1,
        ),
        transaction: transaction,
      );
    });
  }

  Future<void> editarTexto(Session session, int id, String conteudo) =>
      _alterar(session, id, (todo) {
        _validarConteudo(conteudo);
        if (todo.linhas != null) {
          throw StateError('Recarregue a página para editar este To-do.');
        }
        return todo.copyWith(conteudo: conteudo);
      });

  Future<void> editarTitulo(Session session, int id, String? titulo) =>
      _alterar(session, id, (todo) {
        final valor = titulo?.trim();
        return todo.copyWith(
          titulo: valor == null || valor.isEmpty ? null : valor,
        );
      });

  Future<void> editarLinhas(Session session, int id, List<TodoLinha> linhas) =>
      _alterar(session, id, (todo) {
        final ids = <String>{};
        for (final linha in linhas) {
          if (linha.id.isEmpty ||
              !ids.add(linha.id) ||
              linha.texto.contains(RegExp(r'[\r\n]')) ||
              (linha.tipo == TodoTipoLinha.texto && linha.marcado)) {
            throw ArgumentError('Linhas inválidas.');
          }
        }
        final conteudo = linhas.map((linha) => linha.texto).join('\n');
        _validarConteudo(conteudo);
        return todo.copyWith(conteudo: conteudo, linhas: linhas);
      });

  Future<void> alterarData(Session session, int id, String? data) =>
      _alterar(session, id, (todo) {
        if (data != null) {
          final valor = DateTime.tryParse(data);
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(data) ||
              valor == null ||
              valor.year == 0 ||
              !valor.toIso8601String().startsWith(data)) {
            throw ArgumentError('Informe uma data válida.');
          }
        }
        return todo.copyWith(data: data);
      });

  Future<void> alterarConclusao(Session session, int id, bool concluido) =>
      _alterar(session, id, (todo) => todo.copyWith(concluido: concluido));

  Future<void> redimensionar(
    Session session,
    int id,
    double largura,
    double altura,
  ) => _alterar(session, id, (todo) {
    if (!largura.isFinite ||
        !altura.isFinite ||
        largura < 200 ||
        altura < 180 ||
        largura > 1600 ||
        altura > 1200) {
      throw ArgumentError('Dimensões inválidas.');
    }
    return todo.copyWith(largura: largura, altura: altura);
  });

  Future<void> vincular(Session session, int id, int? demandaId) => _alterar(
    session,
    id,
    (todo) => todo.copyWith(demandaId: demandaId),
    validarVinculo: demandaId,
  );

  Future<void> mover(
    Session session,
    int id,
    int destinoId,
    bool depois,
  ) async {
    final usuarioId = await _usuario(session);
    await session.db.transaction((transaction) async {
      await _bloquearOrdem(session, usuarioId, transaction);
      final todos = await _listar(
        session,
        usuarioId,
        transaction: transaction,
        bloquear: true,
      );
      final origem = todos.indexWhere((todo) => todo.id == id);
      if (origem < 0 || !todos.any((todo) => todo.id == destinoId)) {
        throw Exception('To-do não encontrado.');
      }
      if (id == destinoId) return;
      final movido = todos.removeAt(origem);
      final destino = todos.indexWhere((todo) => todo.id == destinoId);
      todos.insert(destino + (depois ? 1 : 0), movido);
      for (final (posicao, todo) in todos.indexed) {
        if (todo.posicao == posicao) continue;
        await Todo.db.updateRow(
          session,
          todo.copyWith(posicao: posicao),
          columns: (t) => [t.posicao],
          transaction: transaction,
        );
      }
    });
  }

  Future<void> excluir(Session session, int id) async {
    final usuarioId = await _usuario(session);
    await Todo.db.deleteWhere(
      session,
      where: (t) => t.usuarioId.equals(usuarioId) & t.id.equals(id),
    );
  }

  Future<void> _alterar(
    Session session,
    int id,
    Todo Function(Todo) alterar, {
    int? validarVinculo,
  }) async {
    final usuarioId = await _usuario(session);
    await session.db.transaction((transaction) async {
      await _validarDemanda(session, usuarioId, validarVinculo, transaction);
      final todo = await Todo.db.findFirstRow(
        session,
        where: (t) => t.usuarioId.equals(usuarioId) & t.id.equals(id),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (todo == null) throw Exception('To-do não encontrado.');
      await Todo.db.updateRow(session, alterar(todo), transaction: transaction);
    });
  }

  Future<List<Todo>> _listar(
    Session session,
    int usuarioId, {
    Transaction? transaction,
    bool bloquear = false,
  }) => Todo.db.find(
    session,
    where: (t) => t.usuarioId.equals(usuarioId),
    orderByList: (t) => [
      Order(column: t.posicao),
      Order(column: t.data),
      Order(column: t.id, orderDescending: true),
    ],
    transaction: transaction,
    lockMode: bloquear ? LockMode.forUpdate : null,
  );

  Future<int> _usuario(Session session) async =>
      (await requireAal2Usuario(session)).usuario.id!;

  Future<void> _bloquearOrdem(
    Session session,
    int usuarioId,
    Transaction transaction,
  ) async {
    await Usuario.db.findById(
      session,
      usuarioId,
      transaction: transaction,
      lockMode: LockMode.forNoKeyUpdate,
    );
  }

  Future<void> _validarDemanda(
    Session session,
    int usuarioId,
    int? demandaId,
    Transaction transaction,
  ) async {
    if (demandaId != null &&
        await UsuarioScope(usuarioId).demanda(
              session,
              demandaId,
              transaction: transaction,
              lockMode: LockMode.forKeyShare,
            ) ==
            null) {
      throw Exception('Demanda não encontrada.');
    }
  }

  void _validarConteudo(String conteudo) {
    if (conteudo.trim().isEmpty) {
      throw ArgumentError('Informe o conteúdo do To-do.');
    }
  }
}
