import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum VisualizacaoDemandas { kanban, lista }

/// Preferência visual local; não depende de sessão ou dados de negócio.
class DemandasVisualizacao extends ChangeNotifier {
  static const storageKey = 'temdas.demandas.visualizacao';
  VisualizacaoDemandas _value = VisualizacaoDemandas.kanban;
  VisualizacaoDemandas get value => _value;
  bool _selected = false;
  bool _disposed = false;
  Future<bool> _pending = Future.value(true);

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_selected || _disposed) return;
      _value = preferences.getString(storageKey) == 'lista'
          ? VisualizacaoDemandas.lista
          : VisualizacaoDemandas.kanban;
      notifyListeners();
    } catch (_) {
      // Armazenamento indisponível mantém o Kanban como padrão.
    }
  }

  Future<bool> select(VisualizacaoDemandas value) {
    _selected = true;
    _value = value;
    notifyListeners();
    return _pending = _pending.then((_) async {
      try {
        return await (await SharedPreferences.getInstance()).setString(
          storageKey,
          value.name,
        );
      } catch (_) {
        return false;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
