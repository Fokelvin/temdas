import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'demanda_status_service.dart';
import 'demanda_ordem_service.dart';

class DemandaEndpoint extends Endpoint {
  final _statusService = DemandaStatusService();
  final _ordemService = DemandaOrdemService();

  Future<Demanda> alterarStatusDemanda(
    Session session,
    int id,
    DemandaStatus status, {
    String? motivoCancelamento,
  }) => _statusService.alterarStatus(
    session,
    id,
    status,
    motivoCancelamento: motivoCancelamento,
  );

  Future<Demanda> concluirDemandaEmCascata(Session session, int id) =>
      _statusService.concluirEmCascata(session, id);

  Future<Demanda> cancelarDemandaEmCascata(
    Session session,
    int id,
    String motivoCancelamento,
  ) => _statusService.cancelarEmCascata(session, id, motivoCancelamento);

  Future<Demanda> moverDemanda(
    Session session,
    DemandaMovimentacaoRequest request,
  ) => _ordemService.mover(session, request);

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

    final demandaCriada = await session.db.transaction((transaction) async {
      if (request.demandaPaiId case final demandaPaiId?) {
        final demandaPai = await Demanda.db.findById(
          session,
          demandaPaiId,
          transaction: transaction,
          lockMode: LockMode.forKeyShare,
        );

        if (demandaPai == null) {
          throw Exception('Demanda mãe não encontrada.');
        }
      }

      final agora = DateTime.now().toUtc();
      final ordem = request.demandaPaiId == null
          ? await _proximaOrdem(session, transaction)
          : null;

      final demanda = Demanda(
        demandaPaiId: request.demandaPaiId,
        ordem: ordem,
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

      return Demanda.db.insertRow(
        session,
        demanda,
        transaction: transaction,
      );
    });

    session.log(
      'Demanda criada: id=${demandaCriada.id}, '
      'demandaPaiId=${demandaCriada.demandaPaiId}.',
    );
    return demandaCriada;
  }

  Future<List<Demanda>> listarDemandas(Session session) async {
    final demandas = await Demanda.db.find(
      session,
      orderBy: (t) => t.criadoEm,
      orderDescending: true,
    );
    final raizes = demandas.where((d) => d.demandaPaiId == null).toList()
      ..sort((a, b) {
        final status = a.status.index.compareTo(b.status.index);
        if (status != 0) return status;
        final ordem = (a.ordem ?? 1 << 30).compareTo(b.ordem ?? 1 << 30);
        return ordem == 0 ? b.criadoEm.compareTo(a.criadoEm) : ordem;
      });
    final filhas = demandas.where((d) => d.demandaPaiId != null);
    return [...raizes, ...filhas];
  }

  Future<int> _proximaOrdem(Session session, Transaction transaction) async {
    final raizes = await Demanda.db.find(
      session,
      where: (t) =>
          t.demandaPaiId.equals(null) & t.status.equals(DemandaStatus.aberta),
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    final maior = raizes.fold<int>(
      -1,
      (atual, demanda) => demanda.ordem != null && demanda.ordem! > atual
          ? demanda.ordem!
          : atual,
    );
    return maior + 1;
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

    final demandaAtualizada = await session.db.transaction((transaction) async {
      final demandaAtual = await Demanda.db.findById(
        session,
        request.id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (demandaAtual == null) {
        throw TransicaoStatusException(
          codigo: TransicaoStatusErroCodigo.demandaNaoEncontrada,
          mensagem: 'Demanda não encontrada.',
        );
      }

      if (demandaAtual.status != request.status) {
        await _statusService.alterarStatus(
          session,
          request.id,
          request.status,
          motivoCancelamento: request.motivoCancelamento,
          transaction: transaction,
        );
      }

      final demandaAtualizada = await Demanda.db.updateById(
        session,
        request.id,
        columnValues: (t) => [
          t.titulo(titulo),
          t.descricao(_normalizarTextoOpcional(request.descricao)),
          t.prioridade(request.prioridade),
          t.sprint(_normalizarTextoOpcional(request.sprint)),
          t.tempoEstimadoMinutos(request.tempoEstimadoMinutos),
          t.observacoes(_normalizarTextoOpcional(request.observacoes)),
          t.atualizadoEm(DateTime.now().toUtc()),
        ],
        transaction: transaction,
      );

      if (demandaAtualizada == null) {
        throw Exception('Demanda não encontrada.');
      }

      return demandaAtualizada;
    });

    session.log('Demanda atualizada: id=${demandaAtualizada.id}.');
    return demandaAtualizada;
  }

  Future<bool> excluirDemanda(
    Session session,
    int id,
  ) async {
    final excluida = await session.db.transaction((transaction) async {
      final demanda = await Demanda.db.findById(
        session,
        id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (demanda == null) {
        return false;
      }

      final filha = await Demanda.db.findFirstRow(
        session,
        where: (t) => t.demandaPaiId.equals(id),
        transaction: transaction,
      );

      if (filha != null) {
        throw Exception(
          'A demanda possui descendentes. Confirme a exclusão da árvore inteira.',
        );
      }

      await Demanda.db.deleteRow(
        session,
        demanda,
        transaction: transaction,
      );
      return true;
    });

    if (excluida) {
      session.log('Demanda folha excluída: id=$id.');
    }
    return excluida;
  }

  Future<bool> excluirArvoreDemanda(
    Session session,
    int id,
  ) async {
    final excluida = await session.db.transaction((transaction) async {
      final demandaRaiz = await Demanda.db.findById(
        session,
        id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (demandaRaiz == null) {
        return false;
      }

      await Demanda.db.deleteRow(
        session,
        demandaRaiz,
        transaction: transaction,
      );
      return true;
    });

    if (excluida) {
      session.log('Árvore de demandas excluída: raizId=$id.');
    }
    return excluida;
  }

  String? _normalizarTextoOpcional(String? valor) {
    final texto = valor?.trim();

    if (texto == null || texto.isEmpty) {
      return null;
    }

    return texto;
  }
}
