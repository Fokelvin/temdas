import 'package:flutter/foundation.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/repositories/demanda_repository.dart';
import '../data/repositories/registro_tempo_repository.dart';

class DemandaDetalheViewModel extends ChangeNotifier {
  DemandaDetalheViewModel({
    DemandaRepository? demandaRepository,
    RegistroTempoRepository? registroTempoRepository,
  }) : _demandaRepository = demandaRepository ?? DemandaRepository(),
       _registroTempoRepository =
           registroTempoRepository ?? RegistroTempoRepository();

  final DemandaRepository _demandaRepository;
  final RegistroTempoRepository _registroTempoRepository;

  bool _carregando = false;
  String? _erro;
  backend.Demanda? _demanda;
  backend.Demanda? _demandaMae;
  List<backend.Demanda> _filhas = [];
  List<backend.RegistroTempo> _registros = [];
  int _versaoCarregamento = 0;
  bool _descartado = false;

  bool get carregando => _carregando;
  String? get erro => _erro;
  backend.Demanda? get demanda => _demanda;
  backend.Demanda? get demandaMae => _demandaMae;
  List<backend.Demanda> get filhas => List.unmodifiable(_filhas);
  List<backend.RegistroTempo> get registros => List.unmodifiable(_registros);

  int get tempoExecutadoMinutos => _demanda?.tempoExecutadoMinutos ?? 0;

  Future<void> carregar(int demandaId) async {
    final versao = ++_versaoCarregamento;

    _carregando = true;
    _erro = null;
    _demanda = null;
    _demandaMae = null;
    _filhas = [];
    _registros = [];
    _notificar();

    try {
      final resultados = await Future.wait<Object?>([
        _demandaRepository.buscarDemandaPorId(demandaId),
        _demandaRepository.listarDemandas(),
        _registroTempoRepository.listarDaDemanda(demandaId),
      ]);

      final demanda = resultados[0] as backend.Demanda?;
      final demandas = resultados[1] as List<backend.Demanda>;
      final registros = resultados[2] as List<backend.RegistroTempo>;

      if (versao != _versaoCarregamento || _descartado) return;

      _demanda = demanda;
      if (demanda != null) {
        _demandaMae = _encontrarPorId(demandas, demanda.demandaPaiId);
        _filhas = demandas
            .where((item) => item.demandaPaiId == demandaId)
            .toList(growable: false);
        _registros = registros.toList(growable: false)
          ..sort((a, b) => a.inicioEm.compareTo(b.inicioEm));
      }
    } catch (error, stackTrace) {
      debugPrint(
        '[DemandaDetalheViewModel] Falha ao carregar a demanda '
        '$demandaId: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      if (versao != _versaoCarregamento || _descartado) return;
      _erro = 'Não foi possível carregar os detalhes da demanda.';
    } finally {
      if (versao == _versaoCarregamento && !_descartado) {
        _carregando = false;
        _notificar();
      }
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _versaoCarregamento++;
    super.dispose();
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  backend.Demanda? _encontrarPorId(List<backend.Demanda> demandas, int? id) {
    if (id == null) return null;

    for (final demanda in demandas) {
      if (demanda.id == id) return demanda;
    }
    return null;
  }
}
