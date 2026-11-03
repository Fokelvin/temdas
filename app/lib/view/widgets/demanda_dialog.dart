import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../formatters/demanda_identificacao.dart';
import '../../view_model/demandas_view_model.dart';

/// Cadastro completo compartilhado por Demandas e pelo lançamento de tempo.
class CriarDemandaDialog extends StatefulWidget {
  const CriarDemandaDialog({super.key, required this.viewModel});
  final DemandasViewModel viewModel;
  @override
  State<CriarDemandaDialog> createState() => _CriarDemandaDialogState();
}

class _CriarDemandaDialogState extends State<CriarDemandaDialog> {
  final _form = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _horas = TextEditingController(text: '1');
  backend.Prioridade _prioridade = backend.Prioridade.media;
  String? _erro;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _horas.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (widget.viewModel.enviando || !_form.currentState!.validate()) return;
    setState(() => _erro = null);
    final descricao = _descricao.text.trim();
    final criada = await widget.viewModel.criarDemanda(
      titulo: _titulo.text.trim(),
      descricao: descricao.isEmpty ? null : descricao,
      tempoEstimadoHoras: _parseHoras(_horas.text)!,
      prioridade: _prioridade,
    );
    if (!mounted) return;
    final demanda = widget.viewModel.demandaCriada;
    if (criada && demanda?.id != null) {
      Navigator.pop(context, demanda);
    } else {
      setState(
        () => _erro =
            widget.viewModel.erro ?? 'Não foi possível criar a Demanda.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final ocupado = widget.viewModel.enviando;
      return PopScope(
        canPop: !ocupado,
        child: AlertDialog(
          scrollable: true,
          title: Row(
            children: [
              const Expanded(child: Text('Criar demanda')),
              IconButton(
                tooltip: 'Fechar',
                onPressed: ocupado ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    key: const ValueKey('criar-demanda-titulo'),
                    controller: _titulo,
                    autofocus: true,
                    enabled: !ocupado,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Informe o título.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('criar-demanda-descricao'),
                    controller: _descricao,
                    maxLines: 3,
                    enabled: !ocupado,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<backend.Prioridade>(
                    key: const ValueKey('criar-demanda-prioridade'),
                    initialValue: _prioridade,
                    decoration: const InputDecoration(labelText: 'Prioridade'),
                    items: [
                      for (final p in backend.Prioridade.values)
                        DropdownMenuItem(
                          value: p,
                          child: Text(_prioridadeLabel(p)),
                        ),
                    ],
                    onChanged: ocupado
                        ? null
                        : (v) {
                            if (v != null) setState(() => _prioridade = v);
                          },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('criar-demanda-tempo'),
                    controller: _horas,
                    enabled: !ocupado,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tempo estimado (horas)',
                    ),
                    validator: _validarHorasEstimadas,
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _erro!,
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
              onPressed: ocupado ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              key: const ValueKey('criar-demanda'),
              onPressed: ocupado ? null : _salvar,
              icon: ocupado
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              label: Text(ocupado ? 'Criando...' : 'Criar demanda'),
            ),
          ],
        ),
      );
    },
  );
}

class DemandaEdicaoFormData {
  const DemandaEdicaoFormData({
    required this.titulo,
    required this.tempoEstimadoHoras,
    required this.status,
    required this.prioridade,
    this.descricao,
  });

  final String titulo;
  final String? descricao;
  final double tempoEstimadoHoras;
  final backend.DemandaStatus status;
  final backend.Prioridade prioridade;
}

class DemandaFilhaFormData {
  const DemandaFilhaFormData({
    required this.titulo,
    required this.tempoEstimadoHoras,
    required this.prioridade,
    this.descricao,
  });

  final String titulo;
  final String? descricao;
  final double tempoEstimadoHoras;
  final backend.Prioridade prioridade;
}

class CriarDemandaFilhaDialog extends StatefulWidget {
  const CriarDemandaFilhaDialog({
    super.key,
    required this.demandaMae,
    required this.onSalvar,
  });

  final backend.Demanda demandaMae;
  final Future<bool> Function(DemandaFilhaFormData) onSalvar;

