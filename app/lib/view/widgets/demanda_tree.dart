import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'demanda_card.dart';

class DemandaTree extends StatelessWidget {
  const DemandaTree({
    super.key,
    required this.demandas,
    required this.acoesHabilitadas,
    required this.onEditar,
    required this.onExcluir,
    required this.onCriarFilha,
    required this.onLancarTempo,
    required this.onMostrarTudo,
  });

  final List<backend.Demanda> demandas;
  final bool acoesHabilitadas;
  final ValueChanged<backend.Demanda> onEditar;
  final ValueChanged<backend.Demanda> onExcluir;
  final ValueChanged<backend.Demanda> onCriarFilha;
  final ValueChanged<backend.Demanda> onLancarTempo;
  final ValueChanged<backend.Demanda> onMostrarTudo;

  @override
  Widget build(BuildContext context) {
    final ids = demandas.map((demanda) => demanda.id).whereType<int>().toSet();
    final porPai = <int, List<backend.Demanda>>{};
    for (final demanda in demandas) {
      final paiId = demanda.demandaPaiId;
      if (paiId != null) {
        porPai.putIfAbsent(paiId, () => []).add(demanda);
      }
    }

    final raizes = demandas
        .where(
          (demanda) =>
              demanda.demandaPaiId == null ||
              !ids.contains(demanda.demandaPaiId),
        )
        .toList();
    final idsRenderizados = <int>{};
    final nos = <_DemandaNivel>[];

    for (final raiz in raizes) {
      _visitar(
        raiz,
        nivel: 0,
        porPai: porPai,
        caminho: const {},
        idsRenderizados: idsRenderizados,
        nos: nos,
      );
    }

    // Relações inválidas ou cíclicas não devem fazer uma demanda desaparecer.
    for (final demanda in demandas) {
      final id = demanda.id;
      if (id != null && idsRenderizados.contains(id)) continue;
      _visitar(
        demanda,
        nivel: 0,
        porPai: porPai,
        caminho: const {},
        idsRenderizados: idsRenderizados,
        nos: nos,
      );
    }

    return Column(children: [for (final no in nos) _construirNo(no)]);
  }

  void _visitar(
    backend.Demanda demanda, {
    required int nivel,
    required Map<int, List<backend.Demanda>> porPai,
    required Set<int> caminho,
    required Set<int> idsRenderizados,
    required List<_DemandaNivel> nos,
  }) {
    final id = demanda.id;
    final proximoCaminho = {...caminho};
    if (id != null) {
      if (!proximoCaminho.add(id)) return;
      idsRenderizados.add(id);
    }

    nos.add(_DemandaNivel(demanda: demanda, nivel: nivel));
    final filhas = id == null
        ? const <backend.Demanda>[]
        : porPai[id] ?? const [];
    for (final filha in filhas) {
      if (filha.id != null && proximoCaminho.contains(filha.id)) continue;
      _visitar(
        filha,
        nivel: nivel + 1,
        porPai: porPai,
        caminho: proximoCaminho,
        idsRenderizados: idsRenderizados,
        nos: nos,
      );
    }
  }

  Widget _construirNo(_DemandaNivel no) {
    final demanda = no.demanda;
    final nivel = no.nivel;
    final recuo = math.min(nivel * 20.0, 100.0);

    return Padding(
      key: ValueKey('demanda-tree-node-${demanda.id ?? demanda.titulo}-$nivel'),
      padding: EdgeInsets.only(left: recuo, bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: nivel == 0
              ? null
              : const Border(left: BorderSide(color: Color(0xFFD6DCE5))),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: nivel == 0 ? 0 : 10),
          child: DemandaCard(
            demanda: demanda,
            acoesHabilitadas: acoesHabilitadas,
            onEditar: () => onEditar(demanda),
            onExcluir: () => onExcluir(demanda),
            onCriarFilha: () => onCriarFilha(demanda),
            onLancarTempo: () => onLancarTempo(demanda),
            onMostrarTudo: () => onMostrarTudo(demanda),
          ),
        ),
      ),
    );
  }
}

class _DemandaNivel {
  const _DemandaNivel({required this.demanda, required this.nivel});

  final backend.Demanda demanda;
  final int nivel;
}
