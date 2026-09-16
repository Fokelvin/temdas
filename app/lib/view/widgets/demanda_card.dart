import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

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
    this.acoesHabilitadas = true,
    this.emProcessamento = false,
    this.onCriarFilha,
    this.onLancarTempo,
    this.onMostrarTudo,
  });

  final backend.Demanda demanda;
  final int tempoExecutadoTotalMinutos;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final ValueChanged<backend.DemandaStatus> onAlterarStatus;
  final VoidCallback onConcluir;
  final bool acoesHabilitadas;
  final bool emProcessamento;
  final VoidCallback? onCriarFilha;
  final VoidCallback? onLancarTempo;
  final VoidCallback? onMostrarTudo;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Card(
        key: ValueKey('demanda-card-${demanda.id}'),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(
            demanda.titulo,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${_prioridadeLabel(demanda.prioridade)} · '
            'Est. ${_formatarHoras(demanda.tempoEstimadoMinutos)} · '
            'Real. ${_formatarHoras(tempoExecutadoTotalMinutos)}',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _menuStatus(context)),
                IconButton(
                  key: ValueKey('concluir-demanda-${demanda.id}'),
                  tooltip: 'Concluir demanda',
                  visualDensity: VisualDensity.compact,
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
            _Campo(titulo: 'ID', valor: demanda.id?.toString() ?? '-'),
            if (demanda.demandaPaiId != null)
              _Campo(
                titulo: 'Demanda mãe',
                valor: demanda.demandaPaiId.toString(),
              ),
            _Campo(
              titulo: 'Descrição',
              valor: demanda.descricao ?? 'Não informada',
            ),
            _Campo(titulo: 'Sprint', valor: demanda.sprint ?? 'Não informada'),
            const SizedBox(height: 12),
            TempoComparacao(
              estimadoMinutos: demanda.tempoEstimadoMinutos,
              executadoMinutos: tempoExecutadoTotalMinutos,
            ),
            _Campo(
              titulo: 'Observações',
              valor: demanda.observacoes ?? 'Não informadas',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onCriarFilha != null)
                  Expanded(
                    child: TextButton.icon(
                      key: ValueKey('criar-filha-${demanda.id}'),
                      onPressed: acoesHabilitadas ? onCriarFilha : null,
                      icon: const Icon(Icons.account_tree_outlined),
                      label: const Text('Criar filha'),
                    ),
                  ),
                if (onLancarTempo != null)
                  Expanded(
                    child: TextButton.icon(
                      key: ValueKey('lancar-tempo-${demanda.id}'),
                      onPressed: acoesHabilitadas ? onLancarTempo : null,
                      icon: const Icon(Icons.more_time),
                      label: const Text('Lançar tempo'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuStatus(BuildContext context) {
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
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _statusLabel(demanda.status),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const Icon(Icons.arrow_drop_down, size: 18),
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
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      onSelected: (acao) {
        switch (acao) {
          case _AcaoDemanda.editar:
            onEditar();
          case _AcaoDemanda.mostrarTudo:
            onMostrarTudo?.call();
          case _AcaoDemanda.excluir:
            onExcluir();
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
        const PopupMenuDivider(),
        PopupMenuItem(
          key: ValueKey('excluir-demanda-${demanda.id}'),
          value: _AcaoDemanda.excluir,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: corDestrutiva),
            title: Text('Excluir', style: TextStyle(color: corDestrutiva)),
          ),
        ),
      ],
    );
  }

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

enum _AcaoDemanda { editar, mostrarTudo, excluir }

class _Campo extends StatelessWidget {
  const _Campo({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text('$titulo: $valor'),
    );
  }
}
