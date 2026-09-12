import 'dart:async';

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../view_model/agenda_view_model.dart';
import 'widgets/app_drawer.dart';
import 'widgets/log_time_dialog.dart';
import 'widgets/resumo_card.dart';

class LogTimePage extends StatefulWidget {
  const LogTimePage({super.key, this.viewModel});

  final AgendaViewModel? viewModel;

  @override
  State<LogTimePage> createState() => _LogTimePageState();
}

class _LogTimePageState extends State<LogTimePage> {
  late final AgendaViewModel _viewModel;
  late final bool _possuiViewModel;

  @override
  void initState() {
    super.initState();
    _possuiViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? AgendaViewModel();
    unawaited(_viewModel.carregarAgenda());
  }

  @override
  void dispose() {
    if (_possuiViewModel) _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _viewModel,
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
                _Header(
                  viewModel: _viewModel,
                  onLancarTempo: _demandasSelecionaveis.isEmpty
                      ? null
                      : _abrirLancamento,
                ),
                const SizedBox(height: 16),
                _Summary(viewModel: _viewModel),
                const SizedBox(height: 20),
                Expanded(child: _conteudo()),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  List<backend.Demanda> get _demandasSelecionaveis {
    final demandas = _viewModel.demandas
        .where((demanda) => demanda.id != null)
        .toList();
    demandas.sort(
      (a, b) => a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()),
    );
    return demandas;
  }

  Widget _conteudo() {
    if (_viewModel.carregando) {
      return const Center(
        child: CircularProgressIndicator(key: ValueKey('agenda-carregando')),
      );
    }
    if (_viewModel.erro case final erro?) {
      return _ErrorAgenda(
        mensagem: erro,
        onTentarNovamente: _viewModel.carregarAgenda,
      );
    }
    if (_viewModel.registros.isEmpty) {
      return _EmptyAgenda(
        periodo: _viewModel.mode == AgendaMode.dia
            ? 'neste dia'
            : 'nesta semana',
        possuiDemandas: _demandasSelecionaveis.isNotEmpty,
        onLancarTempo: _demandasSelecionaveis.isEmpty ? null : _abrirLancamento,
      );
    }
    return _viewModel.mode == AgendaMode.dia
        ? _DayAgenda(viewModel: _viewModel, onExcluir: _confirmarExclusao)
        : _WeekAgenda(viewModel: _viewModel, onExcluir: _confirmarExclusao);
  }

  Future<void> _abrirLancamento() async {
    final demandas = _demandasSelecionaveis;
    if (demandas.isEmpty || _viewModel.enviando) return;

    final demandaId = await showDialog<int>(
      context: context,
      builder: (_) => _SelecionarDemandaDialog(demandas: demandas),
    );
    if (demandaId == null || !mounted) return;

    final demanda = _viewModel.demandaPorId(demandaId);
    if (demanda == null) {
      _mostrarFeedback(
        'A demanda selecionada não está mais disponível.',
        erro: true,
      );
      return;
    }

    final dados = await showDialog<LogTimeFormData>(
      context: context,
      builder: (_) => LogTimeDialog(
        demandaTitulo: demanda.titulo,
        dataInicial: _viewModel.dataSelecionada,
      ),
    );
    if (dados == null || !mounted) return;

    final salvo = await _viewModel.registrarTempo(
      demandaId: demandaId,
      data: dados.data,
      hora: dados.hora,
      duracaoHoras: dados.duracaoHoras,
    );
    if (!mounted) return;
    _mostrarFeedback(
      salvo
          ? 'Tempo lançado com sucesso.'
          : _viewModel.erro ?? 'Não foi possível lançar o tempo.',
      erro: !salvo,
    );
  }

  Future<void> _confirmarExclusao(backend.RegistroTempo registro) async {
    final id = registro.id;
    if (id == null || _viewModel.enviando) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir lançamento?'),
        content: const Text(
          'O tempo executado da demanda será recalculado. '
          'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: ValueKey('confirmar-exclusao-registro-$id'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    final excluido = await _viewModel.excluirRegistroTempo(id);
    if (!mounted) return;
    _mostrarFeedback(
      excluido
          ? 'Lançamento excluído com sucesso.'
          : _viewModel.erro ?? 'Não foi possível excluir o lançamento.',
      erro: !excluido,
    );
  }

  void _mostrarFeedback(String mensagem, {required bool erro}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.viewModel, required this.onLancarTempo});

  final AgendaViewModel viewModel;
  final VoidCallback? onLancarTempo;

  @override
  Widget build(BuildContext context) {
    final label = viewModel.mode == AgendaMode.dia
        ? _longDate(viewModel.dataSelecionada)
        : '${_shortDate(viewModel.diasDaSemana.first)} – '
              '${_shortDate(viewModel.diasDaSemana.last)}';
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              key: const ValueKey('periodo-anterior'),
              tooltip: 'Período anterior',
              onPressed: viewModel.enviando ? null : viewModel.periodoAnterior,
              icon: const Icon(Icons.chevron_left),
            ),
            OutlinedButton(
              onPressed: viewModel.enviando ? null : viewModel.irParaHoje,
              child: const Text('Hoje'),
            ),
            IconButton(
              key: const ValueKey('proximo-periodo'),
              tooltip: 'Próximo período',
              onPressed: viewModel.enviando ? null : viewModel.proximoPeriodo,
              icon: const Icon(Icons.chevron_right),
            ),
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
              onSelectionChanged: viewModel.enviando
                  ? null
                  : (value) => unawaited(viewModel.setMode(value.first)),
            ),
            FilledButton.icon(
              key: const ValueKey('abrir-lancamento-global'),
              onPressed: viewModel.enviando ? null : onLancarTempo,
              icon: viewModel.enviando
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(viewModel.enviando ? 'Salvando...' : 'Lançar tempo'),
            ),
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.viewModel});

  final AgendaViewModel viewModel;

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

