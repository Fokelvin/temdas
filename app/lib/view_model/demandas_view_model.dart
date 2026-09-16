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
  final Set<int> _demandasEmProcessamento = {};
  final _errosPorDemanda =
      <int, ({String mensagem, backend.TransicaoStatusException? transicao})>{};
  bool _carregando = false;
  bool _descartado = false;
  int _versaoCarregamento = 0;
  String? _erro;
  backend.TransicaoStatusException? _erroTransicaoStatus;
  backend.Demanda? _demandaCriada;
  List<backend.Demanda> _demandas = [];

  // Os fluxos globais continuam exclusivos; mutações locais bloqueiam só seu ID.
  bool get enviando => _enviando || _demandasEmProcessamento.isNotEmpty;
  bool get envioGlobalEmAndamento => _enviando;
  Set<int> get demandasEmProcessamento =>
      Set.unmodifiable(_demandasEmProcessamento);
  bool demandaEmProcessamento(int? id) => _demandasEmProcessamento.contains(id);
  String? erroDaDemanda(int? id) =>
      id == null ? _erro : _errosPorDemanda[id]?.mensagem;
  backend.TransicaoStatusException? erroTransicaoDaDemanda(int? id) =>
      id == null ? _erroTransicaoStatus : _errosPorDemanda[id]?.transicao;
  bool get carregando => _carregando;
  String? get erro => _erro;
  backend.TransicaoStatusException? get erroTransicaoStatus =>
      _erroTransicaoStatus;
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
    if (_descartado || enviando) return false;

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
        _invalidarCarregamentoPendente();
        _demandaCriada = demandaCriada;
        _inserirDemanda(demandaCriada);
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
    String? motivoCancelamento,
    required backend.Prioridade prioridade,
    String? descricao,
  }) async {
    if (_descartado || _enviando) return false;

    final id = _idValido(demanda);
    if (id == null) return false;

    final index = _indiceDemanda(id);
    final statusAnterior = index == -1
        ? demanda.status
        : _demandas[index].status;
    final novoCancelamento =
        status == backend.DemandaStatus.cancelada && statusAnterior != status;
    if (!_podeIniciarMutacao(id, global: novoCancelamento)) return false;
    final idProcessamento = novoCancelamento ? null : id;
    _errosPorDemanda.remove(id);
    _iniciarEnvio(demandaId: idProcessamento);

    try {
      final tempoEstimadoMinutos = (tempoEstimadoHoras * 60).round();

      final demandaAtualizada = await _repository.atualizarDemanda(
        id: id,
        titulo: titulo,
        descricao: descricao,
        status: status,
        motivoCancelamento: motivoCancelamento,
        prioridade: prioridade,
        sprint: demanda.sprint,
        tempoEstimadoMinutos: tempoEstimadoMinutos,
        observacoes: demanda.observacoes,
      );

      if (!_descartado) {
        _invalidarCarregamentoPendente();
        _substituirDemanda(demandaAtualizada);
        // Só uma nova transição no update pode cancelar descendentes.
        if (novoCancelamento) {
          await _recarregarAposMutacao(demandaId: id);
        }
      }
      return true;
    } catch (error, stackTrace) {
      if (!_descartado) {
        _registrarFalha('atualizar a demanda $id', error, stackTrace);
        _definirErroDemanda(
          id,
          error,
          'Não foi possível atualizar a demanda. Tente novamente.',
        );
      }
      return false;
    } finally {
      _finalizarEnvio(demandaId: idProcessamento);
    }
  }

  Future<bool> alterarStatusDemanda({
    required backend.Demanda demanda,
    required backend.DemandaStatus status,
    String? motivoCancelamento,
  }) => _executarTransicaoStatus(
    demanda,
    (id) => _repository.alterarStatusDemanda(
      id: id,
      status: status,
      motivoCancelamento: motivoCancelamento,
    ),
    // O endpoint de status sempre processa descendentes ao cancelar.
    recarregar: status == backend.DemandaStatus.cancelada,
  );

  Future<bool> concluirDemanda(backend.Demanda demanda) =>
      _executarTransicaoStatus(demanda, _repository.concluirDemanda);

  Future<bool> concluirDemandaEmCascata(backend.Demanda demanda) =>
      _executarTransicaoStatus(
        demanda,
        _repository.concluirDemandaEmCascata,
        recarregar: true,
      );

  Future<bool> cancelarDemandaEmCascata(
    backend.Demanda demanda,
    String motivo,
  ) => _executarTransicaoStatus(
    demanda,
    (id) => _repository.cancelarDemandaEmCascata(id, motivo),
    recarregar: true,
  );

  Future<bool> _executarTransicaoStatus(
    backend.Demanda demanda,
    Future<backend.Demanda> Function(int id) executar, {
    bool recarregar = false,
  }) async {
    if (_descartado || _enviando) return false;

    final id = _idValido(demanda);
    if (id == null) return false;

    if (!_podeIniciarMutacao(id, global: recarregar)) return false;
    final idProcessamento = recarregar ? null : id;
    _errosPorDemanda.remove(id);
    _iniciarEnvio(demandaId: idProcessamento);

    try {
      final atualizada = await executar(id);
      if (!_descartado) {
        _invalidarCarregamentoPendente();
        _substituirDemanda(atualizada);
        if (recarregar) await _recarregarAposMutacao(demandaId: id);
      }
      return true;
    } catch (error, stackTrace) {
      if (!_descartado) {
        _registrarFalha('alterar o status da demanda $id', error, stackTrace);
        _definirErroDemanda(
          id,
          error,
          'Não foi possível alterar o status da demanda. Tente novamente.',
        );
      }
      return false;
    } finally {
      _finalizarEnvio(demandaId: idProcessamento);
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
    if (!_podeIniciarMutacao(id, global: false)) return false;
    if (duracaoMinutos <= 0) {
      _definirErroDemanda(
        id,
        ArgumentError.value(duracaoMinutos),
        'Informe uma duração de pelo menos um minuto.',
      );
      notifyListeners();
      return false;
    }

    _errosPorDemanda.remove(id);
    _iniciarEnvio(demandaId: id);
    var registrado = false;

    try {
      await _registroTempoRepository.registrarTempo(
        demandaId: id,
        inicioEm: inicioEm.toUtc(),
        duracaoMinutos: duracaoMinutos,
      );
      registrado = true;
      if (!_descartado) {
        _invalidarCarregamentoPendente();
        final atualizada = await _repository.buscarDemandaPorId(id);
        if (!_descartado) {
          if (atualizada == null) {
            throw StateError('A demanda $id não foi encontrada.');
          }
          _invalidarCarregamentoPendente();
          _substituirDemanda(atualizada);
        }
      }
      return true;
    } catch (error, stackTrace) {
      if (!_descartado) {
        _registrarFalha('registrar tempo na demanda $id', error, stackTrace);
        _definirErroDemanda(
          id,
          error,
          registrado
              ? 'O tempo foi registrado, mas não foi possível atualizar a demanda. '
                    'Recarregue as demandas.'
              : 'Não foi possível registrar o tempo. Tente novamente.',
        );
      }
      // Uma falha na leitura não desfaz o registro já salvo no backend.
      return registrado;
    } finally {
      _finalizarEnvio(demandaId: id);
    }
  }

  Future<bool> _excluir(
    backend.Demanda demanda, {
    required bool arvoreCompleta,
  }) async {
    if (_descartado || enviando) return false;

    final id = _idValido(demanda);
    if (id == null) return false;

    final idsExcluidos = <int>{
      id,
      if (arvoreCompleta)
        ...descendentesDe(demanda).map((item) => item.id).whereType<int>(),
    };

    _iniciarEnvio();

    try {
      final excluida = arvoreCompleta
          ? await _repository.excluirArvoreDemanda(id)
          : await _repository.excluirDemanda(id);

      if (!excluida) {
        _erro = 'A demanda não foi encontrada ou já foi excluída.';
        return false;
      }

      if (!_descartado) {
        _invalidarCarregamentoPendente();
        _removerDemandas(idsExcluidos);
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

  int _indiceDemanda(int? id) =>
      id == null ? -1 : _demandas.indexWhere((item) => item.id == id);

  void _substituirDemanda(backend.Demanda atualizada) {
    final index = _indiceDemanda(atualizada.id);
    if (index != -1) _demandas[index] = atualizada;
    if (_demandaCriada?.id == atualizada.id) _demandaCriada = atualizada;
  }

  void _inserirDemanda(backend.Demanda criada) {
    final index = _demandas.indexWhere(
      (demanda) => criada.criadoEm.isAfter(demanda.criadoEm),
    );
    _demandas.insert(index == -1 ? _demandas.length : index, criada);
  }

  void _removerDemandas(Set<int> ids) {
    _demandas.removeWhere((item) => ids.contains(item.id));
    if (ids.contains(_demandaCriada?.id)) _demandaCriada = null;
    _errosPorDemanda.removeWhere((id, _) => ids.contains(id));
  }

  int? _idValido(backend.Demanda demanda) {
    final id = demanda.id;
    if (id != null) return id;
    _erroTransicaoStatus = null;
    _erro = 'A demanda não possui um ID válido.';
    notifyListeners();
    return null;
  }

  void _invalidarCarregamentoPendente() {
    // Uma carga anterior não pode sobrescrever a mutação confirmada.
    _versaoCarregamento++;
    _carregando = false;
  }

  Future<bool> _recarregarAposMutacao({int? demandaId}) async {
    final sucesso = await _carregarDemandas(
      operacao: 'atualizar a lista de demandas após uma alteração',
      mensagemFalha:
          'A alteração foi salva, mas não foi possível atualizar a lista. '
          'Recarregue as demandas.',
    );
    if (!_descartado && demandaId != null && !sucesso && _erro != null) {
      _errosPorDemanda[demandaId] = (mensagem: _erro!, transicao: null);
    }
    return sucesso;
  }

  Future<bool> _carregarDemandas({
    required String operacao,
    required String mensagemFalha,
  }) async {
    final versao = ++_versaoCarregamento;

    _carregando = true;
    _erro = null;
    _erroTransicaoStatus = null;
    _notificar();

    try {
      final demandas = await _repository.listarDemandas();
      if (!_carregamentoAtual(versao)) return false;

      _demandas = List.of(demandas);
      if (_demandaCriada case final criada?) {
        final index = _indiceDemanda(criada.id);
        if (index != -1) _demandaCriada = _demandas[index];
      }
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

  bool _podeIniciarMutacao(int id, {required bool global}) =>
      !_descartado &&
      !_enviando &&
      !_demandasEmProcessamento.contains(id) &&
      (!global || _demandasEmProcessamento.isEmpty);

  void _iniciarEnvio({int? demandaId}) {
    if (demandaId == null) {
      _enviando = true;
    } else {
      _demandasEmProcessamento.add(demandaId);
    }
    _erro = null;
    _erroTransicaoStatus = null;
    notifyListeners();
  }

  void _finalizarEnvio({int? demandaId}) {
    if (_descartado) return;
    if (demandaId == null) {
      _enviando = false;
    } else {
      _demandasEmProcessamento.remove(demandaId);
    }
    _notificar();
  }

  void _definirErroDemanda(int id, Object error, String mensagemFalha) {
    _erroTransicaoStatus = error is backend.TransicaoStatusException
        ? error
        : null;
    _erro = _erroTransicaoStatus?.mensagem ?? mensagemFalha;
    // Respostas simultâneas não devem trocar o erro consultado por cada card.
    _errosPorDemanda[id] = (mensagem: _erro!, transicao: _erroTransicaoStatus);
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
    _demandasEmProcessamento.clear();
    super.dispose();
  }
}
