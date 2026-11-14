import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/serverpod_client.dart';
import '../data/supabase_session.dart';

enum _Campo {
  texto,
  titulo,
  data,
  conclusao,
  tamanho,
  vinculo,
  exclusao,
  ordem,
}

typedef _Gravacao = Future<void> Function();
typedef _Chave = (int, _Campo, Object?);

class TodoViewModel extends ChangeNotifier {
  TodoViewModel(this._client);

  static TodoViewModel? _sessaoAtual;
  static String? _usuarioAtual;
  static StreamSubscription<Object?>? _auth;

  /// Keeps pending edits when the user moves between the two boards.
  static TodoViewModel daSessao() {
    final sessao = supabaseSession;
    final usuario = sessao?.currentSession?.user.id;
    if (sessao == null || usuario == null) {
      return TodoViewModel(serverpodClient);
    }
    _auth ??= sessao.authChanges.listen((estado) {
      if (estado.session?.user.id != _usuarioAtual) {
        _sessaoAtual?._encerrar();
        _sessaoAtual = null;
        _usuarioAtual = null;
      }
    });
    if (_usuarioAtual != usuario) {
      _sessaoAtual?._encerrar();
      _usuarioAtual = usuario;
      _sessaoAtual = TodoViewModel(serverpodClient);
    }
    return _sessaoAtual!;
  }

  final backend.Client _client;
  final _todos = <backend.Todo>[];
  final _fila = <_Chave, _Gravacao>{};
  final _textos = <int, Timer>{};
  final _titulos = <int, Timer>{};
  final _exclusoes = <int>{};
  bool _encerrado = false;
  bool _gravando = false;
  bool _falha = false;
  bool _carregando = false;
  bool _erroAoCarregar = false;
  bool _manual = false;
  int _versao = 0;

  List<backend.Todo> get todos => List.unmodifiable(_todos);
  bool get carregando => _carregando;
  bool get erroAoCarregar => _erroAoCarregar;
  bool get falhaAoSalvar => _falha;
  bool get salvando => _gravando || _textos.isNotEmpty || _titulos.isNotEmpty;
  bool excluindo(int id) => _exclusoes.contains(id);
  bool get podeCriar => !(_carregando || _erroAoCarregar || _falha || salvando);

  Future<void> carregar() async {
    if (_encerrado ||
        _carregando ||
        _fila.isNotEmpty ||
        salvando ||
        _todos.any((todo) => todo.conteudo.trim().isEmpty)) {
      return;
    }
    final versao = _versao;
    _carregando = true;
    _erroAoCarregar = false;
    notifyListeners();
    try {
      final dados = await _client.todo.listar();
      if (_encerrado || versao != _versao) return;
      _todos
        ..clear()
        ..addAll(dados);
      _manual = dados.any((todo) => todo.posicao != null);
    } catch (_) {
      _erroAoCarregar = true;
    } finally {
      _carregando = false;
      if (!_encerrado) notifyListeners();
    }
  }

  Future<void> criar(String texto, int? demandaId) async {
    if (_encerrado) throw StateError('Sessão encerrada.');
    final criado = await _client.todo.criar(texto, demandaId);
    if (_encerrado) return;
    _versao++;
    _todos.insert(0, criado);
    _ordenarPorData();
    notifyListeners();
  }

  void editarLinhas(int id, List<backend.TodoLinha> linhas) {
    final texto = linhas.map((linha) => linha.texto).join('\n');
    _atualizar(id, (todo) => todo.copyWith(conteudo: texto, linhas: linhas));
    _textos.remove(id)?.cancel();
    final chave = (id, _Campo.texto, null);
    _cancelarGravacoes((pendente) => pendente == chave);
    if (texto.trim().isNotEmpty) {
      _textos[id] = Timer(const Duration(milliseconds: 350), () {
        _textos.remove(id);
        _enfileirar(chave, () => _client.todo.editarLinhas(id, linhas));
      });
    }
    notifyListeners();
  }

  void editarTitulo(int id, String? titulo) {
    final valor = titulo?.trim();
    final salvo = valor == null || valor.isEmpty ? null : valor;
    _atualizar(id, (todo) => todo.copyWith(titulo: salvo));
    _titulos.remove(id)?.cancel();
    final chave = (id, _Campo.titulo, null);
    _cancelarGravacoes((pendente) => pendente == chave);
    _titulos[id] = Timer(const Duration(milliseconds: 350), () {
      _titulos.remove(id);
      _enfileirar(chave, () => _client.todo.editarTitulo(id, salvo));
      notifyListeners();
    });
    notifyListeners();
  }

