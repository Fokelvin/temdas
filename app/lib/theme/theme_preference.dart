import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferência deste dispositivo, independente da sessão autenticada.
class ThemePreference extends ChangeNotifier {
  static const storageKey = 'temdas.themeMode';
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;
  bool _selected = false;
  bool _disposed = false;
  Future<bool> _pendingSave = Future.value(true);

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_selected || _disposed) return;
      _mode = switch (preferences.getString(storageKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      notifyListeners();
    } catch (_) {
      // Armazenamento indisponível mantém o padrão do sistema.
    }
  }

  Future<bool> select(ThemeMode mode) {
    _selected = true;
    _mode = mode;
    notifyListeners();
    // Serializa mudanças rápidas para persistir sempre a última escolha.
    return _pendingSave = _pendingSave.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        return mode == ThemeMode.system
            ? await preferences.remove(storageKey)
            : await preferences.setString(storageKey, mode.name);
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

class ThemePreferenceScope extends InheritedNotifier<ThemePreference> {
  const ThemePreferenceScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ThemePreference? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ThemePreferenceScope>()
      ?.notifier;
}
