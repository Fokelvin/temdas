import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../theme/tokens.dart';
import 'demand_components.dart';

/// Illustrative, local data. Public previews never load private repositories.
class HomePreview extends StatelessWidget {
  const HomePreview({super.key, required this.section});

  final int section;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final title = switch (section) {
      2 => 'Sprints',
      3 => 'Log Time',
      4 => 'Relatórios',
      _ => 'Demandas',
    };
    return Container(
      key: ValueKey('home-preview-$section'),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.borderStrong),
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(
                  'Dados de exemplo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: IgnorePointer(
              child: switch (section) {
                1 => const _DemandList(),
                2 => const _SprintPreview(),
                3 => const _TimePreview(),
                4 => const _ReportPreview(),
                _ => const _BoardPreview(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

backend.Demanda _example(backend.DemandaStatus status, int id) =>
    backend.Demanda(
      id: id,
      usuarioId: 0,
      titulo: 'Demanda de exemplo',
      status: status,
      prioridade: backend.Prioridade.media,
      tempoEstimadoMinutos: 240,
      tempoExecutadoMinutos: status == backend.DemandaStatus.concluida
          ? 240
          : 90,
      criadoEm: DateTime.utc(2026, 10, 12),
      atualizadoEm: DateTime.utc(2026, 10, 12),
    );

class _BoardPreview extends StatelessWidget {
  const _BoardPreview();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide =
          box.maxWidth >= 520 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.2;
      final statuses = wide
          ? [
              backend.DemandaStatus.aberta,
              backend.DemandaStatus.emAndamento,
              backend.DemandaStatus.concluida,
            ]
          : [backend.DemandaStatus.emAndamento];
      Widget column(backend.DemandaStatus status) => Container(
        padding: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTokens.of(context).bg,
          border: Border.all(color: AppTokens.of(context).border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GroupHeader(status: status, count: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DemandCard(
                demand: _example(status, status.index + 1),
                real: status == backend.DemandaStatus.concluida ? 240 : 90,
                actions: const SizedBox.shrink(),
                chevron: const Icon(Symbols.chevron_right_rounded, size: 16),
              ),
            ),
            if (wide) const SizedBox(height: 56),
          ],
        ),
      );
      if (!wide) return column(statuses.single);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < statuses.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: column(statuses[i])),
          ],
        ],
      );
    },
  );
}

class _DemandList extends StatelessWidget {
  const _DemandList();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final status in [
        backend.DemandaStatus.aberta,
        backend.DemandaStatus.emAndamento,
      ]) ...[
        GroupHeader(status: status, count: 1),
        DemandRow(
          id: status.index + 1,
          title: 'Demanda de exemplo',
          priority: backend.Prioridade.media,
          hours: 90,
          estimate: 240,
          status: status,
          actions: const SizedBox.shrink(),
          chevron: const Icon(Symbols.chevron_right_rounded, size: 16),
          onTap: null,
        ),
      ],
    ],
  );
}

class _SprintPreview extends StatelessWidget {
  const _SprintPreview();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Symbols.sprint_rounded, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text('Sprint de exemplo', style: text.titleMedium)),
          ],
        ),
        const SizedBox(height: 16),
        Text('12/10 — 16/10', style: text.bodySmall),
        const SizedBox(height: 24),
        const HoursLabel(minutes: 360, estimate: 960),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) =>
              HoursMeter(real: 360, estimate: 960, width: box.maxWidth),
        ),
        const SizedBox(height: 24),
        for (final status in [
          backend.DemandaStatus.emAndamento,
          backend.DemandaStatus.aberta,
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                StatusDot(color: statusColor(status)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Demanda de exemplo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const HoursLabel(minutes: 90),
              ],
            ),
          ),
      ],
    );
  }
}

class _TimePreview extends StatelessWidget {
  const _TimePreview();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final wide =
          box.maxWidth >= 440 &&
          MediaQuery.textScalerOf(context).scale(1) <= 1.2;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 44, right: 12),
            child: Column(
              children: [
                for (final hour in ['09:00', '10:00', '11:00', '12:00'])
                  SizedBox(
                    height: 60,
                    child: Text(
                      hour,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFeatures: AppTokens.numbers,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          for (final day in wide ? ['12/10', '13/10', '14/10'] : ['12/10'])
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: Text(
                      day,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  Container(
                    height: 240,
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppTokens.of(context).border),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTokens.of(context).surface2,
                            border: const Border(
                              left: BorderSide(
                                color: AppTokens.accent,
                                width: 3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Demanda de exemplo',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8),
                              HoursLabel(minutes: 90),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    },
  );
}

class _ReportPreview extends StatelessWidget {
  const _ReportPreview();

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tempo realizado total',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        const HoursLabel(minutes: 360),
        const SizedBox(height: 24),
        for (var i = 0; i < 3; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Demanda de exemplo',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                HoursLabel(minutes: (i + 1) * 60),
              ],
            ),
          ),
      ],
    );
  }
}
