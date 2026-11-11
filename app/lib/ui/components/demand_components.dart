import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;
import '../theme/tokens.dart';
import '../../view/widgets/densidade_demanda.dart';
import '../../view_model/demanda_lista_preferencias.dart';

part 'compact_demand_components.dart';

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
      Text(
        switch (priority) {
          b.Prioridade.baixa => 'Baixa',
          b.Prioridade.media => 'Média',
          b.Prioridade.alta => 'Alta',
          b.Prioridade.urgente => 'Urgente',
        },
        style: TextStyle(
          fontSize: 12,
          color: AppTokens.of(context).secondaryLabel,
        ),
      ),
    ],
  );
}

class SprintTag extends StatelessWidget {
  const SprintTag({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
    style: TextStyle(fontSize: 12, color: AppTokens.of(context).secondaryLabel),
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
            style: TextStyle(
              color: minutes == 0 && !t.darkContrast ? t.text2 : t.text,
            ),
          ),
          if (estimate != null)
            TextSpan(
              text: ' / ${format(estimate!)}',
              style: TextStyle(color: t.secondaryLabel),
            ),
          const TextSpan(text: ' h'),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 11 : 12,
        color: t.secondaryLabel,
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
              backgroundColor: AppTokens.of(context).progressTrack,
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
    this.densidade = DensidadeDemanda.normal,
    this.status,
    this.prioridade,
    required this.count,
    this.collapsed = false,
    this.onTap,
    this.bloqueado = false,
  }) : assert(status != null || prioridade != null);
  final DensidadeDemanda densidade;
  final b.DemandaStatus? status;
  final b.Prioridade? prioridade;
  final int count;
  final bool collapsed;
  final bool bloqueado;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: bloqueado ? null : onTap,
    child: SizedBox(
      height: densidade.isCompacta ? 44 : 52,
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
            if (status case final b.DemandaStatus valor)
              StatusDot(color: statusColor(valor)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                switch (prioridade) {
                  b.Prioridade.urgente => 'Urgente',
                  b.Prioridade.alta => 'Alta',
                  b.Prioridade.media => 'Média',
                  b.Prioridade.baixa => 'Baixa',
                  null => statusLabel(status!),
                },
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
                color: AppTokens.of(context).metadata,
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
          style: TextStyle(
            fontSize: 12,
            color: AppTokens.of(context).secondaryLabel,
          ),
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
                  color: AppTokens.of(context).secondaryLabel,
                ),
              ),
            ],
          ),
      ],
    ),
  );
}

class DemandTableHeader extends StatelessWidget {
  const DemandTableHeader({
    super.key,
    this.densidade = DensidadeDemanda.normal,
    this.colunas = ColunaDemanda.padrao,
    this.ordem,
    this.onOrdenar,
    this.modoSelecao = false,
    this.onAlternarSelecao,
  });

  final DensidadeDemanda densidade;
  final Set<ColunaDemanda> colunas;
  final OrdemListaDemanda? ordem;
  final ValueChanged<ColunaDemanda>? onOrdenar;
  final bool modoSelecao;
  final VoidCallback? onAlternarSelecao;

  Widget _controleSelecao() => SizedBox(
    width: 40,
    child: IconButton(
      key: const ValueKey('alternar-modo-selecao-lista'),
      tooltip: modoSelecao
          ? 'Encerrar seleção múltipla'
          : 'Ativar seleção múltipla',
      onPressed: onAlternarSelecao,
      icon: Icon(
        modoSelecao ? Symbols.checklist_rtl_rounded : Symbols.checklist_rounded,
      ),
    ),
  );

