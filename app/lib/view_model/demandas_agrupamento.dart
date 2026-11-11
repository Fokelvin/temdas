import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AgrupamentoDemandas {
  demanda('Demanda (hierarquia)'),
  status('Status'),
  prioridade('Prioridade');

  const AgrupamentoDemandas(this.rotulo);
  final String rotulo;
}

/// Preferência visual local; não depende de sessão ou dados de negócio.
class DemandasAgrupamento extends ChangeNotifier {
  static const storageKey = 'temdas.demandas.agrupamento';
  AgrupamentoDemandas _value = AgrupamentoDemandas.demanda;
  AgrupamentoDemandas get value => _value;
  bool _selected = false;
  bool _disposed = false;
  Future<bool> _pending = Future.value(true);

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_selected || _disposed) return;
      final salvo = preferences.getString(storageKey);
      _value = AgrupamentoDemandas.values.firstWhere(
        (opcao) => opcao.name == salvo,
        orElse: () => AgrupamentoDemandas.demanda,
      );
      notifyListeners();
    } catch (_) {
      // Armazenamento indisponível mantém o agrupamento por demanda como padrão.
    }
  }

  Future<bool> select(AgrupamentoDemandas value) {
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
