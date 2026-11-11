import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../ui/components/demand_components.dart';
import '../../view_model/demandas_agrupamento.dart';
import 'densidade_demanda.dart';
import '../../view_model/demanda_lista_preferencias.dart';

class DemandaLista extends StatelessWidget {
  const DemandaLista({
    super.key,
    required this.densidade,
    required this.agrupamento,
    required this.hierarquia,
    required this.porStatus,
    required this.porPrioridade,
    required this.gruposRecolhidos,
    this.gruposEmBusca = false,
    required this.onAlternarGrupo,
    required this.construirLinha,
  });

  final DensidadeDemanda densidade;
  final AgrupamentoDemandas agrupamento;
  final List<DemandaNivel> hierarquia;
  final Map<backend.DemandaStatus, List<DemandaNivel>> porStatus;
  final Map<backend.Prioridade, List<DemandaNivel>> porPrioridade;
  final Set<Object> gruposRecolhidos;
  final bool gruposEmBusca;
  final ValueChanged<Object> onAlternarGrupo;
  final Widget Function(DemandaNivel) construirLinha;

  @override
  Widget build(BuildContext context) {
    final Map<Object, List<DemandaNivel>> grupos = switch (agrupamento) {
      AgrupamentoDemandas.demanda => const {},
      AgrupamentoDemandas.status => porStatus,
      AgrupamentoDemandas.prioridade => porPrioridade,
    };
    return Column(
      key: ValueKey('demandas-lista-${agrupamento.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...hierarquia.map(construirLinha),
        for (final grupo in grupos.entries.where(
          (g) => g.value.isNotEmpty,
        )) ...[
          GroupHeader(
            densidade: densidade,
            status: grupo.key is backend.DemandaStatus
                ? grupo.key as backend.DemandaStatus
                : null,
            prioridade: grupo.key is backend.Prioridade
                ? grupo.key as backend.Prioridade
                : null,
            count: grupo.value.where((no) => no.nivel == 0).length,
            collapsed: gruposRecolhidos.contains(grupo.key),
            bloqueado: gruposEmBusca,
            onTap: () => onAlternarGrupo(grupo.key),
          ),
          if (!gruposRecolhidos.contains(grupo.key))
            ...grupo.value.map(construirLinha),
        ],
        if (agrupamento == AgrupamentoDemandas.status)
          EmptyStatusesLine(
            statuses: porStatus.entries
                .where((g) => g.value.isEmpty)
                .map((g) => g.key)
                .toList(),
          ),
      ],
    );
  }
}

class DemandaNivel {
  const DemandaNivel({required this.demanda, required this.nivel});

  final backend.Demanda demanda;
  final int nivel;
}

class ComandoExpansaoLista {
  ComandoExpansaoLista(this.expandir);
  final bool expandir;
}

class DemandaListaControles extends StatelessWidget {
  const DemandaListaControles({
    super.key,
    required this.colunas,
    required this.onAlternarColuna,
    this.onExpandir,
    this.expandido = false,
  });

  final Set<ColunaDemanda> colunas;
  final ValueChanged<ColunaDemanda> onAlternarColuna;
  final ValueChanged<bool>? onExpandir;
  final bool expandido;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onExpandir == null
                ? null
                : () => onExpandir!(!expandido),
            icon: Icon(
              expandido
                  ? Symbols.unfold_less_rounded
                  : Symbols.unfold_more_rounded,
              size: 18,
            ),
            label: Text(expandido ? 'Recolher todas' : 'Expandir todas'),
          ),
        ),
      ),
      TextButton.icon(
        icon: const Icon(Symbols.view_column_rounded, size: 18),
        label: const Text('Escolher colunas'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (context) {
            final selecionadas = {...colunas};
            return StatefulBuilder(
              builder: (context, atualizar) => AlertDialog(
                title: const Text('Escolher colunas'),
                content: SizedBox(
                  width: 320,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final coluna in ColunaDemanda.values)
                          CheckboxListTile(
                            title: Text(coluna.rotulo),
                            value: selecionadas.contains(coluna),
                            onChanged: coluna == ColunaDemanda.demanda
                                ? null
                                : (visivel) {
                                    atualizar(() {
                                      if (visivel == true) {
                                        selecionadas.add(coluna);
                                      } else {
                                        selecionadas.remove(coluna);
                                      }
                                    });
                                    onAlternarColuna(coluna);
                                  },
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Concluir'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}
