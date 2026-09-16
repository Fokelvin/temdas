import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Fonte de verdade das transições, compartilhada pelo update e pelas cascatas.
class DemandaStatusService {
  Future<Demanda> alterarStatus(
    Session session,
    int id,
    DemandaStatus status, {
    String? motivoCancelamento,
    bool concluirEmCascata = false,
    Transaction? transaction,
  }) async {
    if (transaction == null) {
      return session.db.transaction(
        (tx) => alterarStatus(
          session,
          id,
          status,
          motivoCancelamento: motivoCancelamento,
          concluirEmCascata: concluirEmCascata,
          transaction: tx,
        ),
      );
    }

    final raiz = await Demanda.db.findById(
      session,
      id,
      transaction: transaction,
      lockMode: LockMode.forUpdate,
    );
    if (raiz == null) {
      throw TransicaoStatusException(
        codigo: TransicaoStatusErroCodigo.demandaNaoEncontrada,
        mensagem: 'Demanda não encontrada.',
      );
    }

    final descendentes = _terminal(status)
        ? await _carregarDescendentes(session, raiz, transaction)
        : const <Demanda>[];
    final ativos = descendentes.where((demanda) => !_terminal(demanda.status));
    final motivo = status == DemandaStatus.cancelada
        ? _validarMotivo(raiz, motivoCancelamento, ativos.isNotEmpty)
        : null;
    if (status == DemandaStatus.concluida &&
        !concluirEmCascata &&
        ativos.isNotEmpty) {
      throw TransicaoStatusException(
        codigo: TransicaoStatusErroCodigo.descendentesAtivos,
        mensagem:
            'A demanda possui descendentes ativos. '
            'É necessário concluir em cascata.',
        podeConcluirEmCascata: true,
      );
    }

    final agora = DateTime.now().toUtc();
    if (status == DemandaStatus.cancelada ||
        (status == DemandaStatus.concluida && concluirEmCascata)) {
      // A busca é por nível; inverter processa descendentes antes dos pais.
      // Terminais são preservados, mas seus descendentes ativos são visitados.
      for (final descendente in ativos.toList().reversed) {
        await _persistirTransicao(
          session,
          descendente,
          status,
          motivo,
          agora,
          transaction,
        );
      }
    }
    return _persistirTransicao(
      session,
      raiz,
      status,
      motivo,
      agora,
      transaction,
    );
  }

  Future<Demanda> concluirEmCascata(Session session, int id) => alterarStatus(
    session,
    id,
    DemandaStatus.concluida,
    concluirEmCascata: true,
  );

  Future<Demanda> cancelarEmCascata(
    Session session,
    int id,
    String motivo,
  ) => alterarStatus(
    session,
    id,
    DemandaStatus.cancelada,
    motivoCancelamento: motivo,
  );

  bool _terminal(DemandaStatus status) =>
      status == DemandaStatus.concluida || status == DemandaStatus.cancelada;

  String? _validarMotivo(
    Demanda atual,
    String? informado,
    bool cancelaDescendentes,
  ) {
    // Editar outros campos de uma demanda já cancelada preserva seu motivo.
    // Uma nova transição para Cancelada sempre exige um motivo explícito.
    final motivo =
        (informado ??
                (atual.status == DemandaStatus.cancelada
                    ? atual.motivoCancelamento
                    : null))
            ?.trim();
    if (motivo == null || motivo.isEmpty) {
      // Sem uma nova transição, metadados de cancelamentos legados podem
      // ser editados sem inventar um motivo que não existia.
      if (informado == null &&
          atual.status == DemandaStatus.cancelada &&
          !cancelaDescendentes) {
        return atual.motivoCancelamento;
      }
      throw TransicaoStatusException(
        codigo: TransicaoStatusErroCodigo.motivoCancelamentoObrigatorio,
        mensagem: 'Informe o motivo do cancelamento.',
      );
    }
    return motivo;
  }

  Future<List<Demanda>> _carregarDescendentes(
    Session session,
    Demanda raiz,
    Transaction transaction,
  ) async {
    final descendentes = <Demanda>[];
    final visitados = <int>{raiz.id!};
    var pais = <int>{raiz.id!};
    while (pais.isNotEmpty) {
      final filhas = await Demanda.db.find(
        session,
        where: (t) => t.demandaPaiId.inSet(pais),
        orderBy: (t) => t.id,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      pais = {};
      for (final filha in filhas) {
        if (!visitados.add(filha.id!)) continue;
        descendentes.add(filha);
        pais.add(filha.id!);
      }
    }
    // Cada pai é bloqueado antes de buscar seus filhos. A criação existente
    // usa FOR KEY SHARE no pai, evitando novas filhas durante esta operação.
    return descendentes;
  }

  Future<Demanda> _persistirTransicao(
    Session session,
    Demanda atual,
    DemandaStatus status,
    String? motivo,
    DateTime agora,
    Transaction transaction,
  ) async {
    return (await Demanda.db.updateById(
      session,
      atual.id!,
      columnValues: (t) => [
        t.status(status),
        if (status == DemandaStatus.cancelada) t.motivoCancelamento(motivo),
        t.concluidoEm(
          status == DemandaStatus.concluida ? atual.concluidoEm ?? agora : null,
        ),
        t.atualizadoEm(agora),
      ],
      transaction: transaction,
    ))!;
  }
}
