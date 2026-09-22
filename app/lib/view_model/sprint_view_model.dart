import 'package:flutter/foundation.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../data/repositories/sprint_repository.dart';

class SprintViewModel extends ChangeNotifier {
  SprintViewModel({SprintRepository? repository})
    : _repository = repository ?? SprintRepository();

  final SprintRepository _repository;

  final List<backend.Sprint> _sprints = [];
  final Map<int, backend.SprintIndicadores> _indicadoresPorSprint = {};
  List<backend.SprintDemanda> _vinculos = const [];
  backend.Sprint? _sprintSelecionada;
  backend.SprintConclusaoResponse? _resumoConclusao;
  backend.SprintConclusaoResponse? _resultadoConclusao;
  backend.SprintIndicadores? _indicadores;
  bool _carregando = false;
  bool _enviando = false;
  bool _descartado = false;
  String? _erro;

  bool get carregando => _carregando;
  bool get enviando => _enviando;
  String? get erro => _erro;
  List<backend.Sprint> get sprints => List.unmodifiable(_sprints);
  Map<int, backend.SprintIndicadores> get indicadoresPorSprint =>
      Map.unmodifiable(_indicadoresPorSprint);
  backend.SprintIndicadores? indicadoresDaSprint(int id) =>
      _indicadoresPorSprint[id];
  backend.Sprint? get sprintSelecionada => _sprintSelecionada;
  List<backend.SprintDemanda> get vinculos => List.unmodifiable(_vinculos);
  backend.SprintConclusaoResponse? get resumoConclusao => _resumoConclusao;
  backend.SprintConclusaoResponse? get resultadoConclusao =>
      _resultadoConclusao;
  backend.SprintIndicadores? get indicadores => _indicadores;

  Future<bool> carregarSprints() async {
    final sprints = await _executar<List<backend.Sprint>>(
      operacao: 'carregar as sprints',
      carregar: true,
      executar: _repository.listarSprints,
    );
    if (sprints == null) return false;

    _sprints
      ..clear()
      ..addAll(sprints);
    final idSelecionado = _sprintSelecionada?.id;
    if (idSelecionado != null) {
      final atualizada = sprints.where((sprint) => sprint.id == idSelecionado);
      if (atualizada.isEmpty) {
        _limparSelecao();
      } else {
        _sprintSelecionada = atualizada.first;
      }
    }
    _notificar();
    return true;
  }

  Future<bool> carregarSprint(int id) async {
    final sprint = await _executar<backend.Sprint>(
      operacao: 'carregar a sprint',
      carregar: true,
      executar: () => _repository.buscarSprintPorId(id),
    );
    if (sprint == null) return false;
    selecionarSprint(sprint);
    return true;
  }

  Future<bool> carregarVinculos(int sprintId) async {
    final vinculos = await _executar<List<backend.SprintDemanda>>(
      operacao: 'carregar as demandas da sprint',
      carregar: true,
      executar: () => _repository.listarDemandasDaSprint(sprintId),
    );
    if (vinculos == null) return false;
    _vinculos = List.unmodifiable(vinculos);
    _notificar();
    return true;
  }

  /// Retorna, quando disponível, a Sprint aberta que já contém cada Demanda.
  /// A resposta serve apenas para orientar a seleção; o backend valida o vínculo.
  Future<Map<int, backend.Sprint>?> carregarDemandasDeOutrasSprintsAbertas(
    int sprintIdAtual,
  ) async {
    return _executar<Map<int, backend.Sprint>>(
      operacao: 'verificar vínculos com outras sprints',
      carregar: true,
      executar: () async {
        final sprints = await _repository.listarSprints();
        final resultado = <int, backend.Sprint>{};
        for (final sprint in sprints) {
          if (sprint.id == null || sprint.id == sprintIdAtual) continue;
          if (sprint.status != backend.SprintStatus.planejada &&
              sprint.status != backend.SprintStatus.ativa) {
            continue;
          }
          final vinculos = await _repository.listarDemandasDaSprint(sprint.id!);
          for (final vinculo in vinculos) {
            resultado.putIfAbsent(vinculo.demandaId, () => sprint);
          }
        }
        return resultado;
      },
    );
  }

  void selecionarSprint(backend.Sprint? sprint) {
    if (sprint == null || _sprintSelecionada?.id != sprint.id) {
      _resumoConclusao = null;
      _resultadoConclusao = null;
      _indicadores = null;
      _vinculos = const [];
    }
    _sprintSelecionada = sprint;
    if (sprint != null) _adicionarOuSubstituirNaLista(sprint);
    _notificar();
  }

