import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../view_model/agenda_view_model.dart';
import '../formatters/demanda_identificacao.dart';

typedef LogTimeCalendarAction =
    Future<void> Function(backend.RegistroTempo registro);

/// Shared temporal grid used by both the day and week agenda views.
class LogTimeCalendar extends StatefulWidget {
  const LogTimeCalendar({
    super.key,
    required this.viewModel,
    required this.onEditar,
    required this.onExcluir,
  });

  final AgendaViewModel viewModel;
  final LogTimeCalendarAction onEditar;
  final LogTimeCalendarAction onExcluir;

  @override
  State<LogTimeCalendar> createState() => _LogTimeCalendarState();
}

class _LogTimeCalendarState extends State<LogTimeCalendar> {
  static const hourHeight = 64.0;
  static const dayWidth = 156.0;
  final _verticalController = ScrollController();
  Object? _periodKey;

  @override
  void initState() {
    super.initState();
    _periodKey = _currentPeriodKey;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEight());
  }

  @override
  void didUpdateWidget(covariant LogTimeCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_periodKey != _currentPeriodKey) {
      _periodKey = _currentPeriodKey;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEight());
    }
  }

  Object get _currentPeriodKey =>
      (widget.viewModel.mode, widget.viewModel.inicioPeriodoLocal);

  void _scrollToEight() {
    if (!mounted || !_verticalController.hasClients) return;
    _verticalController.jumpTo(8 * hourHeight);
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.viewModel.mode == AgendaMode.dia
        ? [widget.viewModel.dataSelecionada]
        : widget.viewModel.diasDaSemana;
    final minimumWidth = 72 + days.length * dayWidth;

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = minimumWidth > constraints.maxWidth
              ? minimumWidth
              : constraints.maxWidth;
          final columnWidth = (width - 72) / days.length;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  _CalendarHeaders(days: days, columnWidth: columnWidth),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _verticalController,
                      child: SizedBox(
                        height: 24 * hourHeight,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _TimeAxis(),
                            ...days.map(
                              (day) => _DayColumn(
                                day: day,
                                columnWidth: columnWidth,
                                registros: widget.viewModel.registrosDoDia(day),
                                demandaPorId: widget.viewModel.demandaPorId,
                                onEditar: widget.onEditar,
                                onExcluir: widget.onExcluir,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CalendarHeaders extends StatelessWidget {
  const _CalendarHeaders({required this.days, required this.columnWidth});
  final List<DateTime> days;
  final double columnWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: Row(
      children: [
        const SizedBox(width: 72),
        ...days.map((day) {
          final hoje = _sameDay(day, DateTime.now());
          return SizedBox(
            width: columnWidth,
            child: Container(
              margin: const EdgeInsets.only(right: 1),
              color: hoje
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: .35)
                  : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_weekday(day.weekday)),
                  Text(
                    '${day.day.toString().padLeft(2, '0')}/'
                    '${day.month.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}

class _TimeAxis extends StatelessWidget {
  const _TimeAxis();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 72,
    child: Stack(
      children: List.generate(
        24,
        (hour) => Positioned(
          top: hour * _LogTimeCalendarState.hourHeight - 8,
          left: 0,
          right: 8,
          child: Text(
            '${_calendarTwoDigits(hour)}:00',
            textAlign: TextAlign.right,
          ),
        ),
      ),
    ),
  );
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.day,
    required this.columnWidth,
    required this.registros,
    required this.demandaPorId,
    required this.onEditar,
    required this.onExcluir,
  });

  final DateTime day;
  final double columnWidth;
  final List<backend.RegistroTempo> registros;
  final backend.Demanda? Function(int) demandaPorId;
  final LogTimeCalendarAction onEditar;
  final LogTimeCalendarAction onExcluir;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: columnWidth,
    child: Stack(
      children: [
        ...List.generate(
          24,
          (hour) => Positioned(
            top: hour * _LogTimeCalendarState.hourHeight,
            left: 0,
            right: 0,
            child: Container(
              height: _LogTimeCalendarState.hourHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .35),
                  ),
                ),
              ),
            ),
          ),
        ),
        ...registros.map(
          (registro) => _CalendarBlock(
            registro: registro,
            demanda: demandaPorId(registro.demandaId),
            onEditar: onEditar,
            onExcluir: onExcluir,
          ),
        ),
      ],
    ),
  );
}

class _CalendarBlock extends StatelessWidget {
  const _CalendarBlock({
    required this.registro,
    required this.demanda,
    required this.onEditar,
    required this.onExcluir,
  });

  final backend.RegistroTempo registro;
  final backend.Demanda? demanda;
  final LogTimeCalendarAction onEditar;
  final LogTimeCalendarAction onExcluir;

  @override
  Widget build(BuildContext context) {
    final inicio = registro.inicioEm.toLocal();
    final inicioMinutos = (inicio.hour * 60 + inicio.minute).clamp(0, 1439);
    final minutosVisiveis = registro.duracaoMinutos.clamp(
      1,
      1440 - inicioMinutos,
    );
    final alturaTemporal =
        minutosVisiveis * _LogTimeCalendarState.hourHeight / 60;
    final gapVisual = alturaTemporal >= 16 ? 2.0 : 0.0;
    final alturaRenderizada = math
        .max(0, alturaTemporal - gapVisual)
        .toDouble();
    final title = demanda == null
        ? 'Demanda #${registro.demandaId}'
        : formatarIdentificacaoDemanda(demanda!);
    final horario =
        '${_calendarTwoDigits(inicio.hour)}:${_calendarTwoDigits(inicio.minute)} – '
        '${_calendarTwoDigits((inicioMinutos + registro.duracaoMinutos) ~/ 60 % 24)}:'
        '${_calendarTwoDigits((inicioMinutos + registro.duracaoMinutos) % 60)}';

    return Positioned(
      top: inicioMinutos * _LogTimeCalendarState.hourHeight / 60,
      left: 5,
      right: 5,
      height: alturaRenderizada,
      child: Tooltip(
        message: '$title\n$horario',
        child: Material(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            key: ValueKey('editar-registro-${registro.id}'),
            borderRadius: BorderRadius.circular(8),
            onTap: registro.id == null
                ? null
                : () => unawaited(onEditar(registro)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final alturaDisponivel = constraints.maxHeight;
                final mostrarHorario = alturaDisponivel >= 40;
                final alturaAcao = math.min(28, alturaDisponivel).toDouble();
                final tamanhoIcone = math.min(17, alturaDisponivel).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: mostrarHorario ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (mostrarHorario)
                              Text(
                                horario,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        height: alturaAcao,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints.tightFor(
                            width: 28,
                            height: alturaAcao,
                          ),
                          tooltip: 'Excluir',
                          color: Theme.of(context).colorScheme.error,
                          onPressed: registro.id == null
                              ? null
                              : () => unawaited(onExcluir(registro)),
                          icon: Icon(Icons.delete_outline, size: tamanhoIcone),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekday(int weekday) =>
    const ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'][weekday - 1];

String _calendarTwoDigits(int value) => value.toString().padLeft(2, '0');
