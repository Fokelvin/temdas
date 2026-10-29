import 'package:flutter/foundation.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/repositories/demanda_repository.dart';
import '../data/repositories/anotacao_demanda_repository.dart';
import 'sprint_view_model.dart';
import 'demandas_view_model.dart';
import '../data/repositories/registro_tempo_repository.dart';

class DemandaDetalheViewModel extends ChangeNotifier {
  DemandaDetalheViewModel({
    DemandaRepository? demandaRepository,
    RegistroTempoRepository? registroTempoRepository,
    AnotacaoDemandaRepository? anotacaoRepository,
    SprintViewModel? sprintViewModel,
  }) : _anotacaoRepository = anotacaoRepository ?? AnotacaoDemandaRepository(),
       _sprintViewModel = sprintViewModel ?? SprintViewModel(),
       _demandaRepository = demandaRepository ?? DemandaRepository(),
       _registroTempoRepository =
           registroTempoRepository ?? RegistroTempoRepository();

  final AnotacaoDemandaRepository _anotacaoRepository;
  final SprintViewModel _sprintViewModel;
  List<backend.AnotacaoDemanda> _anotacoes = [];
  List<backend.AnotacaoDemanda> get anotacoes => List.unmodifiable(_anotacoes);
  backend.Sprint? sprint;
  String? erroSprint;
  bool carregandoSprint = false;
  bool carregandoAnotacoes = false;
  bool salvando = false;
  String? erroAnotacoes;
  String? erroMutacao;
  final DemandaRepository _demandaRepository;
  final RegistroTempoRepository _registroTempoRepository;

  DemandasViewModel? acoesViewModel;
  bool _carregando = false;
  String? _erro;
  backend.Demanda? _demanda;
  backend.Demanda? _demandaMae;
  List<backend.Demanda> _filhas = [];
  List<backend.RegistroTempo> _registros = [];
  int _versaoCarregamento = 0;
  int _versaoSprint = 0;
  int _versaoAnotacoes = 0;
  int? _idAtual;
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
    if (_idAtual != demandaId) _anotacoes = [];
    _idAtual = demandaId;

    _carregando = true;
    _erro = null;
    _demanda = null;
    _demandaMae = null;
    _filhas = [];
    _registros = [];
    _notificar();
    carregarSprint(demandaId);

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

      acoesViewModel?.dispose();
      acoesViewModel = DemandasViewModel(
        repository: _demandaRepository,
        registroTempoRepository: _registroTempoRepository,
        demandasIniciais: demandas,
      );
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

  Future<void> carregarSprint(int demandaId) async {
    final versao = ++_versaoSprint;
    carregandoSprint = true;
    erroSprint = null;
    _notificar();
    final vinculos = await _sprintViewModel
        .carregarDemandasDeOutrasSprintsAbertas();
    if (_descartado || versao != _versaoSprint) return;
    sprint = vinculos?[demandaId];
    erroSprint = vinculos == null
        ? 'Não foi possível consultar a Sprint.'
        : null;
    carregandoSprint = false;
    _notificar();
  }

  Future<void> carregarAnotacoes(int demandaId) async {
    final versao = ++_versaoAnotacoes;
    final carregamento = _versaoCarregamento;
    carregandoAnotacoes = true;
    erroAnotacoes = null;
    _notificar();
    try {
      final resultado = await _anotacaoRepository.listar(demandaId);
      if (!_descartado &&
          versao == _versaoAnotacoes &&
          carregamento == _versaoCarregamento) {
        _anotacoes = resultado;
      }
    } catch (_) {
      if (!_descartado &&
          versao == _versaoAnotacoes &&
          carregamento == _versaoCarregamento) {
        erroAnotacoes = 'Não foi possível carregar as anotações.';
      }
    } finally {
      if (versao == _versaoAnotacoes) {
        carregandoAnotacoes = false;
        _notificar();
      }
    }
  }

  Future<bool> salvarAnotacao(int demandaId, String conteudo, {int? id}) =>
      _mutar(() async {
        if (id == null) {
          await _anotacaoRepository.criar(demandaId, conteudo);
        } else {
          await _anotacaoRepository.editar(id, conteudo);
        }
        await carregarAnotacoes(demandaId);
      });

  Future<bool> excluirAnotacao(int demandaId, int id) => _mutar(() async {
    await _anotacaoRepository.excluir(id);
    await carregarAnotacoes(demandaId);
  });

  Future<bool> salvarObservacao(int id, String texto) => _mutar(() async {
    final atualizado = await _registroTempoRepository.atualizarObservacao(
      id,
      texto,
    );
    if (!_descartado) {
      _registros = [for (final r in _registros) r.id == id ? atualizado : r];
    }
  });

  Future<bool> _mutar(Future<void> Function() operacao) async {
    if (salvando || _descartado) return false;
    salvando = true;
    erroMutacao = null;
    _notificar();
    try {
      await operacao();
      return true;
    } catch (_) {
      erroMutacao = 'Não foi possível salvar. Tente novamente.';
      return false;
    } finally {
      salvando = false;
      _notificar();
    }
  }

  @override
  void dispose() {
    _descartado = true;
    _versaoCarregamento++;
    acoesViewModel?.dispose();
    _sprintViewModel.dispose();
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
