import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'tempo_comparacao.dart';

class DemandaCard extends StatelessWidget {
  const DemandaCard({
    super.key,
    required this.demanda,
    required this.onEditar,
    required this.onExcluir,
    this.acoesHabilitadas = true,
    this.onCriarFilha,
    this.onLancarTempo,
    this.onMostrarTudo,
  });

  final backend.Demanda demanda;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;
  final bool acoesHabilitadas;
  final VoidCallback? onCriarFilha;
  final VoidCallback? onLancarTempo;
  final VoidCallback? onMostrarTudo;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Card(
        key: ValueKey('demanda-card-${demanda.id}'),
        child: ExpansionTile(
          title: Text(
            demanda.titulo,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${_statusLabel(demanda.status)} • '
            '${_prioridadeLabel(demanda.prioridade)} • '
            '${_formatarHoras(demanda.tempoEstimadoMinutos)} estimadas',
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              executadoMinutos: demanda.tempoExecutadoMinutos,
            ),
            _Campo(
              titulo: 'Observações',
              valor: demanda.observacoes ?? 'Não informadas',
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (onCriarFilha != null)
                  TextButton.icon(
                    key: ValueKey('criar-filha-${demanda.id}'),
                    onPressed: acoesHabilitadas ? onCriarFilha : null,
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('Criar filha'),
                  ),
                if (onLancarTempo != null)
                  TextButton.icon(
                    key: ValueKey('lancar-tempo-${demanda.id}'),
                    onPressed: acoesHabilitadas ? onLancarTempo : null,
                    icon: const Icon(Icons.more_time),
                    label: const Text('Lançar tempo'),
                  ),
                TextButton.icon(
                  key: ValueKey('editar-demanda-${demanda.id}'),
                  onPressed: acoesHabilitadas ? onEditar : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  key: ValueKey('excluir-demanda-${demanda.id}'),
                  onPressed: acoesHabilitadas ? onExcluir : null,
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir'),
                ),
                if (onMostrarTudo != null)
                  TextButton.icon(
                    key: ValueKey('mostrar-tudo-${demanda.id}'),
                    onPressed: acoesHabilitadas ? onMostrarTudo : null,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Mostrar tudo'),
                  ),
              ],
            ),
          ],
        ),
      ),
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
