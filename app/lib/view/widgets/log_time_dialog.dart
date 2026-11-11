import '../formatters/demanda_hierarquia.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;
import 'registro_tempo_observacoes.dart';
import '../formatters/demanda_identificacao.dart';
import '../formatters/texto_busca.dart';

import '../../view_model/log_time_form_data.dart';
import '../demanda_detalhe_page.dart';

export '../../view_model/log_time_form_data.dart';

class LogTimeDialog extends StatefulWidget {
  const LogTimeDialog({
    super.key,
    this.demandaTitulo = '',
    required this.dataInicial,
    this.demandaId,
    this.observacaoInicial,
    this.observacoesOriginais,
    this.onSalvar,
    this.horaInicial,
    this.demandas,
    this.demandaPorId,
    this.onCriarDemanda,
  }) : duracaoInicialMinutos = LogTimeFormData.duracaoPadraoMinutos,
       edicao = false;

  const LogTimeDialog.editar({
    super.key,
    required this.demandaTitulo,
    required this.dataInicial,
    required TimeOfDay this.horaInicial,
    required this.duracaoInicialMinutos,
    required Future<String?> Function(LogTimeFormData) this.onSalvar,
    this.demandaId,
    this.observacaoInicial,
    this.observacoesOriginais,
  }) : edicao = true,
       demandas = null,
       demandaPorId = null,
       onCriarDemanda = null;

  final String demandaTitulo;
  final List<backend.Demanda>? demandas;
  final backend.Demanda? Function(int)? demandaPorId;
  final Future<backend.Demanda?> Function()? onCriarDemanda;
  final int? demandaId;
  final DateTime dataInicial;
  final TimeOfDay? horaInicial;
  final int duracaoInicialMinutos;
  final bool edicao;
  final String? observacaoInicial;
  final List<backend.RegistroTempoObservacao>? observacoesOriginais;

  /// Retorna uma mensagem em caso de falha, ou null após salvar com sucesso.
  final Future<String?> Function(LogTimeFormData)? onSalvar;

  @override
  State<LogTimeDialog> createState() => _LogTimeDialogState();
}

