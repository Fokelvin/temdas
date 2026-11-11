part of 'demand_components.dart';

// A composição Normal fica na biblioteca principal. As duas composições
// compactas reutilizam controles, dados e callbacks existentes.
class _CompactDemandCard extends StatelessWidget {
  const _CompactDemandCard({required this.card});
  final DemandCard card;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return HoverRegion(
      focusBorderRadius: BorderRadius.circular(AppTokens.cardRadius),
      child: Material(
        color: card.highlighted && t.darkContrast ? t.cardHover : t.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.cardRadius),
          side: BorderSide(
            color: card.highlighted ? AppTokens.accent : t.surfaceBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('abrir-painel-demanda-${card.demand.id}'),
          onTap: card.onTap,
          hoverColor: t.cardHover,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CompactHeadline(
                  id: card.demand.id,
                  title: card.demand.titulo,
                  status: card.demand.status,
                  chevron: card.chevron,
                  actions: card.actions,
                  dragHandle: card.dragHandle,
                ),
                LayoutBuilder(
                  builder: (context, box) {
                    final hours = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HoursLabel(
                          minutes: card.real,
                          estimate: card.demand.tempoEstimadoMinutos,
                        ),
                        const SizedBox(width: 4),
                        HoursMeter(
                          real: card.real,
                          estimate: card.demand.tempoEstimadoMinutos,
                          width: 24,
                        ),
                      ],
                    );
                    return Wrap(
                      key: const ValueKey('compact-kanban-metadata'),
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PriorityTag(priority: card.demand.prioridade),
                        if (card.sprint != null)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: box.maxWidth * .34,
                            ),
                            child: card.sprint!,
                          ),
                        hours,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactHeadline extends StatelessWidget {
  const _CompactHeadline({
    required this.id,
    required this.title,
    required this.status,
    required this.chevron,
    required this.actions,
    this.dragHandle,
    this.onTap,
  });
  final int? id;
  final String title;
  final b.DemandaStatus status;
  final Widget chevron, actions;
  final Widget? dragHandle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 1024;
    final t = AppTokens.of(context);
    return Row(
      children: [
        if (dragHandle != null) SizedBox(width: 24, child: dragHandle),
        SizedBox(width: mobile ? 44 : 28, child: chevron),
        Text(
          '#${id ?? '–'}',
          style: TextStyle(
            fontFamily: 'Roboto Mono',
            fontSize: 12,
            color: t.metadata,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Tooltip(
            message: title,
            child: InkWell(
              key: onTap == null ? null : ValueKey('abrir-painel-demanda-$id'),
              onTap: onTap,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: status == b.DemandaStatus.concluida
                      ? t.secondaryLabel
                      : t.text,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: mobile ? 44 : 32, child: actions),
      ],
    );
  }
}

/// As mesmas larguras são usadas pelo cabeçalho e pelas linhas, incluindo
/// a compensação do recuo da árvore: o final das colunas permanece alinhado.
class _CompactColumns extends StatelessWidget {
  const _CompactColumns({
    required this.chevron,
    required this.id,
    required this.title,
    required this.priority,
    required this.estimate,
    required this.real,
    required this.sprint,
    required this.status,
    required this.actions,
  });
  final Widget chevron,
      id,
      title,
      priority,
      estimate,
      real,
      sprint,
      status,
      actions;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return Row(
      children: [
        SizedBox(width: 28, child: chevron),
        SizedBox(width: 44, child: id),
        Expanded(child: title),
        const SizedBox(width: 8),
        SizedBox(width: wide ? 76 : 84, child: priority),
        if (wide)
          SizedBox(
            width: 56,
            child: Align(alignment: Alignment.centerRight, child: estimate),
          ),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Align(alignment: Alignment.centerRight, child: real),
        ),
        const SizedBox(width: 8),
        SizedBox(width: wide ? 112 : 84, child: sprint),
        const SizedBox(width: 8),
        SizedBox(width: 112, child: status),
        SizedBox(width: 32, child: actions),
      ],
    );
  }
}

class _CompactDemandHeader extends StatelessWidget {
  const _CompactDemandHeader();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      if (box.maxWidth < 680) return const SizedBox.shrink();
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: AppTokens.of(context).bg,
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: AppTokens.of(context).secondaryLabel,
          ),
          child: const _CompactColumns(
            chevron: SizedBox(),
            id: Text('ID'),
            title: Text('Demanda'),
            priority: Text('Prioridade'),
            estimate: Text('Est.'),
            real: Text('Real'),
            sprint: Text('Sprint'),
            status: Text('Status'),
            actions: SizedBox(),
          ),
        ),
      );
    },
  );
}

class _CompactDemandRow extends StatelessWidget {
  const _CompactDemandRow({required this.row});
  final DemandRow row;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final t = AppTokens.of(context);
      final mobile = box.maxWidth < 680;
      final Widget content;
      if (mobile) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CompactHeadline(
              id: row.id,
              title: row.title,
              status: row.status,
              chevron: row.chevron,
              actions: row.actions,
              onTap: row.onTap,
            ),
            Row(
              children: [
                PriorityTag(priority: row.priority),
                const SizedBox(width: 4),
                if (row.sprint != null) SizedBox(width: 76, child: row.sprint!),
                const SizedBox(width: 4),
                Flexible(
                  child: HoursLabel(minutes: row.hours, estimate: row.estimate),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  width: box.maxWidth < 400 ? 92 : 112,
                  child: row.statusWidget(context),
                ),
              ],
            ),
          ],
        );
      } else {
        content = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: _CompactColumns(
            chevron: row.chevron,
            id: row._id(context),
            title: Tooltip(message: row.title, child: row._title(context)),
            priority: PriorityTag(priority: row.priority),
            estimate: HoursLabel(minutes: row.estimate),
            real: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: HoursLabel(
                    minutes: row.hours,
                    estimate: MediaQuery.sizeOf(context).width < 1100
                        ? row.estimate
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                HoursMeter(real: row.hours, estimate: row.estimate, width: 24),
              ],
            ),
            sprint: row.sprint ?? const SizedBox.shrink(),
            status: row.statusWidget(context),
            actions: row.actions,
          ),
        );
      }
      return HoverRegion(
        focusBorderRadius: BorderRadius.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: row.onTap,
            hoverColor: t.hover,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: t.border)),
              ),
              child: content,
            ),
          ),
        ),
      );
    },
  );
}
