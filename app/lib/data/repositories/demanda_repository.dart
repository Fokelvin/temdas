import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../serverpod_client.dart';

class DemandaRepository {
  DemandaRepository({backend.Client? client})
    : _client = client ?? serverpodClient;

  final backend.Client _client;

  Future<backend.Demanda> criarDemanda({
    required String titulo,
    required int tempoEstimadoMinutos,
    int? demandaPaiId,
    String? descricao,
    backend.Prioridade? prioridade,
    String? sprint,
    String? observacoes,
  }) {
    final request = backend.DemandaCreateRequest(
      demandaPaiId: demandaPaiId,
      titulo: titulo,
      descricao: descricao,
      prioridade: prioridade,
      sprint: sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
      observacoes: observacoes,
    );

    return _client.demanda.criarDemanda(request);
  }

  Future<backend.Demanda> atualizarDemanda({
    required int id,
    required String titulo,
    String? descricao,
    required backend.DemandaStatus status,
    required backend.Prioridade prioridade,
    String? sprint,
    required int tempoEstimadoMinutos,
    String? observacoes,
  }) {
    final request = backend.DemandaUpdateRequest(
      id: id,
      titulo: titulo,
      descricao: descricao,
      status: status,
      prioridade: prioridade,
      sprint: sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
      observacoes: observacoes,
    );

    return _client.demanda.atualizarDemanda(request);
  }

  Future<List<backend.Demanda>> listarDemandas() {
    return _client.demanda.listarDemandas();
  }

  Future<backend.Demanda?> buscarDemandaPorId(int id) {
    return _client.demanda.buscarDemandaPorId(id);
  }

  Future<bool> excluirDemanda(int id) {
    return _client.demanda.excluirDemanda(id);
  }

  Future<bool> excluirArvoreDemanda(int id) {
    return _client.demanda.excluirArvoreDemanda(id);
  }
}
