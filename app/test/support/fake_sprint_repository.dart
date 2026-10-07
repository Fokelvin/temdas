import 'dart:async';

import 'package:temdas/data/repositories/sprint_repository.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

class FakeSprintRepository implements SprintRepository {
  FakeSprintRepository({
    required this.sprints,
    this.indicadoresPorId = const {},
    Map<int, List<backend.SprintDemanda>> vinculosPorSprint = const {},
  }) {
    _inicializarVinculos(vinculosPorSprint);
  }

  final List<backend.Sprint> sprints;
  final Map<int, backend.SprintIndicadores> indicadoresPorId;
  final Map<int, List<backend.SprintDemanda>> vinculosPorSprint = {};
  Completer<List<backend.Sprint>>? listaPendente;
  Object? erroListagem;
  Object? erroIndicadores;
  Object? erroCriacao;
  Object? erroAtualizacao;
  Object? erroAtivacao;
  Object? erroCancelamento;
  Object? erroReabertura;
  Object? erroResumoConclusao;
  Object? erroConclusao;
  Object? erroExclusao;
  Object? erroVinculo;
  Object? erroDesvinculo;
  List<backend.SprintDemanda>? respostaVinculo;
  List<int>? demandaIdsVinculadas;
  Completer<void>? criacaoPendente;
  int chamadasListagem = 0;
  int chamadasBusca = 0;
  int chamadasVinculos = 0;
  int chamadasIndicadores = 0;
  int chamadasCriacao = 0;
  int chamadasAtualizacao = 0;
  int chamadasAtivacao = 0;
  int chamadasCancelamento = 0;
  int chamadasReabertura = 0;
  int chamadasResumoConclusao = 0;
  int chamadasConclusao = 0;
  int chamadasExclusao = 0;
  int chamadasVinculo = 0;
  int chamadasVinculoLote = 0;
  int chamadasDesvinculo = 0;
  int? sprintIdVinculada;
  int? demandaIdVinculada;
  int? sprintIdDesvinculada;
  int? demandaIdDesvinculada;
  String? nomeEnviado;
  DateTime? dataInicioEnviada;
  DateTime? dataFimEnviada;
  int? tempoPrevistoEnviado;
  String? nomeAtualizado;
  int _proximoId = 100;

  void _inicializarVinculos(Map<int, List<backend.SprintDemanda>> iniciais) {
    for (final entrada in iniciais.entries) {
      vinculosPorSprint[entrada.key] = List.of(entrada.value);
    }
  }

  @override
  Future<List<backend.Sprint>> listarSprints() {
    chamadasListagem++;
    if (erroListagem case final erro?) return Future.error(erro);
    return listaPendente?.future ?? Future.value(sprints);
  }

  @override
  Future<backend.Sprint> buscarSprintPorId(int id) async {
    chamadasBusca++;
    final resultados = sprints.where((sprint) => sprint.id == id);
    if (resultados.isEmpty) throw StateError('Sprint não encontrada.');
    return resultados.first;
  }

  backend.Sprint _porId(int id) =>
      sprints.firstWhere((sprint) => sprint.id == id);

  void _substituir(backend.Sprint sprint) {
    final indice = sprints.indexWhere((atual) => atual.id == sprint.id);
    if (indice == -1) {
      sprints.add(sprint);
    } else {
      sprints[indice] = sprint;
    }
  }

  @override
  Future<List<backend.SprintDemanda>> listarDemandasDaSprint(int sprintId) {
    chamadasVinculos++;
    return Future.value(vinculosPorSprint[sprintId] ?? const []);
  }

  @override
  Future<backend.SprintIndicadores> calcularIndicadoresSprint(int id) async {
    chamadasIndicadores++;
    if (erroIndicadores case final erro?) throw erro;
    return indicadoresPorId[id] ??
        backend.SprintIndicadores(
          tempoPrevistoMinutos: 0,
          tempoTotalEstimadoMinutos: 0,
          tempoExecutadoMinutos: 0,
          diferencaExecutadoEstimadoMinutos: 0,
        );
  }

