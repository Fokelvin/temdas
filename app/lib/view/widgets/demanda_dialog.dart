import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

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
  const CriarDemandaFilhaDialog({super.key, required this.demandaMae});

  final backend.Demanda demandaMae;

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

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _tempoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
                  'Demanda mãe: ${widget.demandaMae.titulo}',
                  key: const ValueKey('demanda-mae-fixa'),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('salvar-demanda-filha'),
          onPressed: _salvar,
          child: const Text('Criar filha'),
        ),
      ],
    );
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final descricao = _descricaoController.text.trim();
    Navigator.pop(
      context,
      DemandaFilhaFormData(
        titulo: _tituloController.text.trim(),
        descricao: descricao.isEmpty ? null : descricao,
        tempoEstimadoHoras: _parseHoras(_tempoController.text)!,
        prioridade: _prioridade,
      ),
    );
  }
}

class EditarDemandaDialog extends StatefulWidget {
  const EditarDemandaDialog({super.key, required this.demanda});

  final backend.Demanda demanda;

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
    return AlertDialog(
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
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          key: const ValueKey('salvar-edicao-demanda'),
          onPressed: _salvar,
          child: const Text('Salvar alterações'),
        ),
      ],
    );
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;

    final descricao = _descricaoController.text.trim();
    Navigator.pop(
      context,
      DemandaEdicaoFormData(
        titulo: _tituloController.text.trim(),
        descricao: descricao.isEmpty ? null : descricao,
        tempoEstimadoHoras: _parseHoras(_tempoController.text)!,
        status: _status,
        prioridade: _prioridade,
      ),
    );
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
