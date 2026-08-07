import 'package:flutter/foundation.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/repositories/demanda_repository.dart';

class DemandasViewModel extends ChangeNotifier {
  DemandasViewModel({DemandaRepository? repository})
    : _repository = repository ?? DemandaRepository();

  final DemandaRepository _repository;

  bool _enviando = false;
  bool _carregando = false;
  String? _erro;
  backend.Demanda? _demandaCriada;
  List<backend.Demanda> _demandas = [];

  bool get enviando => _enviando;
  bool get carregando => _carregando;
  String? get erro => _erro;
  backend.Demanda? get demandaCriada => _demandaCriada;
  List<backend.Demanda> get demandas => List.unmodifiable(_demandas);

  Future<void> carregarDemandas() async {
    if (_carregando) return;

    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _demandas = await _repository.listarDemandas();
    } catch (error) {
      _erro = error.toString();
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<bool> criarDemanda({
    required String titulo,
    required double tempoEstimadoHoras,
    String? descricao,
    backend.Prioridade? prioridade,
  }) async {
    if (_enviando) return false;

    _enviando = true;
    _erro = null;
    notifyListeners();

    try {
      final tempoEstimadoMinutos = (tempoEstimadoHoras * 60).round();

      _demandaCriada = await _repository.criarDemanda(
        titulo: titulo,
        tempoEstimadoMinutos: tempoEstimadoMinutos,
        descricao: descricao,
        prioridade: prioridade,
      );

      return true;
    } catch (error) {
      _erro = error.toString();
      return false;
    } finally {
      _enviando = false;
      notifyListeners();
    }
  }
}
