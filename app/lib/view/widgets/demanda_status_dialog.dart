import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../view_model/demandas_view_model.dart';

Future<bool?> mostrarConclusaoEmCascataDialog(
  BuildContext context, {
  required backend.Demanda demanda,
  required DemandasViewModel viewModel,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _DialogoStatus(
    demanda: demanda,
    viewModel: viewModel,
    cancelamento: false,
  ),
);

Future<bool?> mostrarCancelamentoDemandaDialog(
  BuildContext context, {
  required backend.Demanda demanda,
  required DemandasViewModel viewModel,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: false,
  builder: (_) => _DialogoStatus(
    demanda: demanda,
    viewModel: viewModel,
    cancelamento: true,
  ),
);

class _DialogoStatus extends StatefulWidget {
  const _DialogoStatus({
    required this.demanda,
    required this.viewModel,
    required this.cancelamento,
  });

  final backend.Demanda demanda;
  final DemandasViewModel viewModel;
  final bool cancelamento;

  @override
  State<_DialogoStatus> createState() => _DialogoStatusState();
}

class _DialogoStatusState extends State<_DialogoStatus> {
  final _formKey = GlobalKey<FormState>();
  final _motivo = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (widget.viewModel.enviando) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _erro = null);
    final sucesso = widget.cancelamento
        ? await widget.viewModel.cancelarDemandaEmCascata(
            widget.demanda,
            _motivo.text.trim(),
          )
        : await widget.viewModel.concluirDemandaEmCascata(widget.demanda);
    if (!mounted) return;
    if (sucesso) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _erro = widget.viewModel.erro ?? 'Não foi possível alterar o status.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final enviando = widget.viewModel.envioGlobalEmAndamento;
      return PopScope(
        canPop: !enviando,
        child: AlertDialog(
          title: Text(
            widget.cancelamento ? 'Cancelar demanda?' : 'Concluir em cascata?',
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.demanda.titulo,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.cancelamento
                          ? 'Os descendentes ativos desta demanda, se houver, '
                                'também serão cancelados.'
                          : 'Esta demanda possui subdemandas ativas. Para concluir '
                                'a demanda mãe, todas as subdemandas ativas também '
                                'precisam ser concluídas.',
                    ),
                    if (widget.cancelamento) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        key: const ValueKey('motivo-cancelamento'),
                        controller: _motivo,
                        enabled: !enviando,
                        autofocus: true,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Motivo do cancelamento',
                        ),
                        validator: (valor) =>
                            valor == null || valor.trim().isEmpty
                            ? 'Informe o motivo do cancelamento.'
                            : null,
                      ),
                    ],
                    if (_erro != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _erro!,
                          key: const ValueKey('erro-dialogo-status'),
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
          ),
          actions: [
            TextButton(
              key: const ValueKey('voltar-dialogo-status'),
              onPressed: enviando
                  ? null
                  : () {
                      if (!widget.viewModel.envioGlobalEmAndamento) {
                        Navigator.pop(context);
                      }
                    },
              child: const Text('Voltar'),
            ),
            FilledButton.icon(
              key: ValueKey(
                widget.cancelamento
                    ? 'confirmar-cancelamento'
                    : 'confirmar-conclusao-cascata',
              ),
              onPressed: widget.viewModel.enviando ? null : _confirmar,
              icon: enviando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              label: Text(
                enviando
                    ? 'Salvando...'
                    : widget.cancelamento
                    ? 'Cancelar demanda'
                    : 'Concluir em cascata',
              ),
            ),
          ],
        ),
      );
    },
  );
}
