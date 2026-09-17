import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../view_model/log_time_form_data.dart';
import '../demanda_detalhe_page.dart';

export '../../view_model/log_time_form_data.dart';

class LogTimeDialog extends StatefulWidget {
  const LogTimeDialog({
    super.key,
    required this.demandaTitulo,
    required this.dataInicial,
    this.demandaId,
    this.onSalvar,
  }) : horaInicial = null,
       duracaoInicialMinutos = 30,
       edicao = false;

  const LogTimeDialog.editar({
    super.key,
    required this.demandaTitulo,
    required this.dataInicial,
    required TimeOfDay this.horaInicial,
    required this.duracaoInicialMinutos,
    required Future<String?> Function(LogTimeFormData) this.onSalvar,
    this.demandaId,
  }) : edicao = true;

  final String demandaTitulo;
  final int? demandaId;
  final DateTime dataInicial;
  final TimeOfDay? horaInicial;
  final int duracaoInicialMinutos;
  final bool edicao;

  /// Retorna uma mensagem em caso de falha, ou null após salvar com sucesso.
  final Future<String?> Function(LogTimeFormData)? onSalvar;

  @override
  State<LogTimeDialog> createState() => _LogTimeDialogState();
}

class _LogTimeDialogState extends State<LogTimeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _horaInicio;
  late final TextEditingController _minutoInicio;
  late final TextEditingController _horaFim;
  late final TextEditingController _minutoFim;
  late DateTime _data;
  bool _intervaloOriginalMultidia = false;
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _data = DateTime(
      widget.dataInicial.year,
      widget.dataInicial.month,
      widget.dataInicial.day,
    );
    final inicio = widget.horaInicial ?? TimeOfDay.now();
    final minutosFim =
        inicio.hour * Duration.minutesPerHour +
        inicio.minute +
        widget.duracaoInicialMinutos;
    _horaInicio = _controller(inicio.hour);
    _minutoInicio = _controller(inicio.minute);
    _horaFim = _controller((minutosFim ~/ Duration.minutesPerHour) % 24);
    _minutoFim = _controller(minutosFim % Duration.minutesPerHour);
    // Não encurta silenciosamente um registro antigo que ultrapassa um dia.
    _intervaloOriginalMultidia = widget.edicao && minutosFim >= 24 * 60;
  }

  TextEditingController _controller(int valor) =>
      TextEditingController(text: valor.toString().padLeft(2, '0'));

  @override
  void dispose() {
    _horaInicio.dispose();
    _minutoInicio.dispose();
    _horaFim.dispose();
    _minutoFim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_enviando,
    child: AlertDialog(
      scrollable: true,
      title: Text(widget.edicao ? 'Editar lançamento' : 'Lançar tempo'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Demanda'),
              TextButton.icon(
                key: const ValueKey('detalhes-demanda-log-time'),
                onPressed: _enviando || widget.demandaId == null
                    ? null
                    : () => mostrarDetalhesDemandaDialog(
                        context,
                        widget.demandaId!,
                      ),
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(widget.demandaTitulo),
              ),
              const SizedBox(height: 16),
              const Text('Data'),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                key: const ValueKey('selecionar-data-log-time'),
                onPressed: _enviando ? null : _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  '${_data.day.toString().padLeft(2, '0')}/'
                  '${_data.month.toString().padLeft(2, '0')}/'
                  '${_data.year}',
                ),
              ),
              const SizedBox(height: 16),
              _CamposHorario(
                titulo: 'Hora inicial',
                chave: 'inicio',
                hora: _horaInicio,
                minuto: _minutoInicio,
                enabled: !_enviando,
                autofocus: true,
                onChanged: _horarioAlterado,
              ),
              const SizedBox(height: 16),
              _CamposHorario(
                titulo: 'Hora final',
                chave: 'fim',
                hora: _horaFim,
                minuto: _minutoFim,
                enabled: !_enviando,
                onChanged: _horarioAlterado,
                onSubmitted: _submit,
              ),
              if (_intervaloOriginalMultidia) ...[
                const SizedBox(height: 12),
                const Text(
                  'Este lançamento termina em outro dia. Para editá-lo aqui, '
                  'ajuste os horários para um intervalo na mesma data.',
                ),
              ],
              if (_erro case final erro?) ...[
                const SizedBox(height: 12),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    erro,
                    key: const ValueKey('erro-edicao-log-time'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const ValueKey('salvar-log-time'),
          onPressed: _enviando ? null : _submit,
          icon: _enviando
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          label: Text(
            _enviando
                ? 'Salvando...'
                : widget.edicao
                ? 'Salvar'
                : 'Lançar',
          ),
        ),
      ],
    ),
  );

  void _horarioAlterado(String _) {
    if (_intervaloOriginalMultidia) {
      setState(() => _intervaloOriginalMultidia = false);
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: _data.isBefore(DateTime(2020)) ? _data : DateTime(2020),
      lastDate: _data.isAfter(DateTime(2100)) ? _data : DateTime(2100),
    );
    if (value != null && mounted) setState(() => _data = value);
  }

  Future<void> _submit() async {
    if (_enviando) return;
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;

    final dados = LogTimeFormData.doMesmoDia(
      data: _data,
      inicio: TimeOfDay(
        hour: int.parse(_horaInicio.text),
        minute: int.parse(_minutoInicio.text),
      ),
      fim: TimeOfDay(
        hour: int.parse(_horaFim.text),
        minute: int.parse(_minutoFim.text),
      ),
    );
    if (dados == null || _intervaloOriginalMultidia) {
      setState(() {
        _erro = 'A hora final deve ser posterior à hora inicial na mesma data.';
      });
      return;
    }
    final onSalvar = widget.onSalvar;
    if (onSalvar == null) {
      Navigator.pop(context, dados);
      return;
    }

    setState(() => _enviando = true);
    String? erro;
    try {
      erro = await onSalvar(dados);
    } catch (_) {
      erro = 'Não foi possível salvar o lançamento. Tente novamente.';
    }
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _erro = erro;
    });
    if (erro == null) Navigator.pop(context, dados);
  }
}

