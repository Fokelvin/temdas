import '../../ui/components/demand_components.dart';
import '../../ui/theme/tokens.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../theme/app_theme.dart';
import '../../theme/temdas_semantic_colors.dart';
import '../formatters/demanda_identificacao.dart';
import 'densidade_demanda.dart';
import 'tempo_comparacao.dart';

class DemandaCard extends StatelessWidget {
  const DemandaCard({
    super.key,
    required this.demanda,
    required this.tempoExecutadoTotalMinutos,
    required this.onEditar,
    required this.onExcluir,
    required this.onAlterarStatus,
    required this.onConcluir,
    this.onReabrir,
    this.sprintContexto,
    this.acoesHabilitadas = true,
    this.emProcessamento = false,
    this.onCriarFilha,
    this.onLancarTempo,
    this.onMostrarTudo,
    this.apenasAcoes = false,
    this.redesign = false,
    this.emLista = false,
    this.expansionController,
    this.dragHandle,
    this.destacado = false,
    this.densidade = DensidadeDemanda.normal,
  });

  final backend.Demanda demanda;
  final Widget? sprintContexto;
  final int tempoExecutadoTotalMinutos;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final ValueChanged<backend.DemandaStatus> onAlterarStatus;
  final VoidCallback onConcluir;
  final VoidCallback? onReabrir;
  final bool acoesHabilitadas;
  final bool emProcessamento;
  final VoidCallback? onCriarFilha;
  final VoidCallback? onLancarTempo;
  final VoidCallback? onMostrarTudo;
  final bool apenasAcoes;
  final bool redesign;
  final bool emLista;
  final ExpansibleController? expansionController;
  final Widget? dragHandle;
  final bool destacado;
  final DensidadeDemanda densidade;

