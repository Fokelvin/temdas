import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import '../theme/tokens.dart';

String statusLabel(b.DemandaStatus s) => switch (s) {
  b.DemandaStatus.aberta => 'Aberta',
  b.DemandaStatus.emAndamento => 'Em andamento',
  b.DemandaStatus.pausada => 'Pausada',
  b.DemandaStatus.concluida => 'Concluída',
  b.DemandaStatus.cancelada => 'Cancelada',
};
Color statusColor(b.DemandaStatus s) => switch (s) {
  b.DemandaStatus.aberta => AppTokens.open,
  b.DemandaStatus.emAndamento => AppTokens.accent,
  b.DemandaStatus.pausada => AppTokens.medium,
  b.DemandaStatus.concluida => AppTokens.low,
  b.DemandaStatus.cancelada => AppTokens.cancelled,
};

class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.size = 8});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class PriorityTag extends StatelessWidget {
  const PriorityTag({super.key, required this.priority});
  final b.Prioridade priority;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      StatusDot(
        size: 6,
        color: switch (priority) {
          b.Prioridade.baixa => AppTokens.low,
          b.Prioridade.media => AppTokens.medium,
          _ => AppTokens.high,
        },
      ),
      const SizedBox(width: 4),
      Text(switch (priority) {
        b.Prioridade.baixa => 'Baixa',
        b.Prioridade.media => 'Média',
        b.Prioridade.alta => 'Alta',
        b.Prioridade.urgente => 'Urgente',
      }, style: TextStyle(fontSize: 12, color: AppTokens.of(context).text2)),
    ],
  );
}

class SprintTag extends StatelessWidget {
  const SprintTag({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: TextStyle(fontSize: 12, color: AppTokens.of(context).text2),
    child: child,
  );
}

class HoursLabel extends StatelessWidget {
  const HoursLabel({
    super.key,
    required this.minutes,
    this.estimate,
    this.compact = false,
  });
  final int minutes;
  final int? estimate;
  final bool compact;
  static String format(int minutes) => (minutes / 60)
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: format(minutes),
            style: TextStyle(color: minutes == 0 ? t.text2 : t.text),
          ),
          if (estimate != null)
            TextSpan(
              text: ' / ${format(estimate!)}',
              style: TextStyle(color: t.text2),
            ),
          const TextSpan(text: ' h'),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 11 : 12,
        color: t.text2,
        fontFeatures: AppTokens.numbers,
      ),
    );
  }
}

class HoursMeter extends StatelessWidget {
  const HoursMeter({
    super.key,
    required this.real,
    required this.estimate,
    this.width = 44,
  });
  final int real, estimate;
  final double width;
  @override
  Widget build(BuildContext context) => estimate <= 0
      ? const SizedBox.shrink()
      : ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            width: width,
            height: 3,
            child: LinearProgressIndicator(
              value: (real / estimate).clamp(0, 1),
              color: real >= estimate ? AppTokens.low : AppTokens.accent,
              backgroundColor: AppTokens.of(context).borderStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});
  final b.DemandaStatus status;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: t.borderStrong),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusDot(color: statusColor(status), size: 6),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              statusLabel(status),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: t.text2),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Symbols.expand_more_rounded, size: 12, color: t.text2),
        ],
      ),
    );
  }
}

