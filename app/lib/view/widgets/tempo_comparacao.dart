import 'dart:math' as math;

import 'package:flutter/material.dart';

class TempoComparacao extends StatelessWidget {
  const TempoComparacao({
    super.key,
    required this.estimadoMinutos,
    required this.executadoMinutos,
    this.compacto = false,
  });

  final int estimadoMinutos;
  final int executadoMinutos;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final estimado = math.max(0, estimadoMinutos);
    final executado = math.max(0, executadoMinutos);
    final excedido = executado > estimado;
    final progresso = estimado == 0
        ? (executado == 0 ? 0.0 : 1.0)
        : math.min(1.0, executado / estimado);
    final cor = excedido
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Semantics(
      label:
          'Tempo estimado ${_formatarDuracao(estimado)}, '
          'tempo executado ${_formatarDuracao(executado)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (compacto)
            Text(
              '${_formatarDuracao(executado)} de '
              '${_formatarDuracao(estimado)} executadas',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text('Estimado: ${_formatarDuracao(estimado)}'),
                Text('Executado: ${_formatarDuracao(executado)}'),
                Text(
                  _saldoLabel(estimado: estimado, executado: executado),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: excedido ? cor : null,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progresso,
            color: cor,
            minHeight: compacto ? 4 : 6,
          ),
        ],
      ),
    );
  }
}

String _saldoLabel({required int estimado, required int executado}) {
  final diferenca = estimado - executado;
  if (diferenca > 0) return 'Restam ${_formatarDuracao(diferenca)}';
  if (diferenca < 0) return 'Excedido em ${_formatarDuracao(-diferenca)}';
  return 'Dentro do estimado';
}

String _formatarDuracao(int minutos) {
  if (minutos == 0) return '0 h';
  if (minutos % 60 == 0) return '${minutos ~/ 60} h';
  if (minutos < 60) return '$minutos min';

  final horas = minutos ~/ 60;
  final restantes = minutos % 60;
  return '$horas h $restantes min';
}
