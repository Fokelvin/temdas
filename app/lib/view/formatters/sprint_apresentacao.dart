import 'package:flutter/services.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

String complementoSprint(String nome) => nome
    .trim()
    .replaceFirst(RegExp(r'^(?:sprint(?:\s+|$))+', caseSensitive: false), '')
    .trim();
String nomeSprint(String nome) => 'Sprint ${complementoSprint(nome)}'.trim();
bool sprintAberta(backend.Sprint s) =>
    s.status == backend.SprintStatus.ativa ||
    s.status == backend.SprintStatus.planejada;
String estadoSprint(backend.Sprint s) => switch (s.status) {
  backend.SprintStatus.ativa => 'Ativa',
  backend.SprintStatus.planejada => 'Planejada',
  backend.SprintStatus.concluida => 'Finalizada',
  backend.SprintStatus.cancelada => 'Cancelada',
};
bool periodosSprintSobrepostos(backend.Sprint a, backend.Sprint b) =>
    !a.dataInicio.isAfter(b.dataFim) && !a.dataFim.isBefore(b.dataInicio);
List<backend.Sprint> ordenarSprints(Iterable<backend.Sprint> sprints) {
  int grupo(backend.Sprint s) => s.status == backend.SprintStatus.ativa
      ? 0
      : s.status == backend.SprintStatus.planejada
      ? 1
      : 2;
  return sprints.toList()..sort((a, b) {
    final prioridade = grupo(a).compareTo(grupo(b));
    if (prioridade != 0) return prioridade;
    final data = grupo(a) == 1
        ? a.dataInicio.compareTo(b.dataInicio)
        : b.dataInicio.compareTo(a.dataInicio);
    return data != 0 ? data : (b.id ?? 0).compareTo(a.id ?? 0);
  });
}

class ComplementoSprintFormatter extends TextInputFormatter {
  const ComplementoSprintFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    final texto = newValue.text.trimLeft().replaceFirst(
      RegExp(r'^(?:sprint(?:\s+|$))+', caseSensitive: false),
      '',
    );
    if (texto == newValue.text) return newValue;
    final removidos = newValue.text.length - texto.length;
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(
        offset: (newValue.selection.extentOffset - removidos).clamp(
          0,
          texto.length,
        ),
      ),
    );
  }
}