class GroupHeader extends StatelessWidget {
  const GroupHeader({
    super.key,
    required this.status,
    required this.count,
    this.collapsed = false,
    this.onTap,
  });
  final b.DemandaStatus status;
  final int count;
  final bool collapsed;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (onTap != null) ...[
              AnimatedRotation(
                turns: collapsed ? -.25 : 0,
                duration: AppTokens.motion(context),
                child: const Icon(Symbols.expand_more_rounded, size: 16),
              ),
              const SizedBox(width: 4),
            ],
            StatusDot(color: statusColor(status)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                statusLabel(status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                color: AppTokens.of(context).text2,
                fontSize: 12,
                fontFeatures: AppTokens.numbers,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class EmptyStatusesLine extends StatelessWidget {
  const EmptyStatusesLine({super.key, required this.statuses});
  final List<b.DemandaStatus> statuses;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Sem demandas',
          style: TextStyle(fontSize: 12, color: AppTokens.of(context).text2),
        ),
        for (final s in statuses)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusDot(color: statusColor(s), size: 6),
              const SizedBox(width: 4),
              Text(
                '${statusLabel(s)} 0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTokens.of(context).text2,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

class DemandTableHeader extends StatelessWidget {
  const DemandTableHeader({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (MediaQuery.sizeOf(context).width < 600) {
        return const SizedBox.shrink();
      }
      final desktop = box.maxWidth >= 960;
      Widget cell(String s, double w, [bool right = false]) => SizedBox(
        width: w,
        child: Text(s, textAlign: right ? TextAlign.right : TextAlign.left),
      );
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: AppTokens.of(context).bg,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppTokens.of(context).text2,
          ),
          child: Row(
            children: [
              const SizedBox(width: 28),
              cell('ID', 44),
              const Expanded(child: Text('Demanda')),
              cell('Prioridade', desktop ? 100 : 76),
              if (desktop) ...[
                cell('Sprint', 84),
                cell('Est.', 64, true),
                const SizedBox(width: 12),
                cell('Real', 112, true),
              ] else
                cell('Real / Est.', 108, true),
              const SizedBox(width: 12),
              cell('Status', 136),
              const SizedBox(width: 32),
            ],
          ),
        ),
      );
    },
  );
}

class DemandRow extends StatelessWidget {
  const DemandRow({
    super.key,
    required this.id,
    required this.title,
    required this.priority,
    required this.hours,
    required this.estimate,
    required this.status,
    required this.actions,
    required this.chevron,
    required this.onTap,
    this.sprint,
    this.statusControl,
  });
  final int? id;
  final String title;
  final b.Prioridade priority;
  final int hours, estimate;
  final b.DemandaStatus status;
  final Widget actions, chevron;
  final VoidCallback? onTap;
  final Widget? sprint;
  Widget _id(BuildContext context) => Text(
    '#${id ?? '–'}',
    maxLines: 1,
    style: TextStyle(
      fontFamily: 'Roboto Mono',
      fontSize: 12,
      color: AppTokens.of(context).text2,
      fontFeatures: AppTokens.numbers,
    ),
  );
  Widget _title(BuildContext context) => InkWell(
    key: ValueKey('abrir-painel-demanda-$id'),
    onTap: onTap,
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: status == b.DemandaStatus.concluida
              ? AppTokens.of(context).text2
              : AppTokens.of(context).text,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final mobile =
          MediaQuery.sizeOf(context).width < 600 || box.maxWidth < 560;
      final desktop = box.maxWidth >= 960;
      final t = AppTokens.of(context);
      final hoursWidget = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          HoursLabel(minutes: hours, estimate: desktop ? null : estimate),
          const SizedBox(height: 4),
          HoursMeter(real: hours, estimate: estimate),
        ],
      );
      return HoverRegion(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            hoverColor: t.hover,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: mobile ? 8 : 0,
              ),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border)),
              ),
              child: mobile
                  ? Column(
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width < 1024
                                  ? 44
                                  : 28,
                              child: chevron,
                            ),
                            _id(context),
                            const SizedBox(width: 8),
                            Expanded(child: _title(context)),
                            SizedBox(width: 44, child: actions),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            PriorityTag(priority: priority),
                            const SizedBox(width: 8),
                            if (sprint != null) ...[
                              SizedBox(width: 44, child: sprint),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: HoursLabel(
                                  minutes: hours,
                                  estimate: estimate,
                                  compact: true,
                                ),
                              ),
                            ),
                            if (box.maxWidth >= 400) ...[
                              const SizedBox(width: 4),
                              HoursMeter(
                                real: hours,
                                estimate: estimate,
                                width: 32,
                              ),
                            ],
                            const SizedBox(width: 8),
                            SizedBox(width: 112, child: statusWidget(context)),
                          ],
                        ),
                      ],
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Row(
                        children: [
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width < 1024
                                ? 44
                                : 28,
                            child: chevron,
                          ),
                          SizedBox(width: 44, child: _id(context)),
                          Expanded(child: _title(context)),
                          SizedBox(
                            width: desktop ? 100 : 76,
                            child: PriorityTag(priority: priority),
                          ),
                          if (desktop) ...[
                            SizedBox(width: 84, child: sprint),
                            SizedBox(
                              width: 64,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: HoursLabel(minutes: estimate),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          SizedBox(
                            width: desktop ? 112 : 108,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: hoursWidget,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(width: 136, child: statusWidget(context)),
                          SizedBox(
                            width: MediaQuery.sizeOf(context).width < 1024
                                ? 44
                                : 32,
                            child: actions,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      );
    },
  );
  // The interactive menu is supplied by the existing card, preserving transitions.
  Widget statusWidget(BuildContext context) =>
      statusControl ?? StatusPill(status: status);
  final Widget? statusControl;
}

class DemandCard extends StatelessWidget {
  const DemandCard({
    super.key,
    required this.demand,
    required this.real,
    required this.actions,
    required this.chevron,
    this.sprint,
    this.dragHandle,
    this.onTap,
    this.highlighted = false,
  });
  final b.Demanda demand;
  final int real;
  final Widget actions, chevron;
  final Widget? sprint, dragHandle;
  final VoidCallback? onTap;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return HoverRegion(
      child: Material(
        color: t.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: highlighted ? AppTokens.accent : t.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('abrir-painel-demanda-${demand.id}'),
          onTap: onTap,
          hoverColor: t.hover,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (dragHandle != null)
                      SizedBox(width: 24, child: dragHandle),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width < 1024 ? 44 : 24,
                      child: chevron,
                    ),
                    Text(
                      '#${demand.id ?? '–'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Roboto Mono',
                        color: t.text2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        demand.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: demand.status == b.DemandaStatus.concluida
                              ? t.text2
                              : t.text,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.sizeOf(context).width < 1024 ? 44 : 32,
                      child: actions,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    PriorityTag(priority: demand.prioridade),
                    const SizedBox(width: 8),
                    if (sprint != null)
                      Expanded(child: ClipRect(child: sprint!)),
                    if (sprint == null) const Spacer(),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          HoursLabel(
                            minutes: real,
                            estimate: demand.tempoEstimadoMinutos,
                            compact: true,
                          ),
                          const SizedBox(height: 4),
                          HoursMeter(
                            real: real,
                            estimate: demand.tempoEstimadoMinutos,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.status,
    required this.count,
    required this.child,
    this.collapsed = false,
    this.target = false,
  });
  final b.DemandaStatus status;
  final int count;
  final Widget child;
  final bool collapsed, target;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return CustomPaint(
      foregroundPainter: target ? const DashedOutline() : null,
      child: AnimatedContainer(
        duration: AppTokens.motion(context, 200),
        curve: AppTokens.curve,
        decoration: BoxDecoration(
          color: target ? t.accentSoft : t.surface,
          border: Border.all(color: target ? AppTokens.accent : t.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: collapsed
            ? Stack(
                children: [
                  Positioned.fill(child: child),
                  IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              StatusDot(color: statusColor(status)),
                              const SizedBox(width: 8),
                              Text(
                                '${statusLabel(status)}  0',
                                style: TextStyle(fontSize: 12, color: t.text2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  GroupHeader(status: status, count: count),
                  Divider(height: 1, color: t.border),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: child,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class StatusTabs extends StatelessWidget {
  const StatusTabs({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: children),
  );
}

class SkeletonRow extends StatelessWidget {
  const SkeletonRow({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: MediaQuery.sizeOf(context).width < 600 ? 80 : 40,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: AppTokens.of(context).border)),
    ),
    child: Row(
      children: [
        Container(width: 32, color: AppTokens.of(context).surface2),
        const SizedBox(width: 16),
        Expanded(child: Container(color: AppTokens.of(context).surface2)),
        const SizedBox(width: 40),
      ],
    ),
  );
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    height: 96,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppTokens.of(context).surface,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTokens.of(context).border),
    ),
    child: Column(
      children: [
        Container(height: 16, color: AppTokens.of(context).surface2),
        const SizedBox(height: 16),
        Container(height: 12, color: AppTokens.of(context).surface2),
      ],
    ),
  );
}

class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.onPressed});
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 52,
    child: FloatingActionButton(
      key: const ValueKey('abrir-criar-demanda'),
      tooltip: 'Criar demanda',
      backgroundColor: AppTokens.accent,
      foregroundColor: AppTokens.dark.bg,
      shape: const CircleBorder(),
      onPressed: onPressed,
      child: const Icon(Symbols.add_rounded, size: 24),
    ),
  );
}

/// Keeps keyboard actions reachable when the desktop pointer is outside a row.
class HoverRegion extends StatefulWidget {
  const HoverRegion({super.key, required this.child});
  final Widget child;
  @override
  State<HoverRegion> createState() => _HoverRegionState();
}

class _HoverRegionState extends State<HoverRegion> {
  bool hovered = false, focused = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: Focus(
      onFocusChange: (v) => setState(() => focused = v),
      child: _HoverScope(
        show: hovered || focused || MediaQuery.sizeOf(context).width < 1024,
        child: widget.child,
      ),
    ),
  );
}

class _HoverScope extends InheritedWidget {
  const _HoverScope({required this.show, required super.child});
  final bool show;
  @override
  bool updateShouldNotify(_HoverScope oldWidget) => show != oldWidget.show;
}

class RevealOnHover extends StatelessWidget {
  const RevealOnHover({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => AnimatedOpacity(
    opacity:
        (context.dependOnInheritedWidgetOfExactType<_HoverScope>()?.show ??
            true)
        ? 1
        : 0,
    duration: AppTokens.motion(context),
    child: child,
  );
}

class DashedOutline extends CustomPainter {
  const DashedOutline({this.color = AppTokens.accent});
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)),
      );
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (double start = 0; start < metric.length; start += 8) {
        canvas.drawPath(
          metric.extractPath(start, (start + 4).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DashedOutline oldDelegate) => color != oldDelegate.color;
}

/// Settles horizontal board scrolling at a column edge, including empty rails.
class ColumnSnapPhysics extends ScrollPhysics {
  const ColumnSnapPhysics({required this.stops, super.parent});
  final List<double> stops;
  @override
  ColumnSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      ColumnSnapPhysics(stops: stops, parent: buildParent(ancestor));
  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if (position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }
    final proposed = (position.pixels + velocity * .12).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    final candidates = [
      ...stops.map(
        (v) => v.clamp(position.minScrollExtent, position.maxScrollExtent),
      ),
      position.maxScrollExtent,
    ];
    final target = candidates.reduce(
      (a, b) => (a - proposed).abs() < (b - proposed).abs() ? a : b,
    );
    if ((target - position.pixels).abs() < toleranceFor(position).distance) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}
