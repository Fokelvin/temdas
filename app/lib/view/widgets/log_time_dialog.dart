import 'package:flutter/material.dart';

class LogTimeFormData {
  const LogTimeFormData({
    required this.data,
    required this.hora,
    required this.duracao,
  });
  final DateTime data;
  final TimeOfDay hora;
  final Duration duracao;
}

class LogTimeDialog extends StatefulWidget {
  const LogTimeDialog({
    super.key,
    required this.demandaTitulo,
    required this.dataInicial,
  });
  final String demandaTitulo;
  final DateTime dataInicial;

  @override
  State<LogTimeDialog> createState() => _LogTimeDialogState();
}

class _LogTimeDialogState extends State<LogTimeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _duracao = TextEditingController(text: '30');
  late DateTime _data = widget.dataInicial;
  TimeOfDay _hora = TimeOfDay.now();

  @override
  void dispose() {
    _duracao.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Adicionar log time'),
    content: SizedBox(
      width: 460,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.demandaTitulo,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text('${_data.day}/${_data.month}/${_data.year}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_hora.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _duracao,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Tempo trabalhado (minutos)',
              ),
              validator: (value) {
                final number = int.tryParse(value ?? '');
                return number == null || number <= 0
                    ? 'Informe um tempo maior que zero'
                    : null;
              },
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
      FilledButton(onPressed: _submit, child: const Text('Adicionar')),
    ],
  );

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null) setState(() => _data = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _hora);
    if (value != null) setState(() => _hora = value);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      LogTimeFormData(
        data: _data,
        hora: _hora,
        duracao: Duration(minutes: int.parse(_duracao.text)),
      ),
    );
  }
}
