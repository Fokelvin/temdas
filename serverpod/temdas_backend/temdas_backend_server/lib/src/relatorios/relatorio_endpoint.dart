import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

class RelatorioEndpoint extends Endpoint {
  Future<RelatorioDemandasResponse> gerarRelatorioDemandas(
    Session session,
    RelatorioDemandaRequest request,
  ) async {
    _validarPeriodo(request.inicioEm, request.fimExclusivo);

    final demandas = await Demanda.db.find(session);
    final registros = await RegistroTempo.db.find(
      session,
      where: (t) =>
          (t.inicioEm >= request.inicioEm) &
          (t.inicioEm < request.fimExclusivo),
      orderBy: (t) => t.inicioEm,
    );

    final demandasPorId = <int, Demanda>{
      for (final demanda in demandas)
        if (demanda.id != null) demanda.id!: demanda,
    };
    final registrosPorDemanda = <int, int>{};
    for (final registro in registros) {
      registrosPorDemanda.update(
        registro.demandaId,
        (total) => total + registro.duracaoMinutos,
        ifAbsent: () => registro.duracaoMinutos,
      );
    }

    final selecionadas = demandas.where((demanda) {
      final temTempo = registrosPorDemanda.containsKey(demanda.id);
      final correspondeStatus =
          request.status == null || demanda.status == request.status;
      final correspondePrioridade =
          request.prioridade == null ||
          demanda.prioridade == request.prioridade;
      return temTempo && correspondeStatus && correspondePrioridade;
    }).toList();
    final selecionadasPorId = <int, Demanda>{
      for (final demanda in selecionadas)
        if (demanda.id != null) demanda.id!: demanda,
    };

    final idsIncluidos = <int>{...selecionadasPorId.keys};
    final idsContexto = <int>{};
    for (final demanda in selecionadas) {
      var atual = demanda;
      final caminho = <int>{};
      while (true) {
        final paiId = atual.demandaPaiId;
        if (paiId == null) break;
        if (!caminho.add(paiId)) break;
        idsIncluidos.add(paiId);
        if (!selecionadasPorId.containsKey(paiId)) idsContexto.add(paiId);
        final pai = demandasPorId[paiId];
        if (pai == null) break;
        atual = pai;
      }
    }

    final porPai = <int?, List<Demanda>>{};
    for (final demanda in demandas) {
      if (demanda.id == null || !idsIncluidos.contains(demanda.id)) continue;
      porPai.putIfAbsent(demanda.demandaPaiId, () => []).add(demanda);
    }
    for (final filhos in porPai.values) {
      filhos.sort(_compararDemandas);
    }

    final itens = <RelatorioDemandaItem>[];
    final idsVisitados = <int>{};
    void visitar(Demanda demanda, int nivel) {
      final id = demanda.id;
      if (id == null || !idsVisitados.add(id)) return;
      final proprio = idsContexto.contains(id)
          ? 0
          : registrosPorDemanda[id] ?? 0;
      itens.add(
        RelatorioDemandaItem(
          demandaId: id,
          titulo: demanda.titulo,
          demandaMaeId: demanda.demandaPaiId,
          nivelHierarquico: nivel,
          status: demanda.status,
          prioridade: demanda.prioridade,
          tempoEstimadoMinutos: demanda.tempoEstimadoMinutos,
          tempoRealizadoProprioMinutos: proprio,
          tempoRealizadoTotalArvoreMinutos: 0,
          apenasContexto: idsContexto.contains(id),
        ),
      );
      for (final filha in porPai[id] ?? const <Demanda>[]) {
        visitar(filha, nivel + 1);
      }
    }

    for (final raiz in porPai[null] ?? const <Demanda>[]) {
      visitar(raiz, 0);
    }
    final demandasOrdenadas = demandas.toList()..sort(_compararDemandas);
    for (final demanda in demandasOrdenadas) {
      if (demanda.id != null && idsIncluidos.contains(demanda.id)) {
        visitar(demanda, _nivelDaDemanda(demanda, demandasPorId));
      }
    }

    final proprioPorId = <int, int>{
      for (final item in itens)
        item.demandaId: item.tempoRealizadoProprioMinutos,
    };
    final filhosPorId = <int, List<int>>{};
    for (final item in itens) {
      final paiId = item.demandaMaeId;
      if (paiId != null) {
        filhosPorId.putIfAbsent(paiId, () => []).add(item.demandaId);
      }
    }
    final totalArvorePorId = <int, int>{};
    int totalDaArvore(int id) => totalArvorePorId.putIfAbsent(
      id,
      () =>
          (proprioPorId[id] ?? 0) +
          (filhosPorId[id] ?? const <int>[]).fold<int>(
            0,
            (total, filhaId) => total + totalDaArvore(filhaId),
          ),
    );

    final itensComTotais = itens
        .map(
          (item) => item.copyWith(
            tempoRealizadoTotalArvoreMinutos: totalDaArvore(item.demandaId),
          ),
        )
        .toList(growable: false);
    final total = selecionadas.fold<int>(
      0,
      (soma, demanda) => soma + (registrosPorDemanda[demanda.id] ?? 0),
    );

    return RelatorioDemandasResponse(
      inicioEm: request.inicioEm,
      fimExclusivo: request.fimExclusivo,
      tempoRealizadoTotalMinutos: total,
      quantidadeDemandasComTempo: selecionadas.length,
      itens: itensComTotais,
    );
  }

  int _compararDemandas(Demanda a, Demanda b) {
    final ordem = (a.ordem ?? 1 << 30).compareTo(b.ordem ?? 1 << 30);
    if (ordem != 0) return ordem;
    final criado = b.criadoEm.compareTo(a.criadoEm);
    if (criado != 0) return criado;
    return (a.id ?? 1 << 30).compareTo(b.id ?? 1 << 30);
  }

  int _nivelDaDemanda(Demanda demanda, Map<int, Demanda> porId) {
    var nivel = 0;
    var atual = demanda;
    final visitados = <int>{};
    while (true) {
      final paiId = atual.demandaPaiId;
      if (paiId == null) break;
      if (!visitados.add(paiId)) break;
      nivel++;
      final pai = porId[paiId];
      if (pai == null) break;
      atual = pai;
    }
    return nivel;
  }

  void _validarPeriodo(DateTime inicio, DateTime fim) {
    if (!inicio.isUtc) {
      throw Exception('O início do período deve estar em UTC.');
    }
    if (!fim.isUtc) {
      throw Exception('O fim exclusivo do período deve estar em UTC.');
    }
    if (!inicio.isBefore(fim)) {
      throw Exception(
        'O início do período deve ser anterior ao fim exclusivo.',
      );
    }
  }
}
