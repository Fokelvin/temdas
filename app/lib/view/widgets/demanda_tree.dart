import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../view_model/tempo_executado_total.dart';
import 'demanda_card.dart';

class DemandaTree extends StatelessWidget {
  const DemandaTree({
    super.key,
    required this.horizontalController,
    required this.demandas,
    required this.acoesHabilitadas,
    required this.onEditar,
    required this.onExcluir,
    required this.onCriarFilha,
    required this.onLancarTempo,
    required this.onMostrarTudo,
    required this.onAlterarStatus,
    required this.onConcluir,
    this.demandasEmProcessamento = const {},
  });

  final List<backend.Demanda> demandas;
  final ScrollController horizontalController;
  final bool acoesHabilitadas;
  final ValueChanged<backend.Demanda> onEditar;
  final ValueChanged<backend.Demanda> onExcluir;
  final ValueChanged<backend.Demanda> onCriarFilha;
  final ValueChanged<backend.Demanda> onLancarTempo;
  final ValueChanged<backend.Demanda> onMostrarTudo;
  final void Function(backend.Demanda, backend.DemandaStatus) onAlterarStatus;
  final ValueChanged<backend.Demanda> onConcluir;
  final Set<int> demandasEmProcessamento;

  @override
  Widget build(BuildContext context) {
    final temposTotais = calcularTemposExecutadosTotais(demandas);
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
    final porStatus = {
      for (final status in backend.DemandaStatus.values)
        status: <_DemandaNivel>[],
    };

    // A raiz define a coluna de toda a árvore; a visita mantém a ordem,
    // os níveis e o status próprio de cada descendente.
    for (final raiz in raizes) {
      _visitar(
        raiz,
        nivel: 0,
        porPai: porPai,
        caminho: const {},
        idsRenderizados: idsRenderizados,
        nos: porStatus[raiz.status]!,
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
        nos: porStatus[demanda.status]!,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const espacamento = 16.0;
        final larguraColuna = math.max(
          360.0,
          (constraints.maxWidth - espacamento * (porStatus.length - 1)) /
              porStatus.length,
        );

        final possuiOverflow =
            larguraColuna * porStatus.length +
                espacamento * (porStatus.length - 1) >
            constraints.maxWidth;

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thickness: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.hovered) ||
                        states.contains(WidgetState.dragged)
                    ? 9.0
                    : 4.0,
              ),
              thumbColor: WidgetStateProperty.resolveWith((states) {
                final opacity = states.contains(WidgetState.dragged)
                    ? 0.75
                    : states.contains(WidgetState.hovered)
                    ? 0.60
                    : 0.28;
                return Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: opacity);
              }),
              crossAxisMargin: 4,
              radius: const Radius.circular(5),
            ),
            child: Scrollbar(
              key: const ValueKey('demandas-quadro-scrollbar'),
              controller: horizontalController,
              thumbVisibility: possuiOverflow,
              trackVisibility: false,
              interactive: true,
              scrollbarOrientation: ScrollbarOrientation.bottom,
              child: SingleChildScrollView(
                key: const ValueKey('demandas-quadro-status'),
                controller: horizontalController,
                scrollDirection: Axis.horizontal,
                // A Row assume a altura da maior coluna. A faixa inferior reserva
                // espaço para a barra no fim do conteúdo, inclusive durante hover.
                padding: EdgeInsets.only(bottom: possuiOverflow ? 18 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final grupo in porStatus.entries) ...[
                      if (grupo.key != porStatus.keys.first)
                        const SizedBox(width: espacamento),
                      SizedBox(
                        width: larguraColuna,
                        child: Column(
                          key: ValueKey('demanda-coluna-${grupo.key.name}'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              key: ValueKey('demanda-status-${grupo.key.name}'),
                              padding: const EdgeInsets.only(
                                top: 16,
                                bottom: 12,
                              ),
                              child: Semantics(
                                header: true,
                                child: Row(
                                  children: [
                                    Text(
                                      _statusLabel(grupo.key),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '(${grupo.value.where((no) => no.nivel == 0).length})',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(child: Divider()),
                                  ],
                                ),
                              ),
                            ),
                            if (grupo.value.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Text(
                                  'Nenhuma demanda neste status.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              )
                            else
                              for (final no in grupo.value)
                                _construirNo(
                                  no,
                                  temposTotais[no.demanda.id] ??
                                      no.demanda.tempoExecutadoMinutos,
                                ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
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

  Widget _construirNo(_DemandaNivel no, int tempoExecutadoTotalMinutos) {
    final demanda = no.demanda;
    final emProcessamento = demandasEmProcessamento.contains(demanda.id);
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
            // A expansão acompanha a demanda quando ela muda de coluna.
            key: PageStorageKey(
              'demanda-expansao-${demanda.id ?? demanda.titulo}',
            ),
            demanda: demanda,
            tempoExecutadoTotalMinutos: tempoExecutadoTotalMinutos,
            acoesHabilitadas: acoesHabilitadas && !emProcessamento,
            emProcessamento: emProcessamento,
            onAlterarStatus: (status) => onAlterarStatus(demanda, status),
            onConcluir: () => onConcluir(demanda),
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

  String _statusLabel(backend.DemandaStatus status) => switch (status) {
    backend.DemandaStatus.aberta => 'Abertas',
    backend.DemandaStatus.emAndamento => 'Em andamento',
    backend.DemandaStatus.pausada => 'Pausadas',
    backend.DemandaStatus.concluida => 'Concluídas',
    backend.DemandaStatus.cancelada => 'Canceladas',
  };
}

class _DemandaNivel {
  const _DemandaNivel({required this.demanda, required this.nivel});

  final backend.Demanda demanda;
  final int nivel;
}