typedef _ExcluirRegistro =
    Future<void> Function(backend.RegistroTempo registro);

class _DayAgenda extends StatelessWidget {
  const _DayAgenda({required this.viewModel, required this.onExcluir});

  final AgendaViewModel viewModel;
  final _ExcluirRegistro onExcluir;

  @override
  Widget build(BuildContext context) {
    final registros = viewModel.registrosDoDia(viewModel.dataSelecionada);
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: registros.length,
        separatorBuilder: (_, _) => const Divider(height: 24),
        itemBuilder: (context, index) => _RegistroTile(
          registro: registros[index],
          demanda: viewModel.demandaPorId(registros[index].demandaId),
          onExcluir: onExcluir,
        ),
      ),
    );
  }
}

class _WeekAgenda extends StatelessWidget {
  const _WeekAgenda({required this.viewModel, required this.onExcluir});

  final AgendaViewModel viewModel;
  final _ExcluirRegistro onExcluir;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth < 980 ? 980 : constraints.maxWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: viewModel.diasDaSemana.map((dia) {
            final registros = viewModel.registrosDoDia(dia);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => unawaited(viewModel.mostrarDia(dia)),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _weekday(dia.weekday),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${dia.day}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const Divider(),
                          if (registros.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text(
                                'Sem lançamentos',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ...registros.map(
                            (registro) => _WeekRegistroCard(
                              registro: registro,
                              demanda: viewModel.demandaPorId(
                                registro.demandaId,
                              ),
                              onExcluir: onExcluir,
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

class _WeekRegistroCard extends StatelessWidget {
  const _WeekRegistroCard({
    required this.registro,
    required this.demanda,
    required this.onExcluir,
  });

  final backend.RegistroTempo registro;
  final backend.Demanda? demanda;
  final _ExcluirRegistro onExcluir;

  @override
  Widget build(BuildContext context) {
    final inicio = registro.inicioEm.toLocal();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${twoDigits(inicio.hour)}:${twoDigits(inicio.minute)} · '
                  '${formatDuration(Duration(minutes: registro.duracaoMinutos))}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  demanda?.titulo ?? 'Demanda #${registro.demandaId}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (registro.id != null)
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              tooltip: 'Excluir lançamento',
              onPressed: () => unawaited(onExcluir(registro)),
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
        ],
      ),
    );
  }
}

class _RegistroTile extends StatelessWidget {
  const _RegistroTile({
    required this.registro,
    required this.demanda,
    required this.onExcluir,
  });

  final backend.RegistroTempo registro;
  final backend.Demanda? demanda;
  final _ExcluirRegistro onExcluir;

  @override
  Widget build(BuildContext context) {
    final inicio = registro.inicioEm.toLocal();
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '${twoDigits(inicio.hour)}:${twoDigits(inicio.minute)}',
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
                demanda?.titulo ?? 'Demanda #${registro.demandaId}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Tempo lançado: '
                '${formatDuration(Duration(minutes: registro.duracaoMinutos))}',
              ),
            ],
          ),
        ),
        if (registro.id != null)
          IconButton(
            key: ValueKey('excluir-registro-${registro.id}'),
            tooltip: 'Excluir lançamento',
            onPressed: () => unawaited(onExcluir(registro)),
            icon: const Icon(Icons.delete_outline),
          ),
      ],
    );
  }
}

class _EmptyAgenda extends StatelessWidget {
  const _EmptyAgenda({
    required this.periodo,
    required this.possuiDemandas,
    required this.onLancarTempo,
  });

  final String periodo;
  final bool possuiDemandas;
  final VoidCallback? onLancarTempo;

  @override
  Widget build(BuildContext context) => Card(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available,
              size: 52,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('Nenhum tempo lançado $periodo.', textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              possuiDemandas
                  ? 'Registre o trabalho executado em uma demanda.'
                  : 'Cadastre uma demanda antes de lançar tempo.',
              textAlign: TextAlign.center,
            ),
            if (onLancarTempo != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onLancarTempo,
                icon: const Icon(Icons.add),
                label: const Text('Lançar tempo'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _ErrorAgenda extends StatelessWidget {
  const _ErrorAgenda({required this.mensagem, required this.onTentarNovamente});

  final String mensagem;
  final Future<void> Function() onTentarNovamente;

  @override
  Widget build(BuildContext context) => Card(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(mensagem, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('recarregar-agenda'),
              onPressed: onTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SelecionarDemandaDialog extends StatefulWidget {
  const _SelecionarDemandaDialog({required this.demandas});

  final List<backend.Demanda> demandas;

  @override
  State<_SelecionarDemandaDialog> createState() =>
      _SelecionarDemandaDialogState();
}

class _SelecionarDemandaDialogState extends State<_SelecionarDemandaDialog> {
  late int _demandaId = widget.demandas.first.id!;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Selecionar demanda'),
    content: SizedBox(
      width: 460,
      child: DropdownButtonFormField<int>(
        key: const ValueKey('selecionar-demanda-log-time'),
        initialValue: _demandaId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Demanda'),
        items: widget.demandas
            .map(
              (demanda) => DropdownMenuItem(
                value: demanda.id!,
                child: Text(
                  demanda.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _demandaId = value);
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        key: const ValueKey('confirmar-demanda-log-time'),
        onPressed: () => Navigator.pop(context, _demandaId),
        child: const Text('Continuar'),
      ),
    ],
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
