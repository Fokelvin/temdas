import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../view_model/agenda_view_model.dart';
import '../formatters/demanda_identificacao.dart';

typedef LogTimeCalendarAction =
    Future<void> Function(backend.RegistroTempo registro);
typedef LogTimeCalendarMove =
    Future<bool> Function(
      backend.RegistroTempo registro,
      DateTime data,
      TimeOfDay hora,
    );

/// Shared temporal grid used by both the day and week agenda views.
class LogTimeCalendar extends StatefulWidget {
  const LogTimeCalendar({
    super.key,
    required this.viewModel,
    required this.onEditar,
    required this.onExcluir,
    required this.onMover,
  });

  final AgendaViewModel viewModel;
  final LogTimeCalendarAction onEditar;
  final LogTimeCalendarAction onExcluir;
  final LogTimeCalendarMove onMover;

  @override
  State<LogTimeCalendar> createState() => _LogTimeCalendarState();
}

class _LogTimeCalendarState extends State<LogTimeCalendar> {
  static const hourHeight = 64.0;
  static const dayWidth = 156.0;
  static const minutesPerDay = 24 * 60;
  static const snapMinutes = 15;
  final _verticalController = ScrollController();
  final Map<String, GlobalKey> _dayKeys = {};
  Object? _periodKey;
  backend.RegistroTempo? _registroArrastado;
  _RegistroDropPreview? _dropPreview;
  bool _dropPreviewVisivel = false;

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
                                key: ValueKey('log-time-day-${_dateKey(day)}'),
                                day: day,
                                dayKey: _dayKey(day),
                                columnWidth: columnWidth,
                                registros: widget.viewModel.registrosDoDia(day),
                                demandaPorId: widget.viewModel.demandaPorId,
                                onEditar: widget.onEditar,
                                onExcluir: widget.onExcluir,
                                onMover: widget.onMover,
                                onDragStarted: _iniciarDrag,
                                onDragFinished: _finalizarDrag,
                                onDragMove: _atualizarDropPreview,
                                onDragLeave: _limparDropPreview,
                                dropPreview: _dropPreviewVisivel
                                    ? _dropPreview
                                    : null,
                                registroArrastadoId: _registroArrastado?.id,
                                podeArrastar: !widget.viewModel.enviando,
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

  void _iniciarDrag(backend.RegistroTempo registro) {
    if (!mounted) return;
    setState(() {
      _registroArrastado = registro;
      _dropPreview = null;
      _dropPreviewVisivel = false;
    });
  }

  void _finalizarDrag(DraggableDetails details) {
    if (!mounted) return;
    final preview = _dropPreview;
    if (!details.wasAccepted &&
        preview != null &&
        preview.valido &&
        _ponteiroDentroDoDia(preview.day, details.offset)) {
      unawaited(widget.onMover(preview.registro, preview.day, preview.hora));
    }
    setState(() {
      _registroArrastado = null;
      _dropPreview = null;
      _dropPreviewVisivel = false;
    });
  }

  bool _atualizarDropPreview(
    backend.RegistroTempo registro,
    DateTime day,
    double localOffset,
  ) {
    if (_registroArrastado?.id != registro.id) return false;
    final preview = _previewFromLocalOffset(registro, day, localOffset);
    if (!mounted) return preview.valido;
    if (_dropPreview != preview || !_dropPreviewVisivel) {
      setState(() {
        _dropPreview = preview;
        _dropPreviewVisivel = true;
      });
    }
    return preview.valido;
  }

  void _limparDropPreview(backend.RegistroTempo? registro) {
    if (!mounted || registro == null || _registroArrastado?.id != registro.id) {
      return;
    }
    if (_dropPreviewVisivel) setState(() => _dropPreviewVisivel = false);
  }

  GlobalKey _dayKey(DateTime day) =>
      _dayKeys.putIfAbsent(_dateKey(day), GlobalKey.new);