  @override
  State<CriarDemandaFilhaDialog> createState() =>
      _CriarDemandaFilhaDialogState();
}

class _CriarDemandaFilhaDialogState extends State<CriarDemandaFilhaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tempoController = TextEditingController(text: '1');
  backend.Prioridade _prioridade = backend.Prioridade.media;
  bool _enviando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        title: const Text('Criar demanda filha'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Demanda mãe: ${formatarIdentificacaoDemanda(widget.demandaMae)}',
                    key: const ValueKey('demanda-mae-fixa'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('criar-filha-titulo'),
                    controller: _tituloController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o título.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('criar-filha-descricao'),
                    controller: _descricaoController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<backend.Prioridade>(
                    key: const ValueKey('criar-filha-prioridade'),
                    initialValue: _prioridade,
                    decoration: const InputDecoration(labelText: 'Prioridade'),
                    items: backend.Prioridade.values
                        .map(
                          (prioridade) => DropdownMenuItem(
                            value: prioridade,
                            child: Text(_prioridadeLabel(prioridade)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _prioridade = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('criar-filha-tempo'),
                    controller: _tempoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tempo estimado (horas)',
                    ),
                    validator: _validarHorasEstimadas,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _enviando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            key: const ValueKey('salvar-demanda-filha'),
            onPressed: _enviando ? null : _salvar,
            icon: _enviando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            label: Text(_enviando ? 'Criando...' : 'Criar filha'),
          ),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    if (_enviando || !_formKey.currentState!.validate()) return;

    final descricao = _descricaoController.text.trim();
    setState(() => _enviando = true);
    try {
      final criada = await widget.onSalvar(
        DemandaFilhaFormData(
          titulo: _tituloController.text.trim(),
          descricao: descricao.isEmpty ? null : descricao,
          tempoEstimadoHoras: _parseHoras(_tempoController.text)!,
          prioridade: _prioridade,
        ),
      );
      if (mounted) Navigator.pop(context, criada);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}

class EditarDemandaDialog extends StatefulWidget {
  const EditarDemandaDialog({
    super.key,
    required this.demanda,
    required this.onSalvar,
  });

  final backend.Demanda demanda;
  final Future<bool> Function(DemandaEdicaoFormData) onSalvar;

  @override
  State<EditarDemandaDialog> createState() => _EditarDemandaDialogState();
}

class _EditarDemandaDialogState extends State<EditarDemandaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;
  late final TextEditingController _tempoController;
  late backend.DemandaStatus _status;
  late backend.Prioridade _prioridade;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    final demanda = widget.demanda;
    _tituloController = TextEditingController(text: demanda.titulo);
    _descricaoController = TextEditingController(text: demanda.descricao ?? '');
    _tempoController = TextEditingController(
      text: _formatarHoras(demanda.tempoEstimadoMinutos),
    );
    _status = demanda.status;
    _prioridade = demanda.prioridade;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_enviando,
      child: AlertDialog(
        title: const Text('Editar demanda'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    key: const ValueKey('editar-demanda-titulo'),
                    controller: _tituloController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Título'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o título.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('editar-demanda-descricao'),
                    controller: _descricaoController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descrição'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<backend.DemandaStatus>(
                    key: const ValueKey('editar-demanda-status'),
                    initialValue: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: backend.DemandaStatus.values
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(_statusLabel(status)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<backend.Prioridade>(
                    key: const ValueKey('editar-demanda-prioridade'),
                    initialValue: _prioridade,
                    decoration: const InputDecoration(labelText: 'Prioridade'),
                    items: backend.Prioridade.values
                        .map(
                          (prioridade) => DropdownMenuItem(
                            value: prioridade,
                            child: Text(_prioridadeLabel(prioridade)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _prioridade = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('editar-demanda-tempo'),
                    controller: _tempoController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tempo estimado (horas)',
                    ),
                    validator: _validarHorasEstimadas,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _enviando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            key: const ValueKey('salvar-edicao-demanda'),
            onPressed: _enviando ? null : _salvar,
            icon: _enviando
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
            label: Text(_enviando ? 'Salvando...' : 'Salvar alterações'),
          ),
        ],
      ),
    );
  }

  Future<void> _salvar() async {
    if (_enviando || !_formKey.currentState!.validate()) return;

    final descricao = _descricaoController.text.trim();
    setState(() => _enviando = true);
    try {
      final atualizada = await widget.onSalvar(
        DemandaEdicaoFormData(
          titulo: _tituloController.text.trim(),
          descricao: descricao.isEmpty ? null : descricao,
          tempoEstimadoHoras: _parseHoras(_tempoController.text)!,
          status: _status,
          prioridade: _prioridade,
        ),
      );
      if (mounted) Navigator.pop(context, atualizada);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}

double? _parseHoras(String? value) {
  return double.tryParse((value ?? '').trim().replaceAll(',', '.'));
}

String? _validarHorasEstimadas(String? value) {
  final horas = _parseHoras(value);
  if (horas == null || horas <= 0) {
    return 'Informe um tempo válido.';
  }
  if ((horas * 2).roundToDouble() != horas * 2) {
    return 'Use intervalos de 0,5 hora.';
  }
  return null;
}

String _formatarHoras(int minutos) {
  final horas = minutos / 60;
  if (horas == horas.truncateToDouble()) {
    return horas.toInt().toString();
  }
  return horas.toString().replaceAll('.', ',');
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
