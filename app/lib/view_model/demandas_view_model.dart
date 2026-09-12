import 'package:flutter/foundation.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/repositories/demanda_repository.dart';
import '../data/repositories/registro_tempo_repository.dart';

class DemandasViewModel extends ChangeNotifier {
  DemandasViewModel({
    DemandaRepository? repository,
    RegistroTempoRepository? registroTempoRepository,
  }) : _repository = repository ?? DemandaRepository(),
       _registroTempoRepository =
           registroTempoRepository ?? RegistroTempoRepository();

  final DemandaRepository _repository;
  final RegistroTempoRepository _registroTempoRepository;

  bool _enviando = false;
  bool _carregando = false;
  bool _descartado = false;
  int _versaoCarregamento = 0;
  String? _erro;
  backend.Demanda? _demandaCriada;
  List<backend.Demanda> _demandas = [];

  bool get enviando => _enviando;
  bool get carregando => _carregando;
  String? get erro => _erro;
  backend.Demanda? get demandaCriada => _demandaCriada;
  List<backend.Demanda> get demandas => List.unmodifiable(_demandas);

  List<backend.Demanda> get demandasRaiz {
    final ids = _demandas.map((demanda) => demanda.id).whereType<int>().toSet();
    return List.unmodifiable(
      _demandas.where(
        (demanda) =>
            demanda.demandaPaiId == null || !ids.contains(demanda.demandaPaiId),
      ),
    );
  }

  List<backend.Demanda> filhasDe(backend.Demanda demanda) {
    final id = demanda.id;
    if (id == null) return const [];
    return List.unmodifiable(
      _demandas.where((candidata) => candidata.demandaPaiId == id),
    );
  }

  List<backend.Demanda> descendentesDe(backend.Demanda demanda) {
    final id = demanda.id;
    if (id == null) return const [];

    final porPai = <int, List<backend.Demanda>>{};
    for (final candidata in _demandas) {
      final paiId = candidata.demandaPaiId;
      if (paiId != null) {
        porPai.putIfAbsent(paiId, () => []).add(candidata);
      }
    }

    final resultado = <backend.Demanda>[];
    final visitados = <int>{id};
    final pendentes = <backend.Demanda>[...?porPai[id]];

    while (pendentes.isNotEmpty) {
      final atual = pendentes.removeLast();
      final atualId = atual.id;
      if (atualId == null || !visitados.add(atualId)) continue;
      resultado.add(atual);
      pendentes.addAll(porPai[atualId] ?? const []);
    }

    return List.unmodifiable(resultado);
  }

  bool possuiDescendentes(backend.Demanda demanda) =>
      descendentesDe(demanda).isNotEmpty;

  Future<void> carregarDemandas() async {
    if (_descartado) return;

    await _carregarDemandas(
      operacao: 'carregar as demandas',
      mensagemFalha: 'Não foi possível carregar as demandas. Tente novamente.',
    );
  }

  Future<bool> criarDemanda({
    required String titulo,
    required double tempoEstimadoHoras,
    int? demandaPaiId,
    String? descricao,
    backend.Prioridade? prioridade,
  }) async {
    if (_descartado || _enviando) return false;

    _iniciarEnvio();

    try {
      final tempoEstimadoMinutos = (tempoEstimadoHoras * 60).round();

      final demandaCriada = await _repository.criarDemanda(
        titulo: titulo,
        tempoEstimadoMinutos: tempoEstimadoMinutos,
        demandaPaiId: demandaPaiId,
        descricao: descricao,
        prioridade: prioridade,
      );

      if (!_descartado) {
        _demandaCriada = demandaCriada;
        await _recarregarAposMutacao();
      }
      return true;
    } catch (error, stackTrace) {
      if (!_descartado) {
        _registrarFalha('criar a demanda', error, stackTrace);
        _erro = 'Não foi possível criar a demanda. Tente novamente.';
      }
      return false;
    } finally {
      _finalizarEnvio();
    }
  }

  Future<bool> atualizarDemanda({
    required backend.Demanda demanda,
    required String titulo,
    required double tempoEstimadoHoras,
    required backend.DemandaStatus status,
    required backend.Prioridade prioridade,
    String? descricao,
  }) async {
    if (_descartado || _enviando) return false;

    final id = _idValido(demanda);
    if (id == null) return false;

    _iniciarEnvio();

    try {
      final tempoEstimadoMinutos = (tempoEstimadoHoras * 60).round();

      final demandaAtualizada = await _repository.atualizarDemanda(
        id: id,
        titulo: titulo,
        descricao: descricao,
        status: status,
        prioridade: prioridade,
        sprint: demanda.sprint,
        tempoEstimadoMinutos: tempoEstimadoMinutos,
        observacoes: demanda.observacoes,
      );

      if (!_descartado) {
        if (_demandaCriada?.id == id) {
          _demandaCriada = demandaAtualizada;
        }
        await _recarregarAposMutacao();
      }
      return true;
    } catch (error, stackTrace) {
      if (!_descartado) {
        _registrarFalha('atualizar a demanda $id', error, stackTrace);
        _erro = 'Não foi possível atualizar a demanda. Tente novamente.';
      }
      return false;
    } finally {
      _finalizarEnvio();
    }
  }

