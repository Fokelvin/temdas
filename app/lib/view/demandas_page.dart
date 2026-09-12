import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../view_model/demandas_view_model.dart';
import 'widgets/app_drawer.dart';
import 'widgets/demanda_dialog.dart';
import 'widgets/demanda_tree.dart';
import 'widgets/log_time_dialog.dart';

class DemandasPage extends StatefulWidget {
  const DemandasPage({super.key, this.viewModel});

  final DemandasViewModel? viewModel;

  @override
  State<DemandasPage> createState() => _DemandasPageState();
}

class _DemandasPageState extends State<DemandasPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _tempoController = TextEditingController(text: '1');
  late final DemandasViewModel _viewModel;
  late final bool _possuiViewModel;

  backend.Prioridade _prioridade = backend.Prioridade.media;

  @override
  void initState() {
    super.initState();
    _possuiViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? DemandasViewModel();
    _viewModel.carregarDemandas();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _tempoController.dispose();
    if (_possuiViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _criarDemanda() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final descricao = _descricaoController.text.trim();
    final criada = await _viewModel.criarDemanda(
      titulo: _tituloController.text.trim(),
      tempoEstimadoHoras: _parseHoras(_tempoController.text)!,
      descricao: descricao.isEmpty ? null : descricao,
      prioridade: _prioridade,
    );

    if (!mounted) return;
    if (criada) {
      _tituloController.clear();
      _descricaoController.clear();
      _tempoController.text = '1';
    }
    _mostrarFeedback(
      criada
          ? 'Demanda criada com sucesso.'
          : _viewModel.erro ?? 'Não foi possível criar a demanda.',
      erro: !criada,
    );
  }

  Future<void> _criarDemandaFilha(backend.Demanda demandaMae) async {
    final demandaMaeId = demandaMae.id;
    if (demandaMaeId == null) {
      _mostrarFeedback('A demanda mãe não possui um ID válido.', erro: true);
      return;
    }

    final dados = await showDialog<DemandaFilhaFormData>(
      context: context,
      builder: (_) => CriarDemandaFilhaDialog(demandaMae: demandaMae),
    );

    if (dados == null || !mounted) return;
    final criada = await _viewModel.criarDemanda(
      titulo: dados.titulo,
      descricao: dados.descricao,
      tempoEstimadoHoras: dados.tempoEstimadoHoras,
      prioridade: dados.prioridade,
      demandaPaiId: demandaMaeId,
    );

    if (!mounted) return;
    _mostrarFeedback(
      criada
          ? 'Demanda filha criada com sucesso.'
          : _viewModel.erro ?? 'Não foi possível criar a demanda filha.',
      erro: !criada,
    );
  }

  Future<void> _editarDemanda(backend.Demanda demanda) async {
    final dados = await showDialog<DemandaEdicaoFormData>(
      context: context,
      builder: (_) => EditarDemandaDialog(demanda: demanda),
    );

    if (dados == null || !mounted) return;

    final atualizada = await _viewModel.atualizarDemanda(
      demanda: demanda,
      titulo: dados.titulo,
      descricao: dados.descricao,
      tempoEstimadoHoras: dados.tempoEstimadoHoras,
      status: dados.status,
      prioridade: dados.prioridade,
    );

    if (!mounted) return;
    _mostrarFeedback(
      atualizada
          ? 'Demanda atualizada com sucesso.'
          : _viewModel.erro ?? 'Não foi possível atualizar a demanda.',
      erro: !atualizada,
    );
  }

  Future<void> _excluirDemanda(backend.Demanda demanda) async {
    final possuiDescendentes = _viewModel.possuiDescendentes(demanda);
    final descendentes = possuiDescendentes
        ? _viewModel.descendentesDe(demanda).length
        : 0;
    final confirmada = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          possuiDescendentes
              ? 'Excluir demanda e descendentes?'
              : 'Excluir demanda?',
        ),
        content: Text(
          possuiDescendentes
              ? 'A demanda “${demanda.titulo}” possui $descendentes '
                    '${descendentes == 1 ? 'descendente' : 'descendentes'}. '
                    'A demanda, toda a árvore abaixo dela e todos os registros '
                    'de tempo vinculados serão excluídos permanentemente.'
              : 'A demanda “${demanda.titulo}” será excluída permanentemente. '
                    'Essa ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: ValueKey('confirmar-exclusao-${demanda.id}'),
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: Text(possuiDescendentes ? 'Excluir tudo' : 'Excluir'),
          ),
        ],
      ),
    );

    if (confirmada != true || !mounted) return;

    final excluida = possuiDescendentes
        ? await _viewModel.excluirArvoreDemanda(demanda)
        : await _viewModel.excluirDemanda(demanda);

    if (!mounted) return;
    _mostrarFeedback(
      excluida
          ? possuiDescendentes
                ? 'Demanda e descendentes excluídos com sucesso.'
                : 'Demanda excluída com sucesso.'
          : _viewModel.erro ?? 'Não foi possível excluir a demanda.',
      erro: !excluida,
    );
  }

  Future<void> _lancarTempo(backend.Demanda demanda) async {
    if (demanda.id == null) {
      _mostrarFeedback('A demanda não possui um ID válido.', erro: true);
      return;
    }

    final dados = await showDialog<LogTimeFormData>(
      context: context,
      builder: (_) => LogTimeDialog(
        demandaTitulo: demanda.titulo,
        dataInicial: DateTime.now(),
      ),
    );
    if (dados == null || !mounted) return;

    final duracaoMinutos = (dados.duracaoHoras * 60).round();
    if (duracaoMinutos <= 0) {
      _mostrarFeedback(
        'Informe uma duração de pelo menos um minuto.',
        erro: true,
      );
      return;
    }

    final inicioLocal = DateTime(
      dados.data.year,
      dados.data.month,
      dados.data.day,
      dados.hora.hour,
      dados.hora.minute,
    );
    final registrado = await _viewModel.registrarTempo(
      demanda: demanda,
      inicioEm: inicioLocal.toUtc(),
      duracaoMinutos: duracaoMinutos,
    );

    if (!mounted) return;
    _mostrarFeedback(
      registrado
          ? 'Tempo registrado com sucesso.'
          : _viewModel.erro ?? 'Não foi possível registrar o tempo.',
      erro: !registrado,
    );
  }

  void _mostrarTudo(backend.Demanda demanda) {
    final id = demanda.id;
    if (id == null) {
      _mostrarFeedback('A demanda não possui um ID válido.', erro: true);
      return;
    }
    Navigator.pushNamed(context, AppRoutes.demandaDetalhe, arguments: id);
  }

  void _mostrarFeedback(String mensagem, {required bool erro}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: erro ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => PageScaffold(
        title: 'Demandas',
        route: AppRoutes.demandas,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildFormulario(context),
                if (_viewModel.erro != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _viewModel.erro!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Demandas salvas',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Recarregar demandas',
                      onPressed: _viewModel.carregando || _viewModel.enviando
                          ? null
                          : _viewModel.carregarDemandas,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_viewModel.carregando)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_viewModel.demandas.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Nenhuma demanda cadastrada.'),
                    ),
                  )
                else
                  DemandaTree(
                    demandas: _viewModel.demandas,
                    acoesHabilitadas: !_viewModel.enviando,
                    onEditar: _editarDemanda,
                    onExcluir: _excluirDemanda,
                    onCriarFilha: _criarDemandaFilha,
                    onLancarTempo: _lancarTempo,
                    onMostrarTudo: _mostrarTudo,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Criar demanda',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Informe o título.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<backend.Prioridade>(
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
                  if (value != null) setState(() => _prioridade = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tempoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Tempo estimado (horas)',
                ),
                validator: _validarHorasEstimadas,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _viewModel.carregando || _viewModel.enviando
                    ? null
                    : _criarDemanda,
                child: Text(
                  _viewModel.enviando ? 'Enviando...' : 'Criar demanda',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

double? _parseHoras(String? value) {
  return double.tryParse((value ?? '').trim().replaceAll(',', '.'));
}

String? _validarHorasEstimadas(String? value) {
  final horas = _parseHoras(value);
  if (horas == null || horas <= 0) return 'Informe um tempo válido.';
  if ((horas * 2).roundToDouble() != horas * 2) {
    return 'Use intervalos de 0,5 hora.';
  }
  return null;
}

String _prioridadeLabel(backend.Prioridade prioridade) {
  return switch (prioridade) {
    backend.Prioridade.baixa => 'Baixa',
    backend.Prioridade.media => 'Média',
    backend.Prioridade.alta => 'Alta',
    backend.Prioridade.urgente => 'Urgente',
  };
}