  Widget? _rotulo(ColunaDemanda coluna, {String? texto, bool direita = false}) {
    if (!colunas.contains(coluna)) return null;
    final selecionada = ordem?.coluna == coluna;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: direita
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            texto ?? coluna.rotulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (selecionada)
          Icon(
            ordem!.crescente ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
          ),
      ],
    );
    if (!coluna.ordenavel || onOrdenar == null) return child;
    final direcao = selecionada
        ? (ordem!.crescente ? 'crescente' : 'decrescente')
        : null;
    return Tooltip(
      message: direcao == null
          ? 'Ordenar por ${coluna.rotulo}'
          : 'Ordenar por ${coluna.rotulo} ($direcao)',
      child: Semantics(
        selected: selecionada,
        child: InkWell(
          key: ValueKey('ordenar-lista-${coluna.name}'),
          onTap: () => onOrdenar!(coluna),
          child: SizedBox(
            height: 36,
            child: Align(
              alignment: direita ? Alignment.centerRight : Alignment.centerLeft,
              widthFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _rotulosEmFaixa(Iterable<ColunaDemanda> candidatas) => Wrap(
    spacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final coluna in candidatas.where(colunas.contains)) _rotulo(coluna)!,
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final compacta = densidade.isCompacta;
      final larguraTela = MediaQuery.sizeOf(context).width;
      final estreito = compacta
          ? box.maxWidth < 680
          : larguraTela < 600 || box.maxWidth < 560;
      if (estreito && onOrdenar == null) return const SizedBox.shrink();
      final desktop = box.maxWidth >= 960;
      final extrasNaLinha = compacta ? box.maxWidth >= 900 : desktop;
      final extras = [ColunaDemanda.criadoEm, ColunaDemanda.tipo];
      final estimado = _rotulo(
        ColunaDemanda.estimado,
        texto: 'Est.',
        direita: true,
      );
      final executado = _rotulo(
        ColunaDemanda.executado,
        texto: 'Real',
        direita: true,
      );
      Widget combinado() => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (executado != null) Flexible(child: executado),
          if (executado != null && estimado != null) const Text(' / '),
          if (estimado != null) Flexible(child: estimado),
        ],
      );
      final horasVisiveis = estimado != null || executado != null;
      final status = _rotulo(ColunaDemanda.status);
      final sprint = _rotulo(ColunaDemanda.sprint);
      final prioridade = _rotulo(ColunaDemanda.prioridade);
      final id = _rotulo(ColunaDemanda.id);
      final demanda = _rotulo(ColunaDemanda.demanda)!;
      return ColoredBox(
        color: AppTokens.of(context).bg,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: AppTokens.of(context).secondaryLabel,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (estreito)
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: (box.maxWidth < 1024 ? 44 : 28) + 40,
                        child: Row(
                          children: [
                            SizedBox(width: box.maxWidth < 1024 ? 44 : 28),
                            _controleSelecao(),
                          ],
                        ),
                      ),
                      ...ColunaDemanda.values
                          .where(colunas.contains)
                          .map((coluna) => _rotulo(coluna)!),
                    ],
                  )
                else
                  SizedBox(
                    height: 36,
                    child: compacta
                        ? _CompactColumns(
                            chevron: const SizedBox(),
                            selection: _controleSelecao(),
                            id: id,
                            title: demanda,
                            priority: prioridade,
                            estimate: estimado,
                            real: larguraTela >= 1100
                                ? executado
                                : (horasVisiveis ? combinado() : null),
                            sprint: sprint,
                            status: status,
                            criadoEm: extrasNaLinha
                                ? _rotulo(
                                    ColunaDemanda.criadoEm,
                                    texto: 'Criação',
                                  )
                                : null,
                            tipo: extrasNaLinha
                                ? _rotulo(ColunaDemanda.tipo)
                                : null,
                            actions: const SizedBox(),
                          )
                        : Row(
                            children: [
                              const SizedBox(width: 28),
                              _controleSelecao(),
                              if (id != null) SizedBox(width: 44, child: id),
                              Expanded(child: demanda),
                              if (prioridade != null)
                                SizedBox(
                                  width: desktop ? 100 : 76,
                                  child: prioridade,
                                ),
                              if (desktop) ...[
                                if (sprint != null)
                                  SizedBox(width: 84, child: sprint),
                                if (estimado != null)
                                  SizedBox(width: 64, child: estimado),
                                if (estimado != null && executado != null)
                                  const SizedBox(width: 12),
                                if (executado != null)
                                  SizedBox(width: 112, child: executado),
                              ] else if (horasVisiveis)
                                SizedBox(width: 108, child: combinado()),
                              if (status != null) ...[
                                const SizedBox(width: 12),
                                SizedBox(width: 136, child: status),
                              ],
                              if (extrasNaLinha)
                                for (final coluna in extras.where(
                                  colunas.contains,
                                ))
                                  SizedBox(
                                    width: _larguraExtra(coluna),
                                    child: _rotulo(
                                      coluna,
                                      texto: coluna == ColunaDemanda.criadoEm
                                          ? 'Criação'
                                          : null,
                                    ),
                                  ),
                              const SizedBox(width: 32),
                            ],
                          ),
                  ),
                if (!estreito && !extrasNaLinha && extras.any(colunas.contains))
                  _rotulosEmFaixa(extras),
              ],
            ),
          ),
        ),
      );
    },
  );
}

double _larguraExtra(ColunaDemanda coluna) =>
    coluna == ColunaDemanda.criadoEm ? 84 : 96;

class DemandRow extends StatelessWidget {
  const DemandRow({
    super.key,
    this.densidade = DensidadeDemanda.normal,
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
    this.mostrarMedidor = true,
    this.colunas = ColunaDemanda.padrao,
    this.tipo,
    this.criadoEm,
    this.selecaoEmLote = false,
    this.selection,
  });
  final DensidadeDemanda densidade;
  final int? id;
  final String title;
  final b.Prioridade priority;
  final int hours, estimate;
  final b.DemandaStatus status;
  final Widget actions, chevron;
  final VoidCallback? onTap;
  final Widget? sprint;
  final bool mostrarMedidor;
  final Set<ColunaDemanda> colunas;
  final String? tipo;
  final DateTime? criadoEm;
  final bool selecaoEmLote;
  final Widget? selection;

