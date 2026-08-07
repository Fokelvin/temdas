import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

class DemandaCard extends StatelessWidget {
  const DemandaCard({
    super.key,
    required this.demanda,
    this.onMostrarTudo,
  });

  final backend.Demanda demanda;
  final VoidCallback? onMostrarTudo;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: Text(
          demanda.titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${_statusLabel(demanda.status)} • '
          '${_prioridadeLabel(demanda.prioridade)} • '
          '${demanda.tempoEstimadoMinutos} min',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Campo(
            titulo: 'ID',
            valor: demanda.id?.toString() ?? '-',
          ),
          _Campo(
            titulo: 'Descrição',
            valor: demanda.descricao ?? 'Não informada',
          ),
          _Campo(
            titulo: 'Sprint',
            valor: demanda.sprint ?? 'Não informada',
          ),
          _Campo(
            titulo: 'Tempo estimado',
            valor: '${demanda.tempoEstimadoMinutos} minutos',
          ),
          _Campo(
            titulo: 'Tempo executado',
            valor: '${demanda.tempoExecutadoMinutos} minutos',
          ),
          _Campo(
            titulo: 'Observações',
            valor: demanda.observacoes ?? 'Não informadas',
          ),
          if (onMostrarTudo != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onMostrarTudo,
                child: const Text('Mostrar tudo'),
              ),
            ),
          ],
        ],
      ),
    );
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
  const _Campo({
    required this.titulo,
    required this.valor,
  });

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