class _LogTimeDialogState extends State<LogTimeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _observacao;
  late final TextEditingController _horaInicio;
  late final TextEditingController _minutoInicio;
  late final TextEditingController _horaFim;
  late final TextEditingController _minutoFim;
  late DateTime _data;
  bool _intervaloOriginalMultidia = false;
  bool _enviando = false;
  String? _erro;
  final _pesquisaDemanda = TextEditingController();
  final _focoDemanda = FocusNode();
  late final List<backend.Demanda> _opcoes;
  backend.Demanda? _demandaSelecionada;
  bool _criandoDemanda = false;
  bool get _selecaoLivre => !widget.edicao && widget.demandas != null;

  @override
  void initState() {
    super.initState();
    _observacao = TextEditingController(
      text: textoObservacaoEditavel(
        texto: widget.observacaoInicial,
        originais: widget.observacoesOriginais,
      ),
    );
    _opcoes = [
      for (final d in widget.demandas ?? <backend.Demanda>[])
        if (d.id != null) d,
    ];
    for (final d in _opcoes) {
      if (d.id == widget.demandaId) _demandaSelecionada = d;
    }
    if (_demandaSelecionada != null) {
      _pesquisaDemanda.text = formatarIdentificacaoDemanda(
        _demandaSelecionada!,
      );
    }
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
    _observacao.dispose();
    _horaInicio.dispose();
    _minutoInicio.dispose();
    _horaFim.dispose();
    _minutoFim.dispose();
    _pesquisaDemanda.dispose();
    _focoDemanda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_enviando && !_criandoDemanda,
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
              if (_selecaoLivre)
                _campoDemanda()
              else ...[
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
              ],
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
                autofocus: !_selecaoLivre,
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
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('log-time-observacao'),
                controller: _observacao,
                enabled: !_enviando,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                ),
              ),
              RegistroTempoObservacoes(
                originais: widget.observacoesOriginais,
                mostrarTextos: false,
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
          onPressed: _enviando || _criandoDemanda
              ? null
              : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          key: const ValueKey('salvar-log-time'),
          onPressed: _enviando || _criandoDemanda ? null : _submit,
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

  List<backend.Demanda> _filtrarDemandas(String texto) {
    final busca = normalizarTextoBusca(texto.trim());
    return _opcoes
        .where(
          (d) => normalizarTextoBusca(
            formatarIdentificacaoDemanda(d),
          ).contains(busca),
        )
        .toList();
  }

  late final _porId = indexarDemandas(_opcoes);

  String? _ancestrais(backend.Demanda d) =>
      caminhoAncestral(d, (id) => widget.demandaPorId?.call(id) ?? _porId[id]);

  Widget _campoDemanda() {
    final largura = (MediaQuery.sizeOf(context).width - 180).clamp(80.0, 408.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RawAutocomplete<backend.Demanda>(
            textEditingController: _pesquisaDemanda,
            focusNode: _focoDemanda,
            displayStringForOption: formatarIdentificacaoDemanda,
            optionsBuilder: (v) => _filtrarDemandas(v.text),
            onSelected: (d) => setState(() => _demandaSelecionada = d),
            fieldViewBuilder: (context, controller, focus, submit) =>
                TextFormField(
                  key: const ValueKey('selecionar-demanda-log-time'),
                  controller: controller,
                  focusNode: focus,
                  autofocus: true,
                  enabled: !_enviando && !_criandoDemanda,
                  decoration: InputDecoration(
                    labelText: 'Demanda',
                    hintText: 'Pesquisar por ID ou título',
                    helperText:
                        _demandaSelecionada != null &&
                            _ancestrais(_demandaSelecionada!) != null
                        ? '↳ ${_ancestrais(_demandaSelecionada!)}'
                        : _opcoes.isEmpty
                        ? 'Nenhuma Demanda cadastrada. Use + para criar.'
                        : _filtrarDemandas(controller.text).isEmpty
                        ? 'Nenhuma Demanda encontrada.'
                        : null,
                    helperMaxLines: 3,
                  ),
                  validator: (_) => _demandaSelecionada?.id == null
                      ? 'Selecione uma demanda válida.'
                      : null,
                  onChanged: (_) => setState(() => _demandaSelecionada = null),
                  onFieldSubmitted: (_) => submit(),
                ),
            optionsViewBuilder: (context, select, options) => Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: largura,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.sizeOf(context).height * .3,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final d = options.elementAt(index);
                        final ancestrais = _ancestrais(d);
                        return ListTile(
                          key: ValueKey('opcao-demanda-log-time-${d.id}'),
                          dense: true,
                          selected:
                              AutocompleteHighlightedOption.of(context) ==
                              index,
                          title: Text(
                            formatarIdentificacaoDemanda(d),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: ancestrais != null
                              ? Tooltip(
                                  message: ancestrais,
                                  child: Text(
                                    '↳ $ancestrais',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : null,
                          onTap: () => select(d),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          key: const ValueKey('criar-demanda-no-log-time'),
          tooltip: 'Criar demanda',
          onPressed:
              _enviando || _criandoDemanda || widget.onCriarDemanda == null
              ? null
              : _criarDemanda,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Future<void> _criarDemanda() async {
    _focoDemanda.unfocus();
    setState(() {
      _criandoDemanda = true;
      _erro = null;
    });
    try {
      final criada = await widget.onCriarDemanda!();
      if (!mounted || criada?.id == null) return;
      setState(() {
        _opcoes.removeWhere((d) => d.id == criada!.id);
        _opcoes.add(criada!);
        _demandaSelecionada = criada;
        _pesquisaDemanda.text = formatarIdentificacaoDemanda(criada);
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _erro =
              'Não foi possível criar a Demanda. Seus dados de lançamento foram mantidos.',
        );
      }
    } finally {
      if (mounted) setState(() => _criandoDemanda = false);
    }
  }

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
    if (_enviando || _criandoDemanda) return;
    setState(() => _erro = null);
    if (!_formKey.currentState!.validate()) return;

    final dados = LogTimeFormData.doMesmoDia(
      data: _data,
      observacao: _observacao.text,
      demandaId: _selecaoLivre ? _demandaSelecionada?.id : widget.demandaId,
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