  bool _visivel(ColunaDemanda coluna) => colunas.contains(coluna);
  bool get _mostraHoras =>
      _visivel(ColunaDemanda.executado) || _visivel(ColunaDemanda.estimado);
  Widget? get _sprintVisivel => _visivel(ColunaDemanda.sprint) ? sprint : null;

  Widget _horas({required bool separarEstimativa, bool compacta = false}) {
    final real = _visivel(ColunaDemanda.executado);
    return HoursLabel(
      minutes: real ? hours : estimate,
      estimate: real && !separarEstimativa && _visivel(ColunaDemanda.estimado)
          ? estimate
          : null,
      compact: compacta,
    );
  }

  List<Widget> _metadadosExtras({required bool emColunas}) => [
    if (_visivel(ColunaDemanda.criadoEm))
      _metadado(ColunaDemanda.criadoEm, _dataCriacao, emColunas),
    if (_visivel(ColunaDemanda.tipo))
      _metadado(ColunaDemanda.tipo, tipo ?? '—', emColunas),
  ];

  String get _dataCriacao {
    final local = criadoEm?.toLocal();
    if (local == null) return '—';
    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    return '$dia/$mes/${local.year}';
  }

  Widget _metadado(
    ColunaDemanda coluna,
    String valor,
    bool emColunas, {
    bool larguraFixa = true,
  }) {
    final texto = Text(
      emColunas ? valor : '${coluna.rotulo}: $valor',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12),
    );
    return emColunas && larguraFixa
        ? SizedBox(width: _larguraExtra(coluna), child: texto)
        : texto;
  }

  Widget _extrasEmpilhados() => Wrap(
    spacing: 12,
    runSpacing: 2,
    children: _metadadosExtras(emColunas: false),
  );

  Widget _medidor({double width = 44}) =>
      !_visivel(ColunaDemanda.executado) || !_visivel(ColunaDemanda.estimado)
      ? const SizedBox.shrink()
      : mostrarMedidor
      ? HoursMeter(real: hours, estimate: estimate, width: width)
      : estimate > 0
      ? SizedBox(width: width, height: 3)
      : const SizedBox.shrink();
  Widget _id(BuildContext context) => Text(
    '#${id ?? '–'}',
    maxLines: 1,
    style: TextStyle(
      fontFamily: 'Roboto Mono',
      fontSize: 12,
      color: AppTokens.of(context).metadata,
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
        maxLines: densidade.isCompacta ? 2 : 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: status == b.DemandaStatus.concluida
              ? AppTokens.of(context).secondaryLabel
              : AppTokens.of(context).text,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => densidade.isCompacta
      ? _CompactDemandRow(row: this)
      : LayoutBuilder(
          builder: (context, box) {
            final mobile =
                MediaQuery.sizeOf(context).width < 600 || box.maxWidth < 560;
            final desktop = box.maxWidth >= 960;
            final t = AppTokens.of(context);
            final hoursWidget = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _horas(separarEstimativa: desktop),
                SizedBox(height: densidade.isCompacta ? 4 : 8),
                _medidor(),
              ],
            );
            return HoverRegion(
              focusBorderRadius: BorderRadius.zero,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  hoverColor: t.hover,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: mobile
                          ? (densidade.isCompacta ? 4 : 12)
                          : (densidade.isCompacta ? 0 : 8),
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
                                    width:
                                        MediaQuery.sizeOf(context).width < 1024
                                        ? 44
                                        : 28,
                                    child: chevron,
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: selection ?? const SizedBox.shrink(),
                                  ),
                                  if (_visivel(ColunaDemanda.id)) ...[
                                    _id(context),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(child: _title(context)),
                                  SizedBox(width: 44, child: actions),
                                ],
                              ),
                              if (_visivel(ColunaDemanda.prioridade) ||
                                  _mostraHoras ||
                                  _visivel(ColunaDemanda.status)) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (_visivel(ColunaDemanda.prioridade)) ...[
                                      PriorityTag(priority: priority),
                                      const SizedBox(width: 8),
                                    ],
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: _mostraHoras
                                            ? _horas(
                                                separarEstimativa: false,
                                                compacta: true,
                                              )
                                            : null,
                                      ),
                                    ),
                                    if (box.maxWidth >= 400 &&
                                        _mostraHoras) ...[
                                      const SizedBox(width: 4),
                                      _medidor(width: 32),
                                    ],
                                    if (_visivel(ColunaDemanda.status)) ...[
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 112,
                                        child: statusWidget(context),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                              if (_sprintVisivel != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _sprintVisivel,
                                  ),
                                ),
                              _extrasEmpilhados(),
                            ],
                          )
                        : ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: densidade.isCompacta ? 40 : 56,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      width:
                                          MediaQuery.sizeOf(context).width <
                                              1024
                                          ? 44
                                          : 28,
                                      child: chevron,
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child:
                                          selection ?? const SizedBox.shrink(),
                                    ),
                                    if (_visivel(ColunaDemanda.id))
                                      SizedBox(width: 44, child: _id(context)),
                                    Expanded(child: _title(context)),
                                    if (_visivel(ColunaDemanda.prioridade))
                                      SizedBox(
                                        width: desktop ? 100 : 76,
                                        child: PriorityTag(priority: priority),
                                      ),
                                    if (desktop &&
                                        _visivel(ColunaDemanda.estimado)) ...[
                                      SizedBox(
                                        width: 64,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: HoursLabel(minutes: estimate),
                                        ),
                                      ),
                                      if (_visivel(ColunaDemanda.executado))
                                        const SizedBox(width: 12),
                                    ],
                                    if (desktop
                                        ? _visivel(ColunaDemanda.executado)
                                        : _mostraHoras)
                                      SizedBox(
                                        width: desktop ? 112 : 108,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: hoursWidget,
                                        ),
                                      ),
                                    if (_visivel(ColunaDemanda.status)) ...[
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 136,
                                        child: statusWidget(context),
                                      ),
                                    ],
                                    if (desktop)
                                      ..._metadadosExtras(emColunas: true),
                                    SizedBox(
                                      width:
                                          MediaQuery.sizeOf(context).width <
                                              1024
                                          ? 44
                                          : 32,
                                      child: actions,
                                    ),
                                  ],
                                ),
                                if (_sprintVisivel != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 72,
                                      bottom: 4,
                                    ),
                                    child: _sprintVisivel,
                                  ),
                                if (!desktop) _extrasEmpilhados(),
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
    this.densidade = DensidadeDemanda.normal,
    required this.demand,
    required this.real,
    required this.actions,
    required this.chevron,
    this.sprint,
    this.dragHandle,
    this.onTap,
    this.highlighted = false,
  });
  final DensidadeDemanda densidade;
  final b.Demanda demand;
  final int real;
  final Widget actions, chevron;
  final Widget? sprint, dragHandle;
  final VoidCallback? onTap;
  final bool highlighted;
  @override
  Widget build(BuildContext context) {
    if (densidade.isCompacta) return _CompactDemandCard(card: this);
    final t = AppTokens.of(context);
    return HoverRegion(
      focusBorderRadius: BorderRadius.circular(AppTokens.cardRadius),
      child: Material(
        color: highlighted && t.darkContrast ? t.cardHover : t.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: highlighted ? AppTokens.accent : t.surfaceBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('abrir-painel-demanda-${demand.id}'),
          onTap: onTap,
          hoverColor: t.cardHover,
          child: Padding(
            padding: EdgeInsets.all(densidade.isCompacta ? 8 : 16),
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
                        color: t.metadata,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        demand.titulo,
                        maxLines: densidade.isCompacta ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: demand.status == b.DemandaStatus.concluida
                              ? t.secondaryLabel
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
                SizedBox(height: densidade.espacamentoEntreCampos),
                Row(
                  children: [
                    PriorityTag(priority: demand.prioridade),
                    const SizedBox(width: 8),
                    const Spacer(),
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
                          SizedBox(height: densidade.isCompacta ? 4 : 8),
                          HoursMeter(
                            real: real,
                            estimate: demand.tempoEstimadoMinutos,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (sprint != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: sprint,
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
    this.densidade = DensidadeDemanda.normal,
    required this.status,
    required this.count,
    required this.child,
    this.collapsed = false,
    this.target = false,
  });
  final DensidadeDemanda densidade;
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
          color: target
              ? (t.darkContrast ? t.cardHover : t.accentSoft)
              : t.surface,
          border: Border.all(
            color: target ? AppTokens.accent : t.surfaceBorder,
          ),
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
                                style: TextStyle(
                                  fontSize: 12,
                                  color: t.metadata,
                                ),
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
                  GroupHeader(
                    status: status,
                    count: count,
                    densidade: densidade,
                  ),
                  Divider(height: 1, color: t.border),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(densidade.isCompacta ? 8 : 12),
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
  const HoverRegion({super.key, required this.child, this.focusBorderRadius});
  final Widget child;
  final BorderRadius? focusBorderRadius;
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
        child:
            AppTokens.of(context).darkContrast &&
                widget.focusBorderRadius != null
            ? DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: widget.focusBorderRadius,
                  border: Border.all(
                    color: focused ? AppTokens.accent : Colors.transparent,
                  ),
                ),
                child: widget.child,
              )
            : widget.child,
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