  Future<bool> excluirDemanda(backend.Demanda demanda) {
    return _excluir(demanda, arvoreCompleta: false);
  }

  Future<bool> excluirArvoreDemanda(backend.Demanda demanda) {
    return _excluir(demanda, arvoreCompleta: true);
  }

  Future<bool> registrarTempo({
    required backend.Demanda demanda,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) async {
    if (_descartado || _enviando) return false;

    final id = _idValido(demanda);
    if (id == null) return false;
    if (duracaoMinutos <= 0) {
      _erro = 'Informe uma duração de pelo menos um minuto.';
      notifyListeners();
      return false;
    }

    _iniciarEnvio();

    try {
      await _registroTempoRepository.registrarTempo(
        demandaId: id,
        inicioEm: inicioEm.toUtc(),
        duracaoMinutos: duracaoMinutos,
      );
      if (!_descartado) await _recarregarAposMutacao();
      return true;
    } catch (error, stackTrace) {
      if (!_descartado) {
        _registrarFalha('registrar tempo na demanda $id', error, stackTrace);
        _erro = 'Não foi possível registrar o tempo. Tente novamente.';
      }
      return false;
    } finally {
      _finalizarEnvio();
    }
  }

  Future<bool> _excluir(
    backend.Demanda demanda, {
    required bool arvoreCompleta,
  }) async {
    if (_descartado || _enviando) return false;

    final id = _idValido(demanda);
    if (id == null) return false;

    _iniciarEnvio();

    try {
      final excluida = arvoreCompleta
          ? await _repository.excluirArvoreDemanda(id)
          : await _repository.excluirDemanda(id);

      if (!excluida) {
        _erro = 'A demanda não foi encontrada ou já foi excluída.';
        return false;
      }

      final listaAtualizada = !_descartado && await _recarregarAposMutacao();
      if (listaAtualizada &&
          _demandaCriada != null &&
          !_demandas.any((item) => item.id == _demandaCriada!.id)) {
        _demandaCriada = null;
      }
      return true;
    } catch (error, stackTrace) {
      if (!_descartado) {
        _registrarFalha('excluir a demanda $id', error, stackTrace);
        _erro = 'Não foi possível excluir a demanda. Tente novamente.';
      }
      return false;
    } finally {
      _finalizarEnvio();
    }
  }

  int? _idValido(backend.Demanda demanda) {
    final id = demanda.id;
    if (id != null) return id;
    _erro = 'A demanda não possui um ID válido.';
    notifyListeners();
    return null;
  }

  Future<bool> _recarregarAposMutacao() {
    return _carregarDemandas(
      operacao: 'atualizar a lista de demandas após uma alteração',
      mensagemFalha:
          'A alteração foi salva, mas não foi possível atualizar a lista. '
          'Recarregue as demandas.',
    );
  }

  Future<bool> _carregarDemandas({
    required String operacao,
    required String mensagemFalha,
  }) async {
    final versao = ++_versaoCarregamento;

    _carregando = true;
    _erro = null;
    _notificar();

    try {
      final demandas = await _repository.listarDemandas();
      if (!_carregamentoAtual(versao)) return false;

      _demandas = demandas;
      return true;
    } catch (error, stackTrace) {
      if (!_carregamentoAtual(versao)) return false;

      _registrarFalha(operacao, error, stackTrace);
      _erro = mensagemFalha;
      return false;
    } finally {
      if (_carregamentoAtual(versao)) {
        _carregando = false;
        _notificar();
      }
    }
  }

  void _iniciarEnvio() {
    _enviando = true;
    _erro = null;
    notifyListeners();
  }

  void _finalizarEnvio() {
    if (_descartado) return;
    _enviando = false;
    _notificar();
  }

  void _registrarFalha(String operacao, Object error, StackTrace stackTrace) {
    debugPrint('[DemandasViewModel] Falha ao $operacao: $error');
    debugPrint(stackTrace.toString());
  }

  bool _carregamentoAtual(int versao) =>
      !_descartado && versao == _versaoCarregamento;

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _versaoCarregamento++;
    super.dispose();
  }
}
