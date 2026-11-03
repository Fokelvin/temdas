import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../view_model/sprint_view_model.dart';
import '../formatters/sprint_apresentacao.dart';

String _periodo(BuildContext context, backend.Sprint sprint) {
  final formatar = MaterialLocalizations.of(context).formatCompactDate;
  return '${formatar(sprint.dataInicio)} – ${formatar(sprint.dataFim)} · ${estadoSprint(sprint)}';
}

Future<backend.Sprint?> selecionarSprintParaVincular(
  BuildContext context, {
  required SprintViewModel viewModel,
  required String descricao,
  Set<int> excluir = const {},
}) => showDialog<backend.Sprint>(
  context: context,
  builder: (_) => _SeletorSprint(
    viewModel: viewModel,
    descricao: descricao,
    excluir: excluir,
  ),
);

class _SeletorSprint extends StatefulWidget {
  const _SeletorSprint({
    required this.viewModel,
    required this.descricao,
    required this.excluir,
  });

  final SprintViewModel viewModel;
  final String descricao;
  final Set<int> excluir;

  @override
  State<_SeletorSprint> createState() => _SeletorSprintState();
}

class _SeletorSprintState extends State<_SeletorSprint> {
  bool _carregando = true;
  bool _falhou = false;
  backend.Sprint? _selecionada;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final sucesso = await widget.viewModel.carregarSprints();
    if (mounted) {
      setState(() {
        _falhou = !sucesso;
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final opcoes = ordenarSprints(
      widget.viewModel.sprints.where(
        (s) =>
            sprintAberta(s) && s.id != null && !widget.excluir.contains(s.id),
      ),
    );
    return AlertDialog(
      title: const Text('Selecionar Sprint'),
      scrollable: true,
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.descricao),
            if (_carregando)
              const LinearProgressIndicator()
            else if (_falhou) ...[
              Text(
                widget.viewModel.erro ??
                    'Não foi possível carregar as Sprints.',
              ),
              TextButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente'),
              ),
            ] else if (opcoes.isEmpty)
              const Text('Nenhuma Sprint aberta disponível.')
            else
              RadioGroup<int>(
                groupValue: _selecionada?.id,
                onChanged: (id) => setState(() {
                  _selecionada = opcoes.firstWhere((s) => s.id == id);
                }),
                child: Column(
                  children: [
                    for (final s in opcoes)
                      RadioListTile<int>(
                        value: s.id!,
                        title: Text(nomeSprint(s.nome)),
                        subtitle: Text(_periodo(context, s)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selecionada == null
              ? null
              : () => Navigator.pop(context, _selecionada),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

Future<bool> confirmarDesvinculacaoSprint(
  BuildContext context,
  backend.Sprint sprint,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desvincular da Sprint?'),
        content: Text(
          'Remover o vínculo com ${nomeSprint(sprint.nome)}? Os vínculos das filhas nessa Sprint também podem ser removidos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    ) ??
    false;

/// Mantém o rascunho separado dos vínculos confirmados pelo servidor.
class SprintVinculosEditor extends StatefulWidget {
  const SprintVinculosEditor({
    super.key,
    this.demandaId,
    this.viewModel,
    required this.ocupado,
  });

  final int? demandaId;
  final SprintViewModel? viewModel;
  final bool ocupado;

  @override
  State<SprintVinculosEditor> createState() => SprintVinculosEditorState();
}

class SprintVinculosEditorState extends State<SprintVinculosEditor> {
  late final _vm = widget.viewModel ?? SprintViewModel();
  final _atuais = <int, backend.Sprint>{};
  final _adicionar = <int, backend.Sprint>{};
  final _remover = <int>{};
  bool _carregando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    if (widget.demandaId case final id?) _carregar(id);
  }

  @override
  void dispose() {
    if (widget.viewModel == null) _vm.dispose();
    super.dispose();
  }

  Future<void> _carregar(int id) async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final dados = await _vm.carregarSprintsDasDemandas(demandaIds: [id]);
    if (!mounted) return;
    setState(() {
      _carregando = false;
      if (dados == null) {
        _erro = _vm.erro ?? 'Não foi possível consultar os vínculos.';
      } else {
        _atuais
          ..clear()
          ..addEntries(
            (dados[id] ?? [])
                .where((s) => s.id != null)
                .map((s) => MapEntry(s.id!, s)),
          );
      }
    });
  }

  Future<void> _escolher() async {
    final sprint = await selecionarSprintParaVincular(
      context,
      viewModel: _vm,
      descricao: 'O vínculo será aplicado ao salvar a Demanda.',
      excluir: {..._atuais.keys, ..._adicionar.keys},
    );
    if (mounted && sprint != null) {
      setState(() => _adicionar[sprint.id!] = sprint);
    }
  }

  Future<List<String>> aplicar(int demandaId) async {
    final falhas = <String>[];
    if (_remover.isEmpty && _adicionar.isEmpty) return falhas;
    for (final id in _remover) {
      final sucesso = await _vm.desvincularDemanda(
        sprintId: id,
        demandaId: demandaId,
      );
      if (!sucesso) {
        falhas.add(
          '${nomeSprint(_atuais[id]!.nome)}: ${_vm.erro ?? 'Desvinculação não confirmada.'}',
        );
      }
    }
    for (final sprint in _adicionar.values) {
      final sucesso = await _vm.vincularDemanda(
        sprintId: sprint.id!,
        demandaId: demandaId,
      );
      if (!sucesso) {
        falhas.add(
          '${nomeSprint(sprint.nome)}: ${_vm.erro ?? 'Vínculo não confirmado.'}',
        );
        if (_vm.vinculacaoInconclusiva) {
          if (sprint.id != _adicionar.keys.last) {
            falhas.add('Os vínculos seguintes não foram enviados.');
          }
          break;
        }
      }
    }
    if (mounted) {
      _adicionar.clear();
      _remover.clear();
      await _carregar(demandaId);
      if (_erro != null) {
        falhas.add('Não foi possível atualizar a lista de vínculos.');
      }
    }
    return falhas;
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = !widget.ocupado && !_carregando && _erro == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Sprints'),
        if (_carregando) const LinearProgressIndicator(),
        if (_erro case final erro?) ...[
          Text(erro),
          TextButton(
            onPressed: widget.ocupado
                ? null
                : () => _carregar(widget.demandaId!),
            child: const Text('Tentar novamente'),
          ),
        ],
        for (final sprint in ordenarSprints([
          ..._atuais.values,
          ..._adicionar.values,
        ]))
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(nomeSprint(sprint.nome)),
            subtitle: Text(
              '${_periodo(context, sprint)}${!sprintAberta(sprint)
                  ? ' · Histórico'
                  : _remover.contains(sprint.id)
                  ? ' · Remover ao salvar'
                  : _adicionar.containsKey(sprint.id)
                  ? ' · Vincular ao salvar'
                  : ''}',
            ),
            trailing: !sprintAberta(sprint)
                ? null
                : IconButton(
                    tooltip: _remover.contains(sprint.id)
                        ? 'Manter vínculo'
                        : 'Remover vínculo ao salvar',
                    onPressed: !habilitado
                        ? null
                        : () => setState(() {
                            final id = sprint.id!;
                            if (_adicionar.remove(id) != null ||
                                _remover.remove(id)) {
                              return;
                            }
                            _remover.add(id);
                          }),
                    icon: Icon(
                      _remover.contains(sprint.id)
                          ? Icons.undo
                          : Icons.link_off,
                    ),
                  ),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: habilitado ? _escolher : null,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Sprint'),
          ),
        ),
      ],
    );
  }
}

Future<void> mostrarFalhasDeVinculos(
  BuildContext context,
  String titulo,
  List<String> falhas,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(titulo),
    scrollable: true,
    content: Text(falhas.join('\n\n')),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Fechar'),
      ),
    ],
  ),
);
