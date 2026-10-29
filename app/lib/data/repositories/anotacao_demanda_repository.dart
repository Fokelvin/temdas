import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;
import '../serverpod_client.dart';

class AnotacaoDemandaRepository {
  AnotacaoDemandaRepository({backend.Client? client})
    : _client = client ?? serverpodClient;
  final backend.Client _client;
  Future<List<backend.AnotacaoDemanda>> listar(int demandaId) =>
      _client.anotacaoDemanda.listar(demandaId);
  Future<backend.AnotacaoDemanda> criar(int demandaId, String conteudo) =>
      _client.anotacaoDemanda.criar(demandaId, conteudo);
  Future<backend.AnotacaoDemanda> editar(int id, String conteudo) =>
      _client.anotacaoDemanda.editar(id, conteudo);
  Future<void> excluir(int id) => _client.anotacaoDemanda.excluir(id);
}
