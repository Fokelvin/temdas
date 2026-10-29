import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

/// Converte somente datas tipadas. O conteúdo livre permanece byte a byte.
String formatarHorarioOriginal(DateTime valor) {
  final local = valor.toLocal();
  String dois(int n) => n.toString().padLeft(2, '0');
  final offset = local.timeZoneOffset.inMinutes;
  final fuso =
      'UTC${offset < 0 ? '-' : '+'}${dois(offset.abs() ~/ 60)}:${dois(offset.abs() % 60)}';
  return '${dois(local.day)}/${dois(local.month)}/${local.year} às ${dois(local.hour)}:${dois(local.minute)} ($fuso)';
}

class RegistroTempoObservacoes extends StatelessWidget {
  const RegistroTempoObservacoes({
    super.key,
    this.texto,
    this.originais,
    this.mostrarTextos = true,
  });
  final String? texto;
  final List<backend.RegistroTempoObservacao>? originais;
  final bool mostrarTextos;

  @override
  Widget build(BuildContext context) {
    final trechos = originais;
    if (trechos == null || trechos.isEmpty) {
      return mostrarTextos && (texto?.isNotEmpty ?? false)
          ? SelectableText(texto!)
          : const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < trechos.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Horário original ${i + 1}: ${formatarHorarioOriginal(trechos[i].inicioEm)} — ${formatarHorarioOriginal(trechos[i].fimEm)}',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                if (mostrarTextos) SelectableText(trechos[i].texto),
              ],
            ),
          ),
      ],
    );
  }
}