  @override
  Widget build(BuildContext context) {
    if (apenasAcoes) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _menuStatus(context)),
              IconButton(
                tooltip: 'Concluir demanda',
                onPressed: acoesHabilitadas ? onConcluir : null,
                icon: const Icon(Icons.check),
              ),
              _menuAcoes(context),
            ],
          ),
          _botoesAcoes(),
        ],
      );
    }
    if (redesign) return _redesign(context);
    return LayoutBuilder(
      builder: (context, constraints) =>
          _card(context, statusLargo: constraints.maxWidth >= 650),
    );
  }

  Widget _redesign(BuildContext context) {
    return _RedesignExpansion(
      controller: expansionController,
      builder: (context, controller) {
        final chevron = IconButton(
          key: ValueKey('expandir-demanda-${demanda.id}'),
          tooltip: controller.isExpanded
              ? 'Recolher demanda'
              : 'Expandir demanda',
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width < 1024 ? 44 : 28,
            minHeight: MediaQuery.sizeOf(context).width < 1024 ? 44 : 40,
          ),
          onPressed: controller.toggle,
          icon: AnimatedRotation(
            turns: controller.isExpanded ? .25 : 0,
            duration: AppTokens.motion(context),
            curve: AppTokens.curve,
            child: const Icon(Symbols.chevron_right_rounded, size: 16),
          ),
        );
        final summary = emLista
            ? DemandRow(
                id: demanda.id,
                title: demanda.titulo,
                priority: demanda.prioridade,
                hours: tempoExecutadoTotalMinutos,
                estimate: demanda.tempoEstimadoMinutos,
                status: demanda.status,
                actions: _menuAcoes(context),
                chevron: chevron,
                onTap: onMostrarTudo,
                sprint: sprintContexto,
                statusControl: _menuStatus(context),
              )
            : DemandCard(
                demand: demanda,
                real: tempoExecutadoTotalMinutos,
                actions: _menuAcoes(context),
                chevron: chevron,
                onTap: onMostrarTudo,
                sprint: sprintContexto,
                dragHandle: dragHandle,
                highlighted: destacado,
              );
        return Column(
          key: ValueKey('demanda-card-${demanda.id}'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            summary,
            if (controller.isExpanded)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        if (!emLista) Expanded(child: _menuStatus(context)),
                        IconButton(
                          key: ValueKey('concluir-demanda-${demanda.id}'),
                          tooltip: 'Concluir demanda',
                          onPressed: acoesHabilitadas ? onConcluir : null,
                          icon: emProcessamento
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Symbols.check_rounded),
                        ),
                      ],
                    ),
                    if (demanda.descricao?.isNotEmpty ?? false)
                      Text('Descrição: ${demanda.descricao}'),
                    const SizedBox(height: 8),
                    TempoComparacao(
                      estimadoMinutos: demanda.tempoEstimadoMinutos,
                      executadoMinutos: tempoExecutadoTotalMinutos,
                    ),
                    _botoesAcoes(),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, {required bool statusLargo}) {
    final colors = Theme.of(context).colorScheme;
    final cardShape = Theme.of(context).cardTheme.shape;
    final outlinedShape = cardShape is OutlinedBorder
        ? cardShape
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TemdasTokens.cardRadius),
          );
    return SelectionArea(
      child: Card(
        key: ValueKey('demanda-card-${demanda.id}'),
        shape: destacado
            ? outlinedShape.copyWith(
                side: BorderSide(
                  color: colors.primary,
                  width: TemdasTokens.borderWidth * 2,
                ),
              )
            : null,
        child: ListTileTheme.merge(
          minVerticalPadding: densidade.paddingVerticalCabecalho,
          horizontalTitleGap: densidade.espacamentoChevron,
          child: _DemandaExpansao(
            controller: expansionController,
            onAbrir: onMostrarTudo,
            demandaId: demanda.id,
            leading: dragHandle,
            trailing: emLista
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 48),
                        child: SizedBox(
                          width: statusLargo ? 152 : 48,
                          child: _menuStatus(
                            context,
                            apenasIcone: !statusLargo,
                          ),
                        ),
                      ),
                      SizedBox.square(
                        dimension: 48,
                        child: _menuAcoes(context),
                      ),
                    ],
                  )
                : null,
            tilePadding: densidade.paddingCabecalho,
            minTileHeight: densidade.alturaMinimaCabecalho,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                densidade.isCompacta
                    ? _cabecalhoCompacto(context)
                    : _cabecalhoNormal(context),
                ?sprintContexto,
              ],
            ),
            childrenPadding: densidade.paddingConteudo,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!emLista) Expanded(child: _menuStatus(context)),
                  IconButton(
                    key: ValueKey('concluir-demanda-${demanda.id}'),
                    tooltip: 'Concluir demanda',
                    visualDensity: VisualDensity.compact,
                    style: densidade.estiloBotao,
                    onPressed: acoesHabilitadas ? onConcluir : null,
                    icon: emProcessamento
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                  ),
                  if (!emLista) _menuAcoes(context),
                ],
              ),
              if (!densidade.isCompacta)
                _Campo(
                  titulo: 'ID',
                  valor: demanda.id?.toString() ?? '-',
                  densidade: densidade,
                ),
              if (demanda.demandaPaiId != null)
                _Campo(
                  titulo: 'Demanda mãe',
                  valor: demanda.demandaPaiId.toString(),
                  densidade: densidade,
                ),
              if (!densidade.isCompacta ||
                  (demanda.descricao?.trim().isNotEmpty ?? false))
                _Campo(
                  titulo: 'Descrição',
                  valor: demanda.descricao ?? 'Não informada',
                  densidade: densidade,
                ),
              SizedBox(height: densidade.espacamentoEntreSecoes),
              TempoComparacao(
                estimadoMinutos: demanda.tempoEstimadoMinutos,
                executadoMinutos: tempoExecutadoTotalMinutos,
              ),
              SizedBox(height: densidade.espacamentoEntreSecoes),
              _botoesAcoes(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalhoNormal(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formatarIdentificacaoDemanda(demanda), style: text.titleSmall),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: _prioridadeLabel(demanda.prioridade),
                style: text.labelMedium?.copyWith(
                  color: _coresPrioridade(context).cor,
                ),
              ),
              TextSpan(
                text:
                    ' · Est. ${_formatarHoras(demanda.tempoEstimadoMinutos)} · '
                    'Real. ${_formatarHoras(tempoExecutadoTotalMinutos)}',
              ),
            ],
          ),
          style: text.bodySmall,
        ),
      ],
    );
  }

  Widget _cabecalhoCompacto(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final prioridade = _coresPrioridade(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final painter = TextPainter(
              text: TextSpan(
                text: formatarIdentificacaoDemanda(demanda),
                style: text.titleSmall,
              ),
              maxLines: 1,
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: constraints.maxWidth);
            final truncado = painter.didExceedMaxLines;
            painter.dispose();
            return Tooltip(
              message: truncado ? formatarIdentificacaoDemanda(demanda) : '',
              child: Text(
                formatarIdentificacaoDemanda(demanda),
                style: text.titleSmall,
                maxLines: emLista ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
        const SizedBox(height: 2),
        DefaultTextStyle.merge(
          style: text.bodySmall,
          child: Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(
                _prioridadeLabel(demanda.prioridade),
                style: text.labelMedium?.copyWith(color: prioridade.cor),
              ),
              Text(
                'Est. ${_formatarHoras(demanda.tempoEstimadoMinutos)} · Real. ${_formatarHoras(tempoExecutadoTotalMinutos)}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  ({Color cor, Color fundo}) _coresPrioridade(BuildContext context) {
    final semantic = TemdasSemanticColors.of(context);
    return switch (demanda.prioridade) {
      backend.Prioridade.baixa => (
        cor: semantic.prioridadeBaixa,
        fundo: semantic.prioridadeBaixaContainer,
      ),
      backend.Prioridade.media => (
        cor: semantic.prioridadeMedia,
        fundo: semantic.prioridadeMediaContainer,
      ),
      backend.Prioridade.alta || backend.Prioridade.urgente => (
        cor: semantic.prioridadeAlta,
        fundo: semantic.prioridadeAltaContainer,
      ),
    };
  }

  Widget _botoesAcoes() {
    final botoes = [
      if (onCriarFilha != null)
        TextButton.icon(
          key: ValueKey('criar-filha-${demanda.id}'),
          onPressed: acoesHabilitadas ? onCriarFilha : null,
          style: densidade.estiloBotao,
          icon: Icon(
            redesign
                ? Symbols.account_tree_rounded
                : Icons.account_tree_outlined,
          ),
          label: const Text('Criar filha'),
        ),
      if (onLancarTempo != null)
        TextButton.icon(
          key: ValueKey('lancar-tempo-${demanda.id}'),
          onPressed: acoesHabilitadas ? onLancarTempo : null,
          style: densidade.estiloBotao,
          icon: Icon(redesign ? Symbols.more_time_rounded : Icons.more_time),
          label: const Text('Lançar tempo'),
        ),
    ];
    if (densidade.isCompacta) {
      return Wrap(spacing: 4, runSpacing: 2, children: botoes);
    }
    return Row(children: [for (final botao in botoes) Expanded(child: botao)]);
  }

  Widget _menuStatus(BuildContext context, {bool apenasIcone = false}) {
    final colors = Theme.of(context).colorScheme;
    final semantic = TemdasSemanticColors.of(context);
    final cor = switch (demanda.status) {
      backend.DemandaStatus.aberta => semantic.aberta,
      backend.DemandaStatus.emAndamento => semantic.emAndamento,
      backend.DemandaStatus.pausada => semantic.pausada,
      backend.DemandaStatus.concluida => semantic.concluida,
      backend.DemandaStatus.cancelada => semantic.cancelada,
    };
    return PopupMenuButton<backend.DemandaStatus>(
      key: ValueKey('status-demanda-${demanda.id}'),
      tooltip: apenasIcone
          ? 'Alterar status: ${_statusLabel(demanda.status)}'
          : 'Alterar status',
      enabled: acoesHabilitadas,
      initialValue: demanda.status,
      onSelected: onAlterarStatus,
      itemBuilder: (_) => [
        for (final status in backend.DemandaStatus.values)
          CheckedPopupMenuItem(
            key: ValueKey('status-opcao-${status.name}-${demanda.id}'),
            value: status,
            checked: status == demanda.status,
            child: Text(_statusLabel(status)),
          ),
      ],
      child: redesign
          ? ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).width < 1024 ? 44 : 32,
              ),
              child: Center(child: StatusPill(status: demanda.status)),
            )
          : apenasIcone
          ? SizedBox.square(
              dimension: 48,
              child: Center(child: Icon(Icons.circle, size: 14, color: cor)),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    cor.withValues(alpha: 0.10),
                    colors.surface,
                  ),
                  border: Border.all(
                    color: cor.withValues(alpha: 0.20),
                    width: TemdasTokens.borderWidth,
                  ),
                  borderRadius: BorderRadius.circular(
                    TemdasTokens.controlRadius,
                  ),
                ),
                child: Padding(
                  padding: densidade.paddingStatus,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusLabel(demanda.status),
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(color: cor),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, size: 18, color: cor),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _menuAcoes(BuildContext context) {
    final corDestrutiva = Theme.of(context).colorScheme.error;
    final menu = PopupMenuButton<_AcaoDemanda>(
      key: ValueKey('acoes-demanda-${demanda.id}'),
      tooltip: 'Mais ações da demanda',
      enabled: acoesHabilitadas,
      icon: Icon(redesign ? Symbols.more_vert_rounded : Icons.more_vert),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ).merge(densidade.estiloBotao),
      onSelected: (acao) {
        switch (acao) {
          case _AcaoDemanda.concluir:
            onConcluir();
          case _AcaoDemanda.filha:
            onCriarFilha?.call();
          case _AcaoDemanda.tempo:
            onLancarTempo?.call();
          case _AcaoDemanda.editar:
            onEditar();
          case _AcaoDemanda.mostrarTudo:
            onMostrarTudo?.call();
          case _AcaoDemanda.excluir:
            onExcluir();
          case _AcaoDemanda.reabrir:
            onReabrir?.call();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          key: ValueKey('editar-demanda-${demanda.id}'),
          value: _AcaoDemanda.editar,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: const Text('Editar'),
          ),
        ),
        if (onMostrarTudo != null)
          PopupMenuItem(
            key: ValueKey('mostrar-tudo-${demanda.id}'),
            value: _AcaoDemanda.mostrarTudo,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.open_in_new),
              title: const Text('Mostrar tudo'),
            ),
          ),
        if (onReabrir != null && _statusTerminal)
          PopupMenuItem(
            key: ValueKey(
              '${_acaoTerminalLabel.toLowerCase()}-demanda-${demanda.id}',
            ),
            value: _AcaoDemanda.reabrir,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconeAcaoTerminal),
              title: Text(_acaoTerminalLabel),
            ),
          ),
        if (redesign) ...[
          PopupMenuItem(
            value: _AcaoDemanda.concluir,
            enabled: acoesHabilitadas,
            child: const Text('Concluir demanda'),
          ),
          if (onCriarFilha != null)
            PopupMenuItem(
              value: _AcaoDemanda.filha,
              child: const Text('Criar filha'),
            ),
          if (onLancarTempo != null)
            PopupMenuItem(
              value: _AcaoDemanda.tempo,
              child: const Text('Lançar tempo'),
            ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          key: ValueKey('excluir-demanda-${demanda.id}'),
          value: _AcaoDemanda.excluir,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              redesign ? Symbols.delete_rounded : Icons.delete_outline,
              color: corDestrutiva,
            ),
            title: Text(
              'Excluir',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: corDestrutiva),
            ),
          ),
        ),
      ],
    );
    return redesign ? RevealOnHover(child: menu) : menu;
  }

  bool get _statusTerminal =>
      demanda.status == backend.DemandaStatus.concluida ||
      demanda.status == backend.DemandaStatus.cancelada;

  String get _acaoTerminalLabel =>
      demanda.status == backend.DemandaStatus.concluida
      ? 'Reabrir'
      : 'Reativar';

  IconData get _iconeAcaoTerminal =>
      demanda.status == backend.DemandaStatus.concluida
      ? Icons.lock_open_outlined
      : Icons.play_arrow_outlined;

  String _formatarHoras(int minutos) {
    final horas = minutos / 60;
    final valor = horas == horas.truncateToDouble()
        ? horas.toInt().toString()
        : horas.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    return '${valor.replaceAll('.', ',')} h';
  }

  String _statusLabel(backend.DemandaStatus status) {
    return switch (status) {
      backend.DemandaStatus.aberta => 'Aberta',
      backend.DemandaStatus.emAndamento => 'Em andamento',
      backend.DemandaStatus.pausada => 'Pausada',
      backend.DemandaStatus.concluida => 'Concluída',
      backend.DemandaStatus.cancelada => 'Cancelada',
    };
  }

  String _prioridadeLabel(backend.Prioridade prioridade) {
    return switch (prioridade) {
      backend.Prioridade.baixa => 'Baixa',
      backend.Prioridade.media => 'Média',
      backend.Prioridade.alta => 'Alta',
      backend.Prioridade.urgente => 'Urgente',
    };
  }
}

