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
    this.acoesHabilitadas = true,
    this.emProcessamento = false,
    this.onCriarFilha,
    this.onLancarTempo,
    this.onMostrarTudo,
    this.expansionController,
    this.dragHandle,
    this.destacado = false,
    this.densidade = DensidadeDemanda.normal,
  });

  final backend.Demanda demanda;
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
  final ExpansibleController? expansionController;
  final Widget? dragHandle;
  final bool destacado;
  final DensidadeDemanda densidade;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SelectionArea(
      child: Card(
        key: ValueKey('demanda-card-${demanda.id}'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: destacado ? colors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: ListTileTheme.merge(
          minVerticalPadding: densidade.paddingVerticalCabecalho,
          horizontalTitleGap: densidade.espacamentoChevron,
          child: ExpansionTile(
            controller: expansionController,
            leading: dragHandle,
            tilePadding: densidade.paddingCabecalho,
            minTileHeight: densidade.alturaMinimaCabecalho,
            title: densidade.isCompacta
                ? _cabecalhoCompacto(context)
                : _cabecalhoNormal(context),
            childrenPadding: densidade.paddingConteudo,
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _menuStatus(context)),
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
                  _menuAcoes(context),
                ],
              ),
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
              _Campo(
                titulo: 'Descrição',
                valor: demanda.descricao ?? 'Não informada',
                densidade: densidade,
              ),
              _Campo(
                titulo: 'Sprint',
                valor: demanda.sprint ?? 'Não informada',
                densidade: densidade,
              ),
              SizedBox(height: densidade.espacamentoEntreSecoes),
              TempoComparacao(
                estimadoMinutos: demanda.tempoEstimadoMinutos,
                executadoMinutos: tempoExecutadoTotalMinutos,
              ),
              _Campo(
                titulo: 'Observações',
                valor: demanda.observacoes ?? 'Não informadas',
                densidade: densidade,
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
        Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: prioridade.fundo,
                borderRadius: BorderRadius.circular(TemdasTokens.controlRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                  _prioridadeLabel(demanda.prioridade),
                  style: text.labelMedium?.copyWith(color: prioridade.cor),
                ),
              ),
            ),
            const SizedBox(width: TemdasTokens.smallGap),
            Expanded(
              child: LayoutBuilder(
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
                    message: truncado
                        ? formatarIdentificacaoDemanda(demanda)
                        : '',
                    child: Text(
                      formatarIdentificacaoDemanda(demanda),
                      style: text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        DefaultTextStyle.merge(
          style: text.bodySmall,
          child: Wrap(
            spacing: 8,
            runSpacing: 2,
            children: [
              Text('Est. ${_formatarHoras(demanda.tempoEstimadoMinutos)}'),
              Text('Real. ${_formatarHoras(tempoExecutadoTotalMinutos)}'),
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
          icon: const Icon(Icons.account_tree_outlined),
          label: const Text('Criar filha'),
        ),
      if (onLancarTempo != null)
        TextButton.icon(
          key: ValueKey('lancar-tempo-${demanda.id}'),
          onPressed: acoesHabilitadas ? onLancarTempo : null,
          style: densidade.estiloBotao,
          icon: const Icon(Icons.more_time),
          label: const Text('Lançar tempo'),
        ),
    ];
    if (densidade.isCompacta) {
      return Wrap(spacing: 4, runSpacing: 2, children: botoes);
    }
    return Row(children: [for (final botao in botoes) Expanded(child: botao)]);
  }

  Widget _menuStatus(BuildContext context) {
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
      tooltip: 'Alterar status',
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(cor.withValues(alpha: 0.10), colors.surface),
          border: Border.all(
            color: cor.withValues(alpha: 0.20),
            width: TemdasTokens.borderWidth,
          ),
          borderRadius: BorderRadius.circular(TemdasTokens.controlRadius),
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
    );
  }

  Widget _menuAcoes(BuildContext context) {
    final corDestrutiva = Theme.of(context).colorScheme.error;
    return PopupMenuButton<_AcaoDemanda>(
      key: ValueKey('acoes-demanda-${demanda.id}'),
      tooltip: 'Mais ações da demanda',
      enabled: acoesHabilitadas,
      icon: const Icon(Icons.more_vert),
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ).merge(densidade.estiloBotao),
      onSelected: (acao) {
        switch (acao) {
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
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar'),
          ),
        ),
        if (onMostrarTudo != null)
          PopupMenuItem(
            key: ValueKey('mostrar-tudo-${demanda.id}'),
            value: _AcaoDemanda.mostrarTudo,
            child: const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.open_in_new),
              title: Text('Mostrar tudo'),
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
        const PopupMenuDivider(),
        PopupMenuItem(
          key: ValueKey('excluir-demanda-${demanda.id}'),
          value: _AcaoDemanda.excluir,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: corDestrutiva),
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

enum _AcaoDemanda { editar, mostrarTudo, reabrir, excluir }

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
