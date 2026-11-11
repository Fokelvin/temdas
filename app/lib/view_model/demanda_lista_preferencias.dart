import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColunaDemanda {
  id('ID'),
  demanda('Demanda'),
  prioridade('Prioridade'),
  estimado('Estimado'),
  executado('Executado'),
  sprint('Sprint'),
  status('Status'),
  criadoEm('Data de criação'),
  tipo('Tipo');

  const ColunaDemanda(this.rotulo);
  final String rotulo;

  bool get ordenavel => this != sprint;

  static const padrao = {
    id,
    demanda,
    prioridade,
    estimado,
    executado,
    sprint,
    status,
  };
}

typedef OrdemListaDemanda = ({ColunaDemanda coluna, bool crescente});

class DemandaListaPreferencias extends ChangeNotifier {
  DemandaListaPreferencias(String pagina) : _chave = 'temdas.$pagina.lista';

  final String _chave;
  Set<ColunaDemanda> _colunas = ColunaDemanda.padrao;
  OrdemListaDemanda? _ordem;
  Future<bool> _gravacao = Future.value(true);
  bool _editada = false;
  bool _descartada = false;

  Set<ColunaDemanda> get colunas => _colunas;
  OrdemListaDemanda? get ordem => _ordem;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_editada || _descartada) return;
      final salvo = prefs.get(_chave);
      if (salvo is! String) return;
      final dados = jsonDecode(salvo);
      if (dados is! Map<String, dynamic>) return;
      final salvas = dados['colunas'];
      if (salvas is List &&
          salvas.every(
            (nome) => ColunaDemanda.values.any((c) => c.name == nome),
          )) {
        _colunas = Set.unmodifiable({
          ColunaDemanda.demanda,
          for (final coluna in ColunaDemanda.values)
            if (salvas.contains(coluna.name)) coluna,
        });
      }
      final nome = dados['ordem'];
      final crescente = dados['crescente'];
      for (final coluna in _colunas) {
        if (coluna.ordenavel && coluna.name == nome && crescente is bool) {
          _ordem = (coluna: coluna, crescente: crescente);
        }
      }
      notifyListeners();
    } catch (_) {
      // Conserva os padrões se o armazenamento estiver indisponível.
    }
  }

  Future<bool> alternarColuna(ColunaDemanda coluna) {
    if (coluna == ColunaDemanda.demanda) return Future.value(true);
    final novas = {..._colunas};
    if (!novas.remove(coluna)) novas.add(coluna);
    _colunas = Set.unmodifiable(novas);
    if (_ordem?.coluna == coluna && !novas.contains(coluna)) _ordem = null;
    return _salvar();
  }

  Future<bool> ordenar(ColunaDemanda coluna) {
    if (!coluna.ordenavel || !_colunas.contains(coluna)) {
      return Future.value(true);
    }
    _ordem = (
      coluna: coluna,
      crescente: _ordem?.coluna != coluna || !_ordem!.crescente,
    );
    return _salvar();
  }

  Future<bool> _salvar() {
    _editada = true;
    final colunas = ColunaDemanda.values
        .where(_colunas.contains)
        .map((c) => c.name)
        .toList();
    final ordem = _ordem;
    _gravacao = _gravacao.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        return await prefs.setString(
          _chave,
          jsonEncode({
            'colunas': colunas,
            'ordem': ordem?.coluna.name,
            'crescente': ordem?.crescente,
          }),
        );
      } catch (_) {
        return false;
      }
    });
    notifyListeners();
    return _gravacao;
  }

  @override
  void dispose() {
    _descartada = true;
    super.dispose();
  }
}