class _CamposHorario extends StatelessWidget {
  const _CamposHorario({
    required this.titulo,
    required this.chave,
    required this.hora,
    required this.minuto,
    required this.enabled,
    required this.onChanged,
    this.autofocus = false,
    this.onSubmitted,
  });

  final String titulo;
  final String chave;
  final TextEditingController hora;
  final TextEditingController minuto;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(titulo),
      const SizedBox(height: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _campo(horas: true)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(':'),
          ),
          Expanded(child: _campo(horas: false)),
        ],
      ),
    ],
  );

  Widget _campo({required bool horas}) {
    final proximo = horas || onSubmitted == null;
    final limite = horas ? 23 : 59;
    return Semantics(
      label: '$titulo: ${horas ? 'horas' : 'minutos'}',
      child: TextFormField(
        key: ValueKey('log-time-$chave-${horas ? 'hora' : 'minuto'}'),
        controller: horas ? hora : minuto,
        enabled: enabled,
        autofocus: horas && autofocus,
        keyboardType: TextInputType.number,
        textInputAction: proximo ? TextInputAction.next : TextInputAction.done,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(2),
        ],
        decoration: InputDecoration(labelText: horas ? 'HH' : 'MM'),
        onChanged: onChanged,
        validator: (value) {
          final numero = int.tryParse(value ?? '');
          if (numero == null) return horas ? 'Informe HH.' : 'Informe MM.';
          if (numero < 0 || numero > limite) return 'Use 00 a $limite.';
          return null;
        },
        onFieldSubmitted: proximo ? null : (_) => onSubmitted?.call(),
      ),
    );
  }
}