  void alterarData(int id, String? data) {
    _atualizar(id, (todo) => todo.copyWith(data: data));
    _ordenarPorData();
    // Before the first move, the server also sorts by date. Keep these edits
    // in sequence with the move that fixes the initial manual positions.
    final chave = (id, _Campo.data, _manual ? null : Object());
    _enfileirar(chave, () => _client.todo.alterarData(id, data));
  }

  void alterarConclusao(int id, bool concluido) {
    _atualizar(id, (todo) => todo.copyWith(concluido: concluido));
    _enfileirar((
      id,
      _Campo.conclusao,
      null,
    ), () => _client.todo.alterarConclusao(id, concluido));
  }

  void vincular(int id, int? demandaId) {
    _atualizar(id, (todo) => todo.copyWith(demandaId: demandaId));
    _enfileirar((
      id,
      _Campo.vinculo,
      null,
    ), () => _client.todo.vincular(id, demandaId));
  }

  void redimensionar(int id, double largura, double altura) {
    _atualizar(id, (todo) => todo.copyWith(largura: largura, altura: altura));
    _enfileirar((
      id,
      _Campo.tamanho,
      null,
    ), () => _client.todo.redimensionar(id, largura, altura));
  }

  void mover(int id, int destinoId, {required bool depois}) {
    final origem = _todos.indexWhere((todo) => todo.id == id);
    if (id == destinoId || origem < 0) return;
    final movido = _todos.removeAt(origem);
    final destino = _todos.indexWhere((todo) => todo.id == destinoId);
    if (destino < 0) {
      _todos.insert(origem, movido);
      return;
    }
    _manual = true;
    _versao++;
    _todos.insert(destino + (depois ? 1 : 0), movido);
    _enfileirar((
      id,
      _Campo.ordem,
      Object(),
    ), () => _client.todo.mover(id, destinoId, depois));
  }

  void excluir(int id) {
    if (!_exclusoes.add(id)) return;
    _textos.remove(id)?.cancel();
    _titulos.remove(id)?.cancel();
    _cancelarGravacoes((chave) => chave.$1 == id && chave.$2 != _Campo.ordem);
    _enfileirar((id, _Campo.exclusao, null), () async {
      await _client.todo.excluir(id);
      _versao++;
      _todos.removeWhere((todo) => todo.id == id);
      _exclusoes.remove(id);
    });
  }

  void tentarSalvar() {
    _falha = false;
    unawaited(_gravar());
  }

  void _atualizar(int id, backend.Todo Function(backend.Todo) alterar) {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index < 0) return;
    _versao++;
    _todos[index] = alterar(_todos[index]);
  }

  void _ordenarPorData() {
    if (_manual) return;
    _todos.sort((a, b) {
      final porData = (a.data ?? '9999-99-99').compareTo(
        b.data ?? '9999-99-99',
      );
      return porData != 0 ? porData : b.id!.compareTo(a.id!);
    });
  }

  void _cancelarGravacoes(bool Function(_Chave) cancelar) {
    if (_falha && _fila.isNotEmpty && cancelar(_fila.keys.first)) {
      _falha = false;
    }
    _fila.removeWhere((chave, _) => cancelar(chave));
    if (!_falha && _fila.isNotEmpty) unawaited(_gravar());
  }

  void _enfileirar(_Chave chave, _Gravacao gravacao) {
    _fila[chave] = gravacao;
    if (_falha) {
      notifyListeners();
    } else {
      unawaited(_gravar());
      notifyListeners();
    }
  }

  Future<void> _gravar() async {
    if (_gravando || _encerrado) return;
    _gravando = true;
    notifyListeners();
    try {
      while (!_encerrado && _fila.isNotEmpty) {
        final operacao = _fila.entries.first;
        try {
          await operacao.value();
        } catch (_) {
          if (identical(_fila[operacao.key], operacao.value)) {
            _falha = true;
            break;
          }
        }
        if (identical(_fila[operacao.key], operacao.value)) {
          _fila.remove(operacao.key);
        }
      }
    } finally {
      _gravando = false;
      if (!_encerrado) notifyListeners();
    }
  }

  void _encerrar() {
    _encerrado = true;
    for (final timer in _textos.values) {
      timer.cancel();
    }
    _textos.clear();
    for (final timer in _titulos.values) {
      timer.cancel();
    }
    _titulos.clear();
    _fila.clear();
    _todos.clear();
  }

  @override
  void dispose() {
    _encerrar();
    super.dispose();
  }
}
