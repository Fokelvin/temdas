import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../serverpod_client.dart';

class RelatorioRepository {
  RelatorioRepository({backend.Client? client})
    : _client = client ?? serverpodClient;

  final backend.Client _client;

  Future<backend.RelatorioDemandasResponse> gerarRelatorio(
    backend.RelatorioDemandaRequest request,
  ) => _client.relatorio.gerarRelatorioDemandas(request);
}
