import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../serverpod_client.dart';

class RegistroTempoRepository {
  RegistroTempoRepository({backend.Client? client})
    : _client = client ?? serverpodClient;

  final backend.Client _client;

  Future<backend.RegistroTempo> registrarTempo({
    required int demandaId,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) {
    final request = backend.RegistroTempoCreateRequest(
      demandaId: demandaId,
      inicioEm: inicioEm,
      duracaoMinutos: duracaoMinutos,
    );

    return _client.registroTempo.registrarTempo(request);
  }

  Future<backend.RegistroTempo> editarRegistroTempo({
    required int id,
    required DateTime inicioEm,
    required int duracaoMinutos,
  }) {
    final request = backend.RegistroTempoUpdateRequest(
      id: id,
      inicioEm: inicioEm,
      duracaoMinutos: duracaoMinutos,
    );

    return _client.registroTempo.editarRegistroTempo(request);
  }

  Future<List<backend.RegistroTempo>> listarPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) {
    return _client.registroTempo.listarRegistrosTempoPorPeriodo(inicio, fim);
  }

  Future<List<backend.RegistroTempo>> listarDaDemanda(int demandaId) {
    return _client.registroTempo.listarRegistrosTempoDaDemanda(demandaId);
  }

  Future<bool> excluirRegistroTempo(int id) {
    return _client.registroTempo.excluirRegistroTempo(id);
  }
}