  bool _ponteiroDentroDoDia(DateTime day, Offset globalPosition) {
    final renderObject = _dayKeys[_dateKey(day)]?.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return false;
    final localPosition = renderObject.globalToLocal(globalPosition);
    return localPosition.dx >= 0 &&
        localPosition.dx <= renderObject.size.width &&
        localPosition.dy >= 0 &&
        localPosition.dy <= renderObject.size.height;
  }
}

_RegistroDropPreview _previewFromLocalOffset(
  backend.RegistroTempo registro,
  DateTime day,
  double localOffset,
) {
  final minutos =
      (localOffset * Duration.minutesPerHour / _LogTimeCalendarState.hourHeight)
          .round();
  final inicioMinutos =
      (minutos / _LogTimeCalendarState.snapMinutes).round() *
      _LogTimeCalendarState.snapMinutes;
  return _RegistroDropPreview(
    registro: registro,
    day: day,
    inicioMinutos: inicioMinutos,
  );
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
    super.key,
    required this.day,
    required this.dayKey,
    required this.columnWidth,
    required this.registros,
    required this.demandaPorId,
    required this.onEditar,
    required this.onExcluir,
    required this.onMover,
    required this.onDragStarted,
    required this.onDragFinished,
    required this.onDragMove,
    required this.onDragLeave,
    required this.dropPreview,
    required this.registroArrastadoId,
    required this.podeArrastar,
  });

  final DateTime day;
  final GlobalKey dayKey;
  final double columnWidth;
  final List<backend.RegistroTempo> registros;
  final backend.Demanda? Function(int) demandaPorId;
  final LogTimeCalendarAction onEditar;
  final LogTimeCalendarAction onExcluir;
  final LogTimeCalendarMove onMover;
  final ValueChanged<backend.RegistroTempo> onDragStarted;
  final ValueChanged<DraggableDetails> onDragFinished;
  final bool Function(backend.RegistroTempo, DateTime, double) onDragMove;
  final ValueChanged<backend.RegistroTempo?> onDragLeave;
  final _RegistroDropPreview? dropPreview;
  final int? registroArrastadoId;
  final bool podeArrastar;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: dayKey,
    width: columnWidth,
    child: Builder(
      builder: (columnContext) => DragTarget<backend.RegistroTempo>(
        onWillAcceptWithDetails: (details) {
          final localOffset = _localOffset(columnContext, details.offset);
          return _atualizarPreview(details.data, localOffset);
        },
        onMove: (details) {
          final localOffset = _localOffset(columnContext, details.offset);
          _atualizarPreview(details.data, localOffset);
        },
        onLeave: (registro) => onDragLeave(registro),
        onAcceptWithDetails: (details) {
          final localOffset = _localOffset(columnContext, details.offset);
          final preview = _previewFromLocalOffset(
            details.data,
            day,
            localOffset,
          );
          if (!preview.valido) return;
          unawaited(onMover(details.data, preview.day, preview.hora));
        },
        builder: (context, candidates, rejected) => Stack(
          clipBehavior: Clip.hardEdge,
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
                onDragStarted: onDragStarted,
                onDragFinished: onDragFinished,
                arrastando: registro.id == registroArrastadoId,
                podeArrastar: podeArrastar,
              ),
            ),
            if (dropPreview != null && _sameDay(dropPreview!.day, day))
              _DropPreviewBlock(preview: dropPreview!),
          ],
        ),
      ),
    ),
  );

  double _localOffset(BuildContext context, Offset globalPosition) {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return 0;
    return renderObject.globalToLocal(globalPosition).dy;
  }

  bool _atualizarPreview(backend.RegistroTempo registro, double localOffset) {
    return onDragMove(registro, day, localOffset);
  }
}

class _CalendarBlock extends StatelessWidget {
  const _CalendarBlock({
    required this.registro,
    required this.demanda,
    required this.onEditar,
    required this.onExcluir,
    required this.onDragStarted,
    required this.onDragFinished,
    required this.arrastando,
    required this.podeArrastar,
  });

