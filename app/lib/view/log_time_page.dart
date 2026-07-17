import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../model/demanda.dart';
import '../view_model/workspace_view_model.dart';
import 'widgets/app_drawer.dart';
import 'widgets/resumo_card.dart';

class LogTimePage extends StatelessWidget {
  const LogTimePage({super.key, required this.viewModel});
  final WorkspaceViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) => PageScaffold(
      title: 'Log time',
      route: AppRoutes.logTime,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(viewModel: viewModel),
                const SizedBox(height: 16),
                _Summary(viewModel: viewModel),
                const SizedBox(height: 20),
                Expanded(
                  child: viewModel.mode == AgendaMode.dia
                      ? _DayAgenda(viewModel: viewModel)
                      : _WeekAgenda(viewModel: viewModel),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel});
  final WorkspaceViewModel viewModel;
  @override
  Widget build(BuildContext context) {
    final label = viewModel.mode == AgendaMode.dia
        ? _longDate(viewModel.dataSelecionada)
        : '${_shortDate(viewModel.diasDaSemana.first)} – ${_shortDate(viewModel.diasDaSemana.last)}';
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Text('Agenda dos tempos lançados nas demandas'),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: viewModel.periodoAnterior,
              icon: const Icon(Icons.chevron_left),
            ),
            OutlinedButton(
              onPressed: viewModel.irParaHoje,
              child: const Text('Hoje'),
            ),
            IconButton(
              onPressed: viewModel.proximoPeriodo,
              icon: const Icon(Icons.chevron_right),
            ),
            const SizedBox(width: 8),
            SegmentedButton<AgendaMode>(
              segments: const [
                ButtonSegment(
                  value: AgendaMode.dia,
                  label: Text('Dia'),
                  icon: Icon(Icons.view_day_outlined),
                ),
                ButtonSegment(
                  value: AgendaMode.semana,
                  label: Text('Semana'),
                  icon: Icon(Icons.calendar_view_week_outlined),
                ),
              ],
              selected: {viewModel.mode},
              onSelectionChanged: (value) => viewModel.setMode(value.first),
            ),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.viewModel});
  final WorkspaceViewModel viewModel;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth < 700
          ? constraints.maxWidth
          : (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: ResumoCard(
              titulo: 'Lançamentos no período',
              valor: '${viewModel.lancamentosDoPeriodo}',
              icone: Icons.event_note,
            ),
          ),
          SizedBox(
            width: width,
            child: ResumoCard(
              titulo: 'Tempo executado',
              valor: formatDuration(viewModel.executadoDoPeriodo),
              icone: Icons.timer_outlined,
            ),
          ),
        ],
      );
    },
  );
}

class _DayAgenda extends StatelessWidget {
  const _DayAgenda({required this.viewModel});
  final WorkspaceViewModel viewModel;
  @override
  Widget build(BuildContext context) {
    final logs = viewModel.logsDoDia(viewModel.dataSelecionada);
    if (logs.isEmpty) return const _EmptyAgenda();
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: logs.length,
        separatorBuilder: (_, _) => const Divider(height: 24),
        itemBuilder: (context, index) => _LogTile(
          log: logs[index],
          demanda: viewModel.demandaPorId(logs[index].demandaId),
        ),
      ),
    );
  }
}

class _WeekAgenda extends StatelessWidget {
  const _WeekAgenda({required this.viewModel});
  final WorkspaceViewModel viewModel;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth < 980 ? 980 : constraints.maxWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: viewModel.diasDaSemana.map((day) {
            final logs = viewModel.logsDoDia(day);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      viewModel.selecionarData(day);
                      viewModel.setMode(AgendaMode.dia);
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _weekday(day.weekday),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${day.day}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Divider(),
                          if (logs.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text(
                                'Sem logs',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ...logs.map(
                            (log) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: .35),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${twoDigits(log.hora.hour)}:${twoDigits(log.hora.minute)} · ${formatDuration(log.duracao)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    viewModel
                                        .demandaPorId(log.demandaId)
                                        .titulo,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ),
  );
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log, required this.demanda});
  final LogTime log;
  final Demanda demanda;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 70,
        child: Text(
          '${twoDigits(log.hora.hour)}:${twoDigits(log.hora.minute)}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      Container(
        width: 4,
        height: 46,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              demanda.titulo,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('Tempo lançado: ${formatDuration(log.duracao)}'),
          ],
        ),
      ),
    ],
  );
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda();
  @override
  Widget build(BuildContext context) => Card(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_available,
            size: 52,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          const Text('Nenhum log time neste dia.'),
        ],
      ),
    ),
  );
}

String _weekday(int day) =>
    const ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'][day - 1];
String _shortDate(DateTime value) =>
    '${twoDigits(value.day)}/${twoDigits(value.month)}';
String _longDate(DateTime value) {
  const months = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  return '${value.day} de ${months[value.month - 1]} de ${value.year}';
}
