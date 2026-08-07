import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../serverpod_client.dart';

class DemandaRepository {
  DemandaRepository({backend.Client? client})
    : _client = client ?? serverpodClient;

  final backend.Client _client;

  Future<backend.Demanda> criarDemanda({
    required String titulo,
    required int tempoEstimadoMinutos,
    String? descricao,
    backend.Prioridade? prioridade,
    String? sprint,
    String? observacoes,
  }) {
    final request = backend.DemandaCreateRequest(
      titulo: titulo,
      descricao: descricao,
      prioridade: prioridade,
      sprint: sprint,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
      observacoes: observacoes,
    );

    return _client.demanda.criarDemanda(request);
  }

  Future<List<backend.Demanda>> listarDemandas() {
    return _client.demanda.listarDemandas();
  }
}
