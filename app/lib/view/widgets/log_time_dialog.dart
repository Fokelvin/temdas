import 'package:flutter/material.dart';

class LogTimeFormData {
  const LogTimeFormData({
    required this.data,
    required this.hora,
    required this.duracaoHoras,
  });

  final DateTime data;
  final TimeOfDay hora;
  final double duracaoHoras;
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
  final _duracaoController = TextEditingController(text: '0,5');
  late DateTime _data = DateTime(
    widget.dataInicial.year,
    widget.dataInicial.month,
    widget.dataInicial.day,
  );
  TimeOfDay _hora = TimeOfDay.now();

  @override
  void dispose() {
    _duracaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Lançar tempo'),
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
                    key: const ValueKey('selecionar-data-log-time'),
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_data.day.toString().padLeft(2, '0')}/'
                      '${_data.month.toString().padLeft(2, '0')}/'
                      '${_data.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('selecionar-hora-log-time'),
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_hora.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const ValueKey('log-time-duracao'),
              controller: _duracaoController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Tempo trabalhado (horas)',
                helperText: 'Exemplos: 0,5; 1.25; 2',
              ),
              validator: _validarDuracao,
              onFieldSubmitted: (_) => _submit(),
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
        key: const ValueKey('salvar-log-time'),
        onPressed: _submit,
        child: const Text('Lançar'),
      ),
    ],
  );

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (value != null && mounted) setState(() => _data = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _hora);
    if (value != null && mounted) setState(() => _hora = value);
  }

  String? _validarDuracao(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o tempo trabalhado em horas.';
    }

    final minutos = _minutosExatos(value);
    if (minutos == null) {
      return 'Use uma duração positiva que resulte em minutos inteiros.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final minutos = _minutosExatos(_duracaoController.text)!;
    Navigator.pop(
      context,
      LogTimeFormData(
        data: _data,
        hora: _hora,
        duracaoHoras: minutos / Duration.minutesPerHour,
      ),
    );
  }

  int? _minutosExatos(String value) {
    final texto = value.trim().replaceAll(',', '.');
    if (!RegExp(r'^(?:\d+(?:\.\d*)?|\.\d+)$').hasMatch(texto)) {
      return null;
    }

    final partes = texto.split('.');
    final inteiro = partes.first.isEmpty
        ? BigInt.zero
        : BigInt.parse(partes[0]);
    final fracaoTexto = partes.length == 1 ? '' : partes[1];
    final divisor = BigInt.from(10).pow(fracaoTexto.length);
    final fracao = fracaoTexto.isEmpty
        ? BigInt.zero
        : BigInt.parse(fracaoTexto);
    final numerador = inteiro * divisor + fracao;
    if (numerador <= BigInt.zero) return null;

    final minutosNumerador = numerador * BigInt.from(Duration.minutesPerHour);
    if (minutosNumerador.remainder(divisor) != BigInt.zero) return null;

    final minutos = minutosNumerador ~/ divisor;
    // Ints maiores não são serializados com precisão no Flutter Web.
    if (minutos.bitLength > 53) return null;
    return minutos.toInt();
  }
}
