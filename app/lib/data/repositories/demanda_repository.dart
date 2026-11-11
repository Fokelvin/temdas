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
    backend.DemandaLocalizacao? localizacao,
  }) {
    final request = backend.DemandaCreateRequest(
      demandaPaiId: demandaPaiId,
      localizacao: localizacao,
      titulo: titulo,
      descricao: descricao,
      prioridade: prioridade,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
    );

    return _client.demanda.criarDemanda(request);
  }

  Future<backend.Demanda> atualizarDemanda({
    required int id,
    required String titulo,
    String? descricao,
    required backend.DemandaStatus status,
    String? motivoCancelamento,
    required backend.Prioridade prioridade,
    required int tempoEstimadoMinutos,
  }) {
    final request = backend.DemandaUpdateRequest(
      id: id,
      titulo: titulo,
      descricao: descricao,
      status: status,
      motivoCancelamento: motivoCancelamento,
      prioridade: prioridade,
      tempoEstimadoMinutos: tempoEstimadoMinutos,
    );

    return _client.demanda.atualizarDemanda(request);
  }

  Future<backend.Demanda> alterarStatusDemanda({
    required int id,
    required backend.DemandaStatus status,
    String? motivoCancelamento,
  }) => _client.demanda.alterarStatusDemanda(
    id,
    status,
    motivoCancelamento: motivoCancelamento,
  );

  Future<backend.Demanda> moverDemanda({
    required int demandaId,
    required backend.DemandaStatus statusDestino,
    required int posicaoDestino,
  }) => _client.demanda.moverDemanda(
    backend.DemandaMovimentacaoRequest(
      demandaId: demandaId,
      statusDestino: statusDestino,
      posicaoDestino: posicaoDestino,
    ),
  );

  Future<backend.Demanda> concluirDemanda(int id) =>
      alterarStatusDemanda(id: id, status: backend.DemandaStatus.concluida);

  Future<backend.Demanda> concluirDemandaEmCascata(int id) =>
      _client.demanda.concluirDemandaEmCascata(id);

  Future<backend.Demanda> cancelarDemandaEmCascata(int id, String motivo) =>
      _client.demanda.cancelarDemandaEmCascata(id, motivo);

  Future<List<backend.Demanda>> listarDemandas({
    backend.DemandaLocalizacao? localizacao,
    bool? incluirBacklog,
  }) => _client.demanda.listarDemandas(
    localizacao: localizacao,
    incluirBacklog: incluirBacklog,
  );

  Future<backend.BacklogPrevia> preverEnvioAoBacklog(int id) =>
      _client.demanda.preverEnvioAoBacklog(id);

  Future<void> alterarLocalizacao(
    int id,
    backend.DemandaLocalizacao destino,
    List<int> vinculosConfirmados,
  ) => _client.demanda.alterarLocalizacao(id, destino, vinculosConfirmados);

  Future<List<backend.Demanda>> buscarDemandasGlobalmente(String consulta) =>
      _client.demanda.buscarDemandasGlobalmente(consulta);

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
