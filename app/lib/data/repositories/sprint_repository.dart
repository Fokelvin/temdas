import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../serverpod_client.dart';

class SprintRepository {
  SprintRepository({backend.Client? client})
    : _client = client ?? serverpodClient;

  final backend.Client _client;

  Future<List<backend.Sprint>> listarSprints() =>
      _client.sprint.listarSprints();

  Future<backend.Sprint> buscarSprintPorId(int id) =>
      _client.sprint.buscarSprintPorId(id);

  Future<List<backend.SprintDemanda>> listarDemandasDaSprint(int sprintId) =>
      _client.sprint.listarDemandasDaSprint(sprintId);

  Future<backend.Sprint> criarSprint({
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) => _client.sprint.criarSprint(
    backend.SprintCreateRequest(
      nome: nome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos,
    ),
  );

  Future<backend.Sprint> atualizarSprint({
    required int id,
    required String nome,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? tempoPrevistoMinutos,
  }) => _client.sprint.atualizarSprint(
    backend.SprintUpdateRequest(
      id: id,
      nome: nome,
      dataInicio: dataInicio,
      dataFim: dataFim,
      tempoPrevistoMinutos: tempoPrevistoMinutos,
    ),
  );

  Future<backend.Sprint> ativarSprint(int id) =>
      _client.sprint.ativarSprint(id);

  Future<backend.Sprint> cancelarSprint(int id) =>
      _client.sprint.cancelarSprint(id);

  Future<backend.Sprint> reabrirSprint(int id) =>
      _client.sprint.reabrirSprint(id);

  Future<backend.SprintConclusaoResponse> obterResumoConclusaoSprint(int id) =>
      _client.sprint.obterResumoConclusaoSprint(id);

  Future<backend.SprintConclusaoResponse> concluirSprint(int id) =>
      _client.sprint.concluirSprint(id);

  Future<backend.SprintIndicadores> calcularIndicadoresSprint(int id) =>
      _client.sprint.calcularIndicadoresSprint(id);

  Future<bool> excluirSprint(int id) => _client.sprint.excluirSprint(id);

  Future<List<backend.SprintDemanda>> vincularDemanda({
    required int sprintId,
    required int demandaId,
  }) => _client.sprint.vincularDemanda(sprintId, demandaId);

  Future<List<backend.SprintDemanda>> vincularDemandas({
    required int sprintId,
    required List<int> demandaIds,
  }) => _client.sprint.vincularDemandas(sprintId, demandaIds);

  Future<bool> desvincularDemanda({
    required int sprintId,
    required int demandaId,
  }) => _client.sprint.desvincularDemanda(sprintId, demandaId);
}
