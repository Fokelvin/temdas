import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Largura em pixels deste navegador, independente de sessão ou Demanda.
class LarguraPainelDemanda extends ChangeNotifier {
  static const storageKey = 'temdas.demanda.painel.largura';
  LarguraPainelDemanda({this.preferenceKey = storageKey});
  final String preferenceKey;
  static const padrao = 420.0;
  static const minima = 360.0;
  static const breakpoint = 840.0;
  double _value = padrao;
  double get value => _value;
  bool _selected = false;
  bool _disposed = false;
  Future<bool> _pending = Future.value(true);

  static double maxima(double viewport) => (viewport * .7).roundToDouble();
  static double limitar(double width, double viewport) =>
      width.clamp(minima, maxima(viewport)).toDouble();

  double paraViewport(double viewport) =>
      viewport < breakpoint ? viewport : limitar(_value, viewport);

  Future<void> load() async {
    try {
      final stored = (await SharedPreferences.getInstance()).getDouble(
        preferenceKey,
      );
      if (_selected || _disposed) return;
      if (stored != null && stored.isFinite && stored >= minima) {
        _value = stored;
      }
      notifyListeners();
    } catch (_) {
      // Armazenamento indisponível não impede usar o painel.
    }
  }

  void ajustar(double width, double viewport) {
    if (viewport < breakpoint || !width.isFinite) return;
    _selected = true;
    _value = limitar(width, viewport);
    notifyListeners();
  }

  Future<bool> salvar() {
    final width = _value;
    return _pending = _pending.then((_) async {
      try {
        return await (await SharedPreferences.getInstance()).setDouble(
          preferenceKey,
          width,
        );
      } catch (_) {
        return false;
      }
    });
  }

  Future<bool> alternar(double viewport) {
    final atual = paraViewport(viewport);
    ajustar(
      (atual - maxima(viewport)).abs() < 1 ? padrao : maxima(viewport),
      viewport,
    );
    return salvar();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