enum _AcaoDemanda {
  editar,
  mostrarTudo,
  reabrir,
  excluir,
  concluir,
  filha,
  tempo,
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.titulo,
    required this.valor,
    required this.densidade,
  });

  final String titulo;
  final String valor;
  final DensidadeDemanda densidade;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: densidade.espacamentoEntreCampos),
      child: Text(
        '$titulo: $valor',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

/// Somente o botão de expansão altera a altura; o corpo abre os detalhes.
class _DemandaExpansao extends StatefulWidget {
  const _DemandaExpansao({
    this.controller,
    this.leading,
    this.trailing,
    this.onAbrir,
    required this.demandaId,
    required this.tilePadding,
    required this.minTileHeight,
    required this.title,
    required this.childrenPadding,
    required this.expandedCrossAxisAlignment,
    required this.children,
  });
  final ExpansibleController? controller;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onAbrir;
  final int? demandaId;
  final EdgeInsetsGeometry tilePadding;
  final double minTileHeight;
  final Widget title;
  final EdgeInsetsGeometry childrenPadding;
  final CrossAxisAlignment expandedCrossAxisAlignment;
  final List<Widget> children;
  @override
  State<_DemandaExpansao> createState() => _DemandaExpansaoState();
}

class _DemandaExpansaoState extends State<_DemandaExpansao> {
  late final ExpansibleController controller =
      widget.controller ?? ExpansibleController();
  bool restaurado = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!restaurado) {
      restaurado = true;
      if (PageStorage.maybeOf(context)?.readState(context) == true) {
        controller.expand();
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ?widget.leading,
            Expanded(
              child: InkWell(
                key: ValueKey('abrir-painel-demanda-${widget.demandaId}'),
                onTap: widget.onAbrir,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: widget.minTileHeight),
                  child: Padding(
                    padding: widget.tilePadding,
                    child: widget.title,
                  ),
                ),
              ),
            ),
            ?widget.trailing,
            IconButton(
              key: ValueKey('expandir-demanda-${widget.demandaId}'),
              tooltip: controller.isExpanded
                  ? 'Recolher demanda'
                  : 'Expandir demanda',
              onPressed: () {
                controller.toggle();
                PageStorage.maybeOf(
                  context,
                )?.writeState(context, controller.isExpanded);
              },
              icon: Icon(
                controller.isExpanded ? Icons.expand_less : Icons.expand_more,
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: controller.isExpanded
              ? InkWell(
                  onTap: widget.onAbrir,
                  child: Padding(
                    padding: widget.childrenPadding,
                    child: Column(
                      crossAxisAlignment: widget.expandedCrossAxisAlignment,
                      children: widget.children,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

class _RedesignExpansion extends StatefulWidget {
  const _RedesignExpansion({this.controller, required this.builder});
  final ExpansibleController? controller;
  final Widget Function(BuildContext, ExpansibleController) builder;
  @override
  State<_RedesignExpansion> createState() => _RedesignExpansionState();
}

class _RedesignExpansionState extends State<_RedesignExpansion> {
  late final ExpansibleController _controller =
      widget.controller ?? ExpansibleController();
  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) => widget.builder(context, _controller),
  );
}