  Future<bool> criarSprint({
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) async {
    final sprint = await _executar<backend.Sprint>(
      operacao: 'criar a sprint',
      executar: () => _repository.criarSprint(
        nome: nome,
        dataInicio: dataInicio,
        dataFim: dataFim,
        tempoPrevistoMinutos: tempoPrevistoMinutos,
      ),
    );
    if (sprint == null) return false;
    _atualizarSprint(sprint);
    return true;
  }

  Future<bool> atualizarSprint({
    required int id,
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) async {
    final sprint = await _executar<backend.Sprint>(
      operacao: 'atualizar a sprint',
      executar: () => _repository.atualizarSprint(
        id: id,
        nome: nome,
        dataInicio: dataInicio,
        dataFim: dataFim,
        tempoPrevistoMinutos: tempoPrevistoMinutos,
      ),
    );
    if (sprint == null) return false;
    _atualizarSprint(sprint);
    return true;
  }

  Future<bool> ativarSprint(int id) =>
      _alterarStatus(id, 'ativar a sprint', _repository.ativarSprint);

  Future<bool> cancelarSprint(int id) =>
      _alterarStatus(id, 'cancelar a sprint', _repository.cancelarSprint);

  Future<bool> reabrirSprint(int id) =>
      _alterarStatus(id, 'reabrir a sprint', _repository.reabrirSprint);

  Future<bool> _alterarStatus(
    int id,
    String operacao,
    Future<backend.Sprint> Function(int id) executar,
  ) async {
    final sprint = await _executar<backend.Sprint>(
      operacao: operacao,
      executar: () => executar(id),
    );
    if (sprint == null) return false;
    if (sprint.status == backend.SprintStatus.cancelada) {
      _vinculos = const [];
      _resumoConclusao = null;
      _resultadoConclusao = null;
      _indicadores = null;
    }
    _atualizarSprint(sprint);
    return true;
  }

  Future<bool> carregarIndicadores(int id) async {
    final indicadores = await _executar<backend.SprintIndicadores>(
      operacao: 'carregar os indicadores da sprint',
      carregar: true,
      executar: () => _repository.calcularIndicadoresSprint(id),
    );
    if (indicadores == null) return false;
    _indicadores = indicadores;
    _indicadoresPorSprint[id] = indicadores;
    _notificar();
    return true;
  }

  Future<bool> carregarIndicadoresDaLista() async {
    final ids = _sprints.map((sprint) => sprint.id).whereType<int>().toList();
    final indicadores = await _executar<Map<int, backend.SprintIndicadores>>(
      operacao: 'carregar os indicadores das sprints',
      carregar: true,
      executar: () async {
        final resultado = <int, backend.SprintIndicadores>{};
        for (final id in ids) {
          resultado[id] = await _repository.calcularIndicadoresSprint(id);
        }
        return resultado;
      },
    );
    if (indicadores == null) return false;

    _indicadoresPorSprint
      ..clear()
      ..addAll(indicadores);
    final idSelecionado = _sprintSelecionada?.id;
    if (idSelecionado != null) {
      _indicadores = indicadores[idSelecionado];
    }
    _notificar();
    return true;
  }

  Future<bool> carregarResumoConclusao(int id) async {
    final resumo = await _executar<backend.SprintConclusaoResponse>(
      operacao: 'carregar o resumo de conclusão da sprint',
      carregar: true,
      executar: () => _repository.obterResumoConclusaoSprint(id),
    );
    if (resumo == null) return false;
    _resumoConclusao = resumo;
    _indicadores = resumo.indicadores;
    _atualizarSprint(resumo.sprint);
    return true;
  }

  Future<bool> concluirSprint(int id) async {
    final resultado = await _executar<backend.SprintConclusaoResponse>(
      operacao: 'concluir a sprint',
      executar: () => _repository.concluirSprint(id),
    );
    if (resultado == null) return false;
    _resultadoConclusao = resultado;
    _resumoConclusao = resultado;
    _indicadores = resultado.indicadores;
    _atualizarSprint(resultado.sprint);
    return true;
  }

  Future<bool> vincularDemanda({
    required int sprintId,
    required int demandaId,
  }) async {
    final vinculos = await _executar<List<backend.SprintDemanda>>(
      operacao: 'vincular a demanda à sprint',
      executar: () =>
          _repository.vincularDemanda(sprintId: sprintId, demandaId: demandaId),
    );
    if (vinculos == null) return false;
    _vinculos = List.unmodifiable(vinculos);
    _notificar();
    return true;
  }

  Future<bool> vincularDemandas({
    required int sprintId,
    required List<int> demandaIds,
  }) async {
    if (demandaIds.isEmpty) return false;
    final vinculos = await _executar<List<backend.SprintDemanda>>(
      operacao: 'vincular as Demandas à sprint',
      executar: () => _repository.vincularDemandas(
        sprintId: sprintId,
        demandaIds: demandaIds,
      ),
    );
    if (vinculos == null) return false;
    _vinculos = List.unmodifiable(vinculos);
    _notificar();
    return true;
  }

  Future<bool> desvincularDemanda({
    required int sprintId,
    required int demandaId,
  }) async {
    final desvinculada = await _executar<bool>(
      operacao: 'desvincular a demanda da sprint',
      executar: () => _repository.desvincularDemanda(
        sprintId: sprintId,
        demandaId: demandaId,
      ),
    );
    if (desvinculada != true) return false;
    // O backend pode remover também todos os descendentes da demanda.
    _vinculos = const [];
    _notificar();
    return true;
  }

  Future<bool> excluirSprint(int id) async {
    final excluida = await _executar<bool>(
      operacao: 'excluir a sprint',
      executar: () => _repository.excluirSprint(id),
    );
    if (excluida != true) return false;
    _sprints.removeWhere((sprint) => sprint.id == id);
    if (_sprintSelecionada?.id == id) _limparSelecao();
    _notificar();
    return true;
  }

  Future<T?> _executar<T>({
    required String operacao,
    required Future<T> Function() executar,
    bool carregar = false,
  }) async {
    if (_descartado || _enviando || _carregando) return null;
    if (carregar) {
      _carregando = true;
    } else {
      _enviando = true;
    }
    _erro = null;
    _notificar();

    try {
      return await executar();
    } catch (error, stackTrace) {
      debugPrint('[SprintViewModel] Falha ao $operacao: $error');
      debugPrintStack(stackTrace: stackTrace);
      _erro = _mensagemDaFalha(error, operacao);
      return null;
    } finally {
      if (!_descartado) {
        _carregando = false;
        _enviando = false;
        _notificar();
      }
    }
  }

  String _mensagemDaFalha(Object error, String operacao) {
    if (error case final backend.SprintException erro) {
      return switch (erro.codigo) {
        backend.SprintErroCodigo.nomeObrigatorio =>
          'Informe um nome para a Sprint.',
        backend.SprintErroCodigo.nomeDuplicado =>
          'Já existe uma Sprint com esse nome.',
        backend.SprintErroCodigo.periodoInvalido =>
          'A data de início não pode ser posterior à data de fim.',
        backend.SprintErroCodigo.periodoSobreposto =>
          'O período informado entra em conflito com outra Sprint.',
        backend.SprintErroCodigo.sprintNaoEncontrada =>
          'A Sprint não foi encontrada ou já foi removida.',
        backend.SprintErroCodigo.sprintAtivaExistente =>
          'Já existe uma Sprint ativa.',
        backend.SprintErroCodigo.inicioAntesDataInicio =>
          'A Sprint só pode ser iniciada a partir da data de início.',
        backend.SprintErroCodigo.tempoPrevistoInvalido =>
          'Informe um tempo previsto maior que zero para iniciar a Sprint.',
        backend.SprintErroCodigo.transicaoStatusInvalida =>
          'Essa transição de status não é permitida para a Sprint.',
        backend.SprintErroCodigo.demandaOutraSprintAberta =>
          'Esta Demanda já pertence a outra Sprint em aberto.',
        backend.SprintErroCodigo.vinculoStatusProibido =>
          'A Sprint não permite alterações de vínculo neste status.',
        backend.SprintErroCodigo.demandaFilhaSemMae =>
          'A Demanda filha só pode ser vinculada com a Demanda mãe na mesma Sprint.',
        backend.SprintErroCodigo.demandaFilhaComMaeVinculada =>
          'A Demanda filha não pode ser desvinculada enquanto a Demanda mãe permanecer vinculada.',
        backend.SprintErroCodigo.demandaNaoEncontrada =>
          'A Demanda não foi encontrada ou já foi removida.',
        backend.SprintErroCodigo.historicoSprintConcluida =>
          'Esta Demanda não pode ser excluída porque possui histórico em uma Sprint concluída.',
      };
    }
    if (error is backend.ServerpodClientException && error.statusCode == -1) {
      return 'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
    }
    return 'Não foi possível $operacao. Tente novamente.';
  }

  void _atualizarSprint(backend.Sprint sprint) {
    _adicionarOuSubstituirNaLista(sprint);
    _sprintSelecionada = sprint;
    _notificar();
  }

  void _adicionarOuSubstituirNaLista(backend.Sprint sprint) {
    final id = sprint.id;
    if (id != null) {
      final index = _sprints.indexWhere((atual) => atual.id == id);
      if (index == -1) {
        _sprints.add(sprint);
      } else {
        _sprints[index] = sprint;
      }
    }
  }

  void _limparSelecao() {
    _sprintSelecionada = null;
    _resumoConclusao = null;
    _resultadoConclusao = null;
    _indicadores = null;
    _vinculos = const [];
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }
}