  final backend.RegistroTempo registro;
  final backend.Demanda? demanda;
  final LogTimeCalendarAction onEditar;
  final LogTimeCalendarAction onExcluir;
  final ValueChanged<backend.RegistroTempo> onDragStarted;
  final ValueChanged<DraggableDetails> onDragFinished;
  final bool arrastando;
  final bool podeArrastar;

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
      child: IgnorePointer(
        ignoring: arrastando,
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
                  final tamanhoIcone = math
                      .min(17, alturaDisponivel)
                      .toDouble();
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
                        _dragHandle(context, alturaAcao, tamanhoIcone),
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
                            icon: Icon(
                              Icons.delete_outline,
                              size: tamanhoIcone,
                            ),
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
      ),
    );
  }

  Widget _dragHandle(BuildContext context, double height, double iconSize) {
    final enabled = podeArrastar && registro.id != null;
    return Draggable<backend.RegistroTempo>(
      key: ValueKey('mover-registro-${registro.id}'),
      data: registro,
      maxSimultaneousDrags: enabled ? 1 : 0,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      allowedButtonsFilter: (buttons) => buttons == kPrimaryButton,
      onDragStarted: () => onDragStarted(registro),
      onDragEnd: onDragFinished,
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: SizedBox(
          width: 180,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_horarioDrag(registro)),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: .35,
        child: _visualDragHandle(height, iconSize),
      ),
      child: _visualDragHandle(height, iconSize),
    );
  }

  Widget _visualDragHandle(double height, double iconSize) => Tooltip(
    message: 'Mover registro',
    child: MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox(
        width: 22,
        height: height,
        child: Center(child: Icon(Icons.drag_indicator, size: iconSize)),
      ),
    ),
  );

  String _horarioDrag(backend.RegistroTempo registro) {
    final inicio = registro.inicioEm.toLocal();
    final fim = inicio.add(Duration(minutes: registro.duracaoMinutos));
    return '${_calendarTwoDigits(inicio.hour)}:${_calendarTwoDigits(inicio.minute)} – '
        '${_calendarTwoDigits(fim.hour)}:${_calendarTwoDigits(fim.minute)}';
  }
}

class _DropPreviewBlock extends StatelessWidget {
  const _DropPreviewBlock({required this.preview});

  final _RegistroDropPreview preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final top = preview.inicioMinutos * _LogTimeCalendarState.hourHeight / 60;
    final height = math.max(
      2,
      math.min(
        preview.registro.duracaoMinutos,
        _LogTimeCalendarState.minutesPerDay - preview.inicioMinutos,
      ),
    );
    final color = preview.valido ? colors.primary : colors.error;
    return Positioned(
      top: top,
      left: 5,
      right: 5,
      height: height * _LogTimeCalendarState.hourHeight / 60,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: .24),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                preview.horario,
                key: const ValueKey('log-time-drop-preview'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistroDropPreview {
  const _RegistroDropPreview({
    required this.registro,
    required this.day,
    required this.inicioMinutos,
  });

  final backend.RegistroTempo registro;
  final DateTime day;
  final int inicioMinutos;

  bool get valido =>
      inicioMinutos >= 0 &&
      inicioMinutos + registro.duracaoMinutos <=
          _LogTimeCalendarState.minutesPerDay;

  TimeOfDay get hora =>
      TimeOfDay(hour: inicioMinutos ~/ 60, minute: inicioMinutos % 60);

  String get horario {
    final fim = inicioMinutos + registro.duracaoMinutos;
    return '${_calendarTwoDigits(inicioMinutos ~/ 60)}:'
        '${_calendarTwoDigits(inicioMinutos % 60)} – '
        '${_calendarTwoDigits(fim ~/ 60 % 24)}:${_calendarTwoDigits(fim % 60)}';
  }

  @override
  bool operator ==(Object other) =>
      other is _RegistroDropPreview &&
      other.registro.id == registro.id &&
      _sameDay(other.day, day) &&
      other.inicioMinutos == inicioMinutos;

  @override
  int get hashCode => Object.hash(registro.id, day, inicioMinutos);
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekday(int weekday) =>
    const ['SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB', 'DOM'][weekday - 1];

String _calendarTwoDigits(int value) => value.toString().padLeft(2, '0');

String _dateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