  @override
  Future<backend.Sprint> criarSprint({
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) async {
    chamadasCriacao++;
    await criacaoPendente?.future;
    if (erroCriacao case final erro?) throw erro;
    nomeEnviado = nome;
    dataInicioEnviada = dataInicio;
    dataFimEnviada = dataFim;
    tempoPrevistoEnviado = tempoPrevistoMinutos;
    final sprint = backend.Sprint(
      usuarioId: 1,
      id: _proximoId++,
      nome: nome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos,
      status: backend.SprintStatus.planejada,
    );
    sprints.add(sprint);
    return sprint;
  }

  @override
  Future<backend.Sprint> atualizarSprint({
    required int id,
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) async {
    chamadasAtualizacao++;
    if (erroAtualizacao case final erro?) throw erro;
    nomeAtualizado = nome;
    tempoPrevistoEnviado = tempoPrevistoMinutos;
    final atualizada = _porId(id).copyWith(
      nome: nome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos,
    );
    _substituir(atualizada);
    return atualizada;
  }

  @override
  Future<backend.Sprint> ativarSprint(int id) async {
    chamadasAtivacao++;
    if (erroAtivacao case final erro?) throw erro;
    if (sprints.any(
      (sprint) =>
          sprint.id != id && sprint.status == backend.SprintStatus.ativa,
    )) {
      throw StateError('Já existe outra Sprint ativa.');
    }
    return _mudarStatus(id, backend.SprintStatus.ativa);
  }

  @override
  Future<backend.Sprint> cancelarSprint(int id) async {
    chamadasCancelamento++;
    if (erroCancelamento case final erro?) throw erro;
    return _mudarStatus(id, backend.SprintStatus.cancelada);
  }

  @override
  Future<backend.Sprint> reabrirSprint(int id) async {
    chamadasReabertura++;
    if (erroReabertura case final erro?) throw erro;
    return _mudarStatus(id, backend.SprintStatus.planejada);
  }

  Future<backend.Sprint> _mudarStatus(
    int id,
    backend.SprintStatus status,
  ) async {
    final atualizada = _porId(id).copyWith(status: status);
    _substituir(atualizada);
    return atualizada;
  }

  @override
  Future<backend.SprintConclusaoResponse> obterResumoConclusaoSprint(
    int id,
  ) async {
    chamadasResumoConclusao++;
    if (erroResumoConclusao case final erro?) throw erro;
    return _respostaConclusao(_porId(id));
  }

  @override
  Future<backend.SprintConclusaoResponse> concluirSprint(int id) async {
    chamadasConclusao++;
    if (erroConclusao case final erro?) throw erro;
    final sprint = _porId(id).copyWith(status: backend.SprintStatus.concluida);
    _substituir(sprint);
    return _respostaConclusao(sprint);
  }

  backend.SprintConclusaoResponse _respostaConclusao(backend.Sprint sprint) =>
      backend.SprintConclusaoResponse(
        sprint: sprint,
        quantidadeDemandasNaoConcluidas: 2,
        indicadores:
            indicadoresPorId[sprint.id] ??
            backend.SprintIndicadores(
              tempoPrevistoMinutos: sprint.tempoPrevistoMinutos,
              tempoTotalEstimadoMinutos: 180,
              tempoExecutadoMinutos: 150,
              diferencaExecutadoEstimadoMinutos: -30,
            ),
      );

  @override
  Future<bool> excluirSprint(int id) async {
    chamadasExclusao++;
    if (erroExclusao case final erro?) throw erro;
    final antes = sprints.length;
    sprints.removeWhere((sprint) => sprint.id == id);
    return sprints.length != antes;
  }

  @override
  Future<List<backend.SprintDemanda>> vincularDemanda({
    required int sprintId,
    required int demandaId,
  }) async {
    chamadasVinculo++;
    sprintIdVinculada = sprintId;
    demandaIdVinculada = demandaId;
    if (erroVinculo case final erro?) throw erro;
    final atuais =
        respostaVinculo ??
        [
          ...?vinculosPorSprint[sprintId],
          backend.SprintDemanda(
            id: (_proximoId++),
            sprintId: sprintId,
            demandaId: demandaId,
          ),
        ];
    final copia = List<backend.SprintDemanda>.of(atuais);
    vinculosPorSprint[sprintId] = copia;
    return copia;
  }

  @override
  Future<List<backend.SprintDemanda>> vincularDemandas({
    required int sprintId,
    required List<int> demandaIds,
  }) async {
    chamadasVinculoLote++;
    demandaIdsVinculadas = List.of(demandaIds);
    if (erroVinculo case final erro?) throw erro;
    final atuais = respostaVinculo == null
        ? [
            ...?vinculosPorSprint[sprintId],
            for (final demandaId in demandaIds)
              backend.SprintDemanda(
                id: (_proximoId++),
                sprintId: sprintId,
                demandaId: demandaId,
              ),
          ]
        : List<backend.SprintDemanda>.of(respostaVinculo!);
    vinculosPorSprint[sprintId] = atuais;
    return atuais;
  }

  @override
  Future<bool> desvincularDemanda({
    required int sprintId,
    required int demandaId,
  }) async {
    chamadasDesvinculo++;
    sprintIdDesvinculada = sprintId;
    demandaIdDesvinculada = demandaId;
    if (erroDesvinculo case final erro?) throw erro;
    final atuais = List<backend.SprintDemanda>.of(
      vinculosPorSprint[sprintId] ?? const [],
    );
    final tamanhoAnterior = atuais.length;
    atuais.removeWhere((item) => item.demandaId == demandaId);
    vinculosPorSprint[sprintId] = atuais;
    return atuais.length != tamanhoAnterior;
  }
}
