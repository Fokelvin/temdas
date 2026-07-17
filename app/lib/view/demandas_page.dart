import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../model/demanda.dart';
import '../view_model/workspace_view_model.dart';
import 'widgets/app_drawer.dart';
import 'widgets/demanda_dialog.dart';
import 'widgets/log_time_dialog.dart';
import 'widgets/resumo_card.dart';

class DemandasPage extends StatelessWidget {
  const DemandasPage({super.key, required this.viewModel});
  final WorkspaceViewModel viewModel;

  Future<void> _novaDemanda(BuildContext context, {String? parentId}) async {
    final value = await showDialog<DemandaFormData>(
      context: context,
      builder: (_) => DemandaDialog(isFilha: parentId != null),
    );
    if (value != null) {
      viewModel.adicionarDemanda(
        titulo: value.titulo,
        estimado: value.estimado,
        status: value.status,
        parentId: parentId,
      );
    }
  }

  Future<void> _adicionarLog(BuildContext context, Demanda demanda) async {
    final value = await showDialog<LogTimeFormData>(
      context: context,
      builder: (_) => LogTimeDialog(
        demandaTitulo: demanda.titulo,
        dataInicial: DateTime.now(),
      ),
    );
    if (value != null) {
      viewModel.adicionarLog(
        demandaId: demanda.id,
        data: value.data,
        hora: TimeOfDayValue(value.hora.hour, value.hora.minute),
        duracao: value.duracao,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Log time adicionado.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) => PageScaffold(
      title: 'Demandas',
      route: AppRoutes.demandas,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: () => _novaDemanda(context),
            icon: const Icon(Icons.add),
            label: const Text('Nova demanda'),
          ),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Todas as demandas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Demandas existem independentemente de uma data ou sprint.',
              ),
              const SizedBox(height: 20),
              ...viewModel.demandasRaiz.map(
                (demanda) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DemandaCard(
                    demanda: demanda,
                    filhas: viewModel.filhasDe(demanda.id),
                    executado: viewModel.executadoDaDemanda(demanda.id),
                    onStatus: (value) =>
                        viewModel.alterarStatus(demanda, value),
                    onAddLog: () => _adicionarLog(context, demanda),
                    onAddChild: () =>
                        _novaDemanda(context, parentId: demanda.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _DemandaCard extends StatelessWidget {
  const _DemandaCard({
    required this.demanda,
    required this.filhas,
    required this.executado,
    required this.onStatus,
    required this.onAddLog,
    required this.onAddChild,
  });
  final Demanda demanda;
  final List<Demanda> filhas;
  final Duration executado;
  final ValueChanged<DemandaStatus> onStatus;
  final VoidCallback onAddLog;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 360,
                child: Text(
                  demanda.titulo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Chip(
                label: Text(
                  '${formatDuration(executado)} / ${formatDuration(demanda.tempoEstimado)}',
                ),
              ),
              DropdownButton<DemandaStatus>(
                value: demanda.status,
                items: DemandaStatus.values
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onStatus(value);
                },
              ),
              FilledButton.tonalIcon(
                onPressed: onAddLog,
                icon: const Icon(Icons.more_time),
                label: const Text('Adicionar log time'),
              ),
            ],
          ),
          if (filhas.isNotEmpty) ...[
            const Divider(height: 28),
            ...filhas.map(
              (item) => Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.titulo)),
                    Chip(
                      label: Text(item.status.label),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddChild,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar demanda filha'),
            ),
          ),
        ],
      ),
    ),
  );
}
