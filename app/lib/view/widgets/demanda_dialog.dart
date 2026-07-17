import 'package:flutter/material.dart';

import '../../model/demanda.dart';

class DemandaFormData {
  const DemandaFormData({
    required this.titulo,
    required this.estimado,
    required this.status,
  });
  final String titulo;
  final Duration estimado;
  final DemandaStatus status;
}

class DemandaDialog extends StatefulWidget {
  const DemandaDialog({super.key, this.isFilha = false});
  final bool isFilha;

  @override
  State<DemandaDialog> createState() => _DemandaDialogState();
}

class _DemandaDialogState extends State<DemandaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _estimado = TextEditingController(text: '60');
  DemandaStatus _status = DemandaStatus.pendente;

  @override
  void dispose() {
    _titulo.dispose();
    _estimado.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.isFilha ? 'Nova demanda filha' : 'Nova demanda'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titulo,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Título'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Informe um título'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _estimado,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tempo estimado (minutos)',
              ),
              validator: (value) {
                final number = int.tryParse(value ?? '');
                return number == null || number <= 0
                    ? 'Informe um tempo maior que zero'
                    : null;
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<DemandaStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: DemandaStatus.values
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => _status = value ?? _status,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(
        onPressed: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.pop(
            context,
            DemandaFormData(
              titulo: _titulo.text.trim(),
              estimado: Duration(minutes: int.parse(_estimado.text)),
              status: _status,
            ),
          );
        },
        child: const Text('Salvar'),
      ),
    ],
  );
}
