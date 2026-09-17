import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'demanda_status_service.dart';

class DemandaOrdemService {
  DemandaOrdemService({DemandaStatusService? statusService})
    : _statusService = statusService ?? DemandaStatusService();

  final DemandaStatusService _statusService;

  Future<Demanda> mover(
    Session session,
    DemandaMovimentacaoRequest request,
  ) => session.db.transaction(
    (transaction) async {
      final solicitada = await Demanda.db.findById(
        session,
        request.demandaId,
        transaction: transaction,
      );
      if (solicitada == null) {
        throw MovimentacaoDemandaException(
          codigo: MovimentacaoDemandaErroCodigo.demandaNaoEncontrada,
          mensagem: 'Demanda não encontrada.',
        );
      }
      if (solicitada.demandaPaiId != null) {
        throw MovimentacaoDemandaException(
          codigo: MovimentacaoDemandaErroCodigo.demandaFilha,
          mensagem: 'Somente demandas raiz podem ser movimentadas.',
        );
      }

      // Lock all roots in a deterministic order. The volume is small and this
      // serializes reorder operations without leaving duplicate positions.
      final raizes = await Demanda.db.find(
        session,
        where: (t) => t.demandaPaiId.equals(null),
        orderBy: (t) => t.id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      final demanda = raizes.cast<Demanda?>().firstWhere(
        (item) => item?.id == request.demandaId,
        orElse: () => null,
      );
      if (demanda == null) {
        throw MovimentacaoDemandaException(
          codigo: MovimentacaoDemandaErroCodigo.demandaNaoEncontrada,
          mensagem: 'Demanda não encontrada.',
        );
      }

      if (demanda.demandaPaiId != null) {
        throw MovimentacaoDemandaException(
          codigo: MovimentacaoDemandaErroCodigo.demandaFilha,
          mensagem: 'Somente demandas raiz podem ser movimentadas.',
        );
      }

      final origem = demanda.status;
      final destino = request.statusDestino;
      if (origem != destino && (_terminal(origem) || _terminal(destino))) {
        throw MovimentacaoDemandaException(
          codigo: MovimentacaoDemandaErroCodigo.statusTerminal,
          mensagem:
              'Concluída e Cancelada só podem ser reordenadas dentro da própria coluna.',
        );
      }

      final porOrigem = _ordenadas(raizes, origem);
      final porDestino = origem == destino
          ? porOrigem
          : _ordenadas(raizes, destino);
      porOrigem.remove(demanda);
      final listaDestino = porDestino;
      final posicao = request.posicaoDestino.clamp(0, listaDestino.length);
      listaDestino.insert(posicao, demanda);

      if (origem != destino) {
        await _statusService.alterarStatus(
          session,
          demanda.id!,
          destino,
          transaction: transaction,
        );
        demanda.status = destino;
      }

      await _renumerar(session, porOrigem, transaction);
      if (origem != destino) {
        await _renumerar(session, listaDestino, transaction);
      }

      return (await Demanda.db.findById(
        session,
        demanda.id!,
        transaction: transaction,
      ))!;
    },
  );

  List<Demanda> _ordenadas(List<Demanda> demandas, DemandaStatus status) {
    final resultado = demandas.where((d) => d.status == status).toList();
    resultado.sort((a, b) {
      final ordemA = a.ordem;
      final ordemB = b.ordem;
      if (ordemA != null && ordemB != null) {
        final comparacao = ordemA.compareTo(ordemB);
        if (comparacao != 0) return comparacao;
      } else if (ordemA != null) {
        return -1;
      } else if (ordemB != null) {
        return 1;
      }
      return b.criadoEm.compareTo(a.criadoEm);
    });
    return resultado;
  }

  Future<void> _renumerar(
    Session session,
    List<Demanda> demandas,
    Transaction transaction,
  ) async {
    for (var index = 0; index < demandas.length; index++) {
      await Demanda.db.updateById(
        session,
        demandas[index].id!,
        columnValues: (t) => [t.ordem(index)],
        transaction: transaction,
      );
    }
  }

  bool _terminal(DemandaStatus status) =>
      status == DemandaStatus.concluida || status == DemandaStatus.cancelada;
}
