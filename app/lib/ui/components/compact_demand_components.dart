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
    this.mostrarId = true,
  });
  final int? id;
  final String title;
  final bool mostrarId;
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
        if (mostrarId)
          Text(
            '#${id ?? '–'}',
            style: TextStyle(
              fontFamily: 'Roboto Mono',
              fontSize: 12,
              color: t.metadata,
            ),
          ),
        if (mostrarId) const SizedBox(width: 8),
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
    required this.criadoEm,
    required this.tipo,
    required this.actions,
  });
  final Widget chevron, title, actions;
  final Widget? id, priority, estimate, real, sprint, status, criadoEm, tipo;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    return Row(
      children: [
        SizedBox(width: 28, child: chevron),
        if (id != null) SizedBox(width: 44, child: id),
        Expanded(child: title),
        if (priority != null) ...[
          const SizedBox(width: 8),
          SizedBox(width: wide ? 76 : 84, child: priority),
        ],
        if (wide && estimate != null)
          SizedBox(
            width: 56,
            child: Align(alignment: Alignment.centerRight, child: estimate),
          ),
        if (real != null) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Align(alignment: Alignment.centerRight, child: real),
          ),
        ],
        if (sprint != null) ...[
          const SizedBox(width: 8),
          SizedBox(width: wide ? 112 : 84, child: sprint),
        ],
        if (status != null) ...[
          const SizedBox(width: 8),
          SizedBox(width: 112, child: status),
        ],
        if (criadoEm != null)
          SizedBox(
            width: _larguraExtra(ColunaDemanda.criadoEm),
            child: criadoEm,
          ),
        if (tipo != null)
          SizedBox(width: _larguraExtra(ColunaDemanda.tipo), child: tipo),
        SizedBox(width: 32, child: actions),
      ],
    );
  }
}

class _CompactDemandRow extends StatelessWidget {
  const _CompactDemandRow({required this.row});
  final DemandRow row;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final t = AppTokens.of(context);
      final mobile = box.maxWidth < 680;
      final wide = MediaQuery.sizeOf(context).width >= 1100;
      final extrasNaLinha = box.maxWidth >= 900;
      final sprintEmLinhaPropria = mobile && box.maxWidth < 280;
      final sprint = row._sprintVisivel;
      final prioridade = row._visivel(ColunaDemanda.prioridade)
          ? PriorityTag(priority: row.priority)
          : null;
      final status = row._visivel(ColunaDemanda.status)
          ? row.statusWidget(context)
          : null;
      final Widget content;
      if (mobile) {
        content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CompactHeadline(
              id: row.id,
              mostrarId: row._visivel(ColunaDemanda.id),
              title: row.title,
              status: row.status,
              chevron: row.chevron,
              actions: row.actions,
              onTap: row.onTap,
            ),
            if (prioridade != null ||
                (!sprintEmLinhaPropria && sprint != null) ||
                row._mostraHoras ||
                status != null)
              Row(
                children: [
                  ?prioridade,
                  if (!sprintEmLinhaPropria && sprint != null) ...[
                    const SizedBox(width: 4),
                    SizedBox(width: 76, child: sprint),
                  ],
                  const SizedBox(width: 4),
                  Flexible(
                    child: row._mostraHoras
                        ? row._horas(separarEstimativa: false)
                        : const SizedBox.shrink(),
                  ),
                  if (status != null) ...[
                    const SizedBox(width: 4),
                    SizedBox(
                      width: box.maxWidth < 400 ? 92 : 112,
                      child: status,
                    ),
                  ],
                ],
              ),
            if (sprintEmLinhaPropria && sprint != null)
              Align(alignment: Alignment.centerLeft, child: sprint),
            row._extrasEmpilhados(),
          ],
        );
      } else {
        content = ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CompactColumns(
                chevron: row.chevron,
                id: row._visivel(ColunaDemanda.id) ? row._id(context) : null,
                title: Tooltip(message: row.title, child: row._title(context)),
                priority: prioridade,
                estimate: row._visivel(ColunaDemanda.estimado)
                    ? HoursLabel(minutes: row.estimate)
                    : null,
                real:
                    (wide
                        ? row._visivel(ColunaDemanda.executado)
                        : row._mostraHoras)
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: row._horas(separarEstimativa: wide)),
                          const SizedBox(width: 6),
                          row._medidor(width: 24),
                        ],
                      )
                    : null,
                sprint: row._visivel(ColunaDemanda.sprint) || row.selecaoEmLote
                    ? row._sprintVisivel ?? const SizedBox.shrink()
                    : null,
                status: status,
                criadoEm: extrasNaLinha && row._visivel(ColunaDemanda.criadoEm)
                    ? row._metadado(
                        ColunaDemanda.criadoEm,
                        row._dataCriacao,
                        true,
                        larguraFixa: false,
                      )
                    : null,
                tipo: extrasNaLinha && row._visivel(ColunaDemanda.tipo)
                    ? row._metadado(
                        ColunaDemanda.tipo,
                        row.tipo ?? '—',
                        true,
                        larguraFixa: false,
                      )
                    : null,
                actions: row.actions,
              ),
              if (!extrasNaLinha) row._extrasEmpilhados(),
            ],
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
