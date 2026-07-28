import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class DemandaEndpoint extends Endpoint {
  Future<Demanda> criarDemanda(
    Session session,
    DemandaCreateRequest request,
  ) async {
    final titulo = request.titulo.trim();

    if (titulo.isEmpty) {
      throw Exception('O título da demanda é obrigatório.');
    }

    if (request.tempoEstimadoMinutos < 0) {
      throw Exception('O tempo estimado não pode ser negativo.');
    }

    if (request.tempoEstimadoMinutos % 30 != 0) {
      throw Exception(
        'O tempo estimado deve ser informado em intervalos de 30 minutos.',
      );
    }

    final agora = DateTime.now().toUtc();

    final demanda = Demanda(
      titulo: titulo,
      descricao: _normalizarTextoOpcional(request.descricao),
      status: DemandaStatus.aberta,
      prioridade: request.prioridade ?? Prioridade.media,
      sprint: _normalizarTextoOpcional(request.sprint),
      tempoEstimadoMinutos: request.tempoEstimadoMinutos,
      tempoExecutadoMinutos: 0,
      observacoes: _normalizarTextoOpcional(request.observacoes),
      criadoEm: agora,
      atualizadoEm: agora,
      concluidoEm: null,
    );

    return Demanda.db.insertRow(session, demanda);
  }

  Future<List<Demanda>> listarDemandas(Session session) async {
    return Demanda.db.find(
      session,
      orderBy: (t) => t.criadoEm,
      orderDescending: true,
    );
  }

  Future<Demanda?> buscarDemandaPorId(
    Session session,
    int id,
  ) async {
    return Demanda.db.findById(session, id);
  }

  Future<Demanda> atualizarDemanda(
    Session session,
    DemandaUpdateRequest request,
  ) async {
    final demandaAtual = await Demanda.db.findById(session, request.id);

    if (demandaAtual == null) {
      throw Exception('Demanda não encontrada.');
    }

    final titulo = request.titulo.trim();

    if (titulo.isEmpty) {
      throw Exception('O título da demanda é obrigatório.');
    }

    if (request.tempoEstimadoMinutos < 0) {
      throw Exception('O tempo estimado não pode ser negativo.');
    }

    if (request.tempoEstimadoMinutos % 30 != 0) {
      throw Exception(
        'O tempo estimado deve ser informado em intervalos de 30 minutos.',
      );
    }

    final agora = DateTime.now().toUtc();

    final concluidoEm = request.status == DemandaStatus.concluida
        ? demandaAtual.concluidoEm ?? agora
        : null;

    final demandaAtualizada = demandaAtual.copyWith(
      titulo: titulo,
      descricao: _normalizarTextoOpcional(request.descricao),
      status: request.status,
      prioridade: request.prioridade,
      sprint: _normalizarTextoOpcional(request.sprint),
      tempoEstimadoMinutos: request.tempoEstimadoMinutos,
      observacoes: _normalizarTextoOpcional(request.observacoes),
      atualizadoEm: agora,
      concluidoEm: concluidoEm,
    );

    return Demanda.db.updateRow(session, demandaAtualizada);
  }

  Future<bool> excluirDemanda(
    Session session,
    int id,
  ) async {
    final demanda = await Demanda.db.findById(session, id);

    if (demanda == null) {
      return false;
    }

    await Demanda.db.deleteRow(session, demanda);
    return true;
  }

  String? _normalizarTextoOpcional(String? valor) {
    final texto = valor?.trim();

    if (texto == null || texto.isEmpty) {
      return null;
    }

    return texto;
  }
}
