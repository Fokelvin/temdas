import 'package:flutter/material.dart';

Future<void> mostrarTextoDemandaDialog(
  BuildContext context, {
  required String titulo,
  String? texto,
  bool obrigatorio = false,
  required Future<bool> Function(String) salvar,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _TextoDialog(
    titulo: titulo,
    texto: texto,
    obrigatorio: obrigatorio,
    salvar: salvar,
  ),
);

class _TextoDialog extends StatefulWidget {
  const _TextoDialog({
    required this.titulo,
    this.texto,
    required this.obrigatorio,
    required this.salvar,
  });
  final String titulo;
  final String? texto;
  final bool obrigatorio;
  final Future<bool> Function(String) salvar;
  @override
  State<_TextoDialog> createState() => _TextoDialogState();
}

class _TextoDialogState extends State<_TextoDialog> {
  late final controller = TextEditingController(text: widget.texto);
  final form = GlobalKey<FormState>();
  bool enviando = false;
  String? erro;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (enviando || !form.currentState!.validate()) return;
    setState(() {
      enviando = true;
      erro = null;
    });
    bool sucesso;
    try {
      sucesso = await widget.salvar(controller.text);
    } catch (_) {
      sucesso = false;
    }
    if (!mounted) return;
    if (sucesso) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      enviando = false;
      erro = 'Não foi possível salvar. Tente novamente.';
    });
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !enviando,
    child: AlertDialog(
      scrollable: true,
      title: Text(widget.titulo),
      content: SizedBox(
        width: 520,
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('demanda-texto'),
                controller: controller,
                autofocus: true,
                enabled: !enviando,
                minLines: 4,
                maxLines: 12,
                decoration: const InputDecoration(labelText: 'Conteúdo'),
                validator: (value) =>
                    widget.obrigatorio && (value?.trim().isEmpty ?? true)
                    ? 'Informe o conteúdo.'
                    : null,
              ),
              if (erro != null) Semantics(liveRegion: true, child: Text(erro!)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: enviando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: enviando ? null : salvar,
          child: Text(enviando ? 'Salvando…' : 'Salvar'),
        ),
      ],
    ),
  );
}
