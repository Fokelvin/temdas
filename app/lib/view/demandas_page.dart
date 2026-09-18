import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import 'formatters/demanda_identificacao.dart';
import '../theme/app_theme.dart';
import '../view_model/demandas_view_model.dart';
import 'demanda_detalhe_page.dart';
import 'widgets/app_drawer.dart';
import 'widgets/demanda_dialog.dart';
import 'widgets/demanda_status_dialog.dart';
import 'widgets/demanda_tree.dart';
import 'widgets/densidade_demanda.dart';
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
  final _buscaController = TextEditingController();
  final _quadroHorizontalController = ScrollController();
  late final DemandasViewModel _viewModel;
  late final bool _possuiViewModel;

  backend.Prioridade _prioridade = backend.Prioridade.media;
  backend.Prioridade? _filtroPrioridade;
  DensidadeDemanda _densidade = DensidadeDemanda.normal;
  int _filtroVersao = 0;
  final Set<int> _demandasEmStatus = {};

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
    _buscaController.dispose();
    _quadroHorizontalController.dispose();
    if (_possuiViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  bool get _filtrosAtivos =>
      _buscaController.text.trim().isNotEmpty || _filtroPrioridade != null;

  void _alterarBusca(String valor) {
    setState(() => _filtroVersao++);
  }

  void _alterarPrioridadeFiltro(backend.Prioridade? valor) {
    setState(() {
      _filtroPrioridade = valor;
      _filtroVersao++;
    });
  }

  void _limparFiltros() {
    _buscaController.clear();
    setState(() {
      _filtroPrioridade = null;
      _filtroVersao++;
    });
  }

  _ResultadoBusca _resultadoBusca() {
    final busca = _buscaController.text.trim().toLowerCase();
    final idBuscado = int.tryParse(busca);
    final demandasComPrioridade = _viewModel.demandas.where(
      (demanda) =>
          _filtroPrioridade == null || demanda.prioridade == _filtroPrioridade,
    );
    final candidatas = demandasComPrioridade.toList();
    List<backend.Demanda> correspondentes;
    if (busca.isEmpty) {
      correspondentes = candidatas;
    } else if (idBuscado != null &&
        candidatas.any((demanda) => demanda.id == idBuscado)) {
      correspondentes = candidatas
          .where((demanda) => demanda.id == idBuscado)
          .toList();
    } else {
      correspondentes = candidatas
          .where((demanda) => demanda.titulo.toLowerCase().contains(busca))
          .toList();
    }

    if (!_filtrosAtivos) {
      return _ResultadoBusca(
        demandas: _viewModel.demandas,
        autoExpandIds: const {},
        focoDemandaId: null,
      );
    }

    final porId = <int, backend.Demanda>{
      for (final demanda in _viewModel.demandas)
        if (demanda.id != null) demanda.id!: demanda,
    };
    final idsVisiveis = <int>{};
    final idsExpandir = <int>{};
    for (final correspondente in correspondentes) {
      var atual = correspondente;
      while (true) {
        final id = atual.id;
        if (id != null) idsVisiveis.add(id);
        final paiId = atual.demandaPaiId;
        if (paiId == null) break;
        idsVisiveis.add(paiId);
        idsExpandir.add(paiId);
        final pai = porId[paiId];
        if (pai == null) break;
        atual = pai;
      }
    }

    final demandasVisiveis = _viewModel.demandas
        .where((demanda) => idsVisiveis.contains(demanda.id))
        .toList();
    return _ResultadoBusca(
      demandas: demandasVisiveis,
      autoExpandIds: idsExpandir,
      focoDemandaId: correspondentes.length == 1
          ? correspondentes.single.id
          : null,
    );
  }

  Future<void> _abrirFormulario() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => PopScope(
          canPop: !_viewModel.enviando,
          child: AlertDialog(
            title: Row(
              children: [
                const Expanded(child: Text('Criar demanda')),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: _viewModel.enviando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(child: _buildFormulario(context)),
            ),
            actions: [
              TextButton(
                onPressed: _viewModel.enviando
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                key: const ValueKey('criar-demanda'),
                onPressed: _viewModel.carregando || _viewModel.enviando
                    ? null
                    : () => _criarDemanda(dialogContext),
                icon: _viewModel.enviando
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                label: Text(
                  _viewModel.enviando ? 'Criando...' : 'Criar demanda',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _criarDemanda(BuildContext dialogContext) async {
    if (_viewModel.enviando || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

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
      if (dialogContext.mounted) Navigator.pop(dialogContext);
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

    final criada = await showDialog<bool>(
      context: context,
      builder: (_) => CriarDemandaFilhaDialog(
        demandaMae: demandaMae,
        onSalvar: (dados) => _viewModel.criarDemanda(
          titulo: dados.titulo,
          descricao: dados.descricao,
          tempoEstimadoHoras: dados.tempoEstimadoHoras,
          prioridade: dados.prioridade,
          demandaPaiId: demandaMaeId,
        ),
      ),
    );

    if (criada == null || !mounted) return;
    _mostrarFeedback(
      criada
          ? 'Demanda filha criada com sucesso.'
          : _viewModel.erro ?? 'Não foi possível criar a demanda filha.',
      erro: !criada,
    );
  }

  Future<void> _editarDemanda(backend.Demanda demanda) async {
    if (_viewModel.envioGlobalEmAndamento ||
        _viewModel.demandaEmProcessamento(demanda.id) ||
        _demandasEmStatus.contains(demanda.id)) {
      return;
    }
    final atualizada = await showDialog<bool>(
      context: context,
      builder: (_) => EditarDemandaDialog(
        demanda: demanda,
        onSalvar: (dados) => _viewModel.atualizarDemanda(
          demanda: demanda,
          titulo: dados.titulo,
          descricao: dados.descricao,
          tempoEstimadoHoras: dados.tempoEstimadoHoras,
          status: dados.status,
          prioridade: dados.prioridade,
        ),
      ),
    );

    if (atualizada == null || !mounted) return;
    _mostrarFeedback(
      atualizada
          ? 'Demanda atualizada com sucesso.'
          : _viewModel.erroDaDemanda(demanda.id) ??
                'Não foi possível atualizar a demanda.',
      erro: !atualizada,
    );
  }

  Future<void> _alterarStatusDemanda(
    backend.Demanda demanda,
    backend.DemandaStatus status,
  ) async {
    final id = demanda.id;
    if (_demandasEmStatus.contains(id) ||
        _viewModel.demandaEmProcessamento(id) ||
        _viewModel.envioGlobalEmAndamento ||
        _viewModel.carregando) {
      return;
    }
    if (id == null) {
      _mostrarFeedback('A demanda não possui um ID válido.', erro: true);
      return;
    }

    setState(() => _demandasEmStatus.add(id));
    try {
      switch (status) {
        case backend.DemandaStatus.concluida:
          await _concluirDemanda(demanda);
        case backend.DemandaStatus.cancelada:
          final cancelada = await mostrarCancelamentoDemandaDialog(
            context,
            demanda: demanda,
            viewModel: _viewModel,
          );
          if (mounted && cancelada == true) {
            _mostrarResultadoStatus(
              demanda,
              true,
              'Demanda cancelada com sucesso.',
            );
          }
        default:
          final alterada = await _viewModel.alterarStatusDemanda(
            demanda: demanda,
            status: status,
          );
          if (mounted) {
            _mostrarResultadoStatus(
              demanda,
              alterada,
              'Status atualizado com sucesso.',
            );
          }
      }
    } finally {
      if (mounted) setState(() => _demandasEmStatus.remove(id));
    }
  }

  Future<void> _reabrirDemanda(backend.Demanda demanda) async {
    final id = demanda.id;
    if (id == null ||
        _demandasEmStatus.contains(id) ||
        _viewModel.demandaEmProcessamento(id) ||
        _viewModel.envioGlobalEmAndamento ||
        _viewModel.carregando) {
      return;
    }

    setState(() => _demandasEmStatus.add(id));
    try {
      final reaberta = await mostrarReaberturaDemandaDialog(
        context,
        demanda: demanda,
        viewModel: _viewModel,
      );
      if (mounted && reaberta == true) {
        _mostrarResultadoStatus(
          demanda,
          true,
          demanda.status == backend.DemandaStatus.concluida
              ? 'Demanda reaberta com sucesso.'
              : 'Demanda reativada com sucesso.',
        );
      }
    } finally {
      if (mounted) setState(() => _demandasEmStatus.remove(id));
    }
  }

  Future<void> _concluirDemanda(backend.Demanda demanda) async {
    final concluida = await _viewModel.concluirDemanda(demanda);
    if (!mounted) return;
    if (concluida) {
      _mostrarResultadoStatus(demanda, true, 'Demanda concluída com sucesso.');
      return;
    }

    final erro = _viewModel.erroTransicaoDaDemanda(demanda.id);
    if (erro?.codigo == backend.TransicaoStatusErroCodigo.descendentesAtivos &&
        erro?.podeConcluirEmCascata == true) {
      final cascata = await mostrarConclusaoEmCascataDialog(
        context,
        demanda: demanda,
        viewModel: _viewModel,
      );
      if (mounted && cascata == true) {
        _mostrarResultadoStatus(demanda, true, 'Demanda concluída em cascata.');
      }
    } else {
      _mostrarResultadoStatus(demanda, false, '');
    }
  }

  void _mostrarResultadoStatus(
    backend.Demanda demanda,
    bool sucesso,
    String mensagemSucesso,
  ) {
    final erro = _viewModel.erroDaDemanda(demanda.id);
    _mostrarFeedback(
      erro ??
          (sucesso ? mensagemSucesso : 'Não foi possível alterar o status.'),
      erro: !sucesso || erro != null,
    );
  }

  Future<void> _excluirDemanda(backend.Demanda demanda) async {
    final possuiDescendentes = _viewModel.possuiDescendentes(demanda);
    final descendentes = possuiDescendentes
        ? _viewModel.descendentesDe(demanda).length
        : 0;
    var excluindo = false;
    final excluida = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PopScope(
          canPop: !excluindo,
          child: AlertDialog(
            title: Text(
              possuiDescendentes
                  ? 'Excluir demanda e descendentes?'
                  : 'Excluir demanda?',
            ),
            content: Text(
              possuiDescendentes
                  ? 'A demanda “${formatarIdentificacaoDemanda(demanda)}” possui $descendentes '
                        '${descendentes == 1 ? 'descendente' : 'descendentes'}. '
                        'A demanda, toda a árvore abaixo dela e todos os registros '
                        'de tempo vinculados serão excluídos permanentemente.'
                  : 'A demanda “${formatarIdentificacaoDemanda(demanda)}” será excluída permanentemente. '
                        'Essa ação não pode ser desfeita.',
            ),
            actions: [
              TextButton(
                onPressed: excluindo
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                key: ValueKey('confirmar-exclusao-${demanda.id}'),
                onPressed: excluindo
                    ? null
                    : () async {
                        if (excluindo) return;
                        setDialogState(() => excluindo = true);
                        final resultado = possuiDescendentes
                            ? await _viewModel.excluirArvoreDemanda(demanda)
                            : await _viewModel.excluirDemanda(demanda);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, resultado);
                        }
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
                icon: excluindo
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                label: Text(
                  excluindo
                      ? 'Excluindo...'
                      : possuiDescendentes
                      ? 'Excluir tudo'
                      : 'Excluir',
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (excluida == null || !mounted) return;
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
      barrierDismissible: false,
      builder: (_) => LogTimeDialog(
        demandaId: demanda.id,
        demandaTitulo: formatarIdentificacaoDemanda(demanda),
        dataInicial: DateTime.now(),
        onSalvar: (dados) async {
          final registrado = await _viewModel.registrarTempo(
            demanda: demanda,
            inicioEm: dados.inicioEm,
            duracaoMinutos: dados.duracaoMinutos,
          );
          return registrado
              ? null
              : _viewModel.erroDaDemanda(demanda.id) ??
                    'Não foi possível registrar o tempo.';
        },
      ),
    );
    if (dados == null || !mounted) return;

    final erro = _viewModel.erroDaDemanda(demanda.id);
    _mostrarFeedback(
      erro ?? 'Tempo registrado com sucesso.',
      erro: erro != null,
    );
  }

  void _mostrarTudo(backend.Demanda demanda) {
    final id = demanda.id;
    if (id == null) {
      _mostrarFeedback('A demanda não possui um ID válido.', erro: true);
      return;
    }
    mostrarDetalhesDemandaDialog(context, id);
  }

  Future<bool> _moverDemanda(
    backend.Demanda demanda,
    backend.DemandaStatus statusDestino,
    int posicaoDestino,
  ) async {
    final sucesso = await _viewModel.moverDemanda(
      demanda: demanda,
      statusDestino: statusDestino,
      posicaoDestino: posicaoDestino,
    );
    if (!mounted || sucesso) return sucesso;

    final erro = _viewModel.erroMovimentacao;
    if (erro?.codigo == backend.MovimentacaoDemandaErroCodigo.statusTerminal) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Alteração de status'),
          content: const Text(
            'Para concluir, cancelar, reabrir ou reativar uma demanda, '
            'utilize as ações disponíveis no card da demanda.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    } else {
      _mostrarFeedback(
        erro?.mensagem ??
            _viewModel.erro ??
            'Não foi possível mover a demanda. Tente novamente.',
        erro: true,
      );
    }
    return false;
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
      builder: (context, _) {
        final resultadoBusca = _resultadoBusca();
        return PageScaffold(
          title: 'Demandas',
          route: AppRoutes.demandas,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: TemdasTokens.contentGap),
              child: FilledButton.icon(
                key: const ValueKey('abrir-criar-demanda'),
                onPressed: _viewModel.enviando || _demandasEmStatus.isNotEmpty
                    ? null
                    : _abrirFormulario,
                icon: const Icon(Icons.add),
                label: const Text('Criar demanda'),
              ),
            ),
          ],
          body: ListView(
            key: const ValueKey('demandas-pagina-scroll'),
            padding: _densidade.paddingPagina,
            children: [
              if (_viewModel.erro != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _viewModel.erro!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Demandas salvas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(
                        TemdasTokens.controlRadius,
                      ),
                    ),
                    child: ToggleButtons(
                      isSelected: [
                        for (final densidade in DensidadeDemanda.values)
                          densidade == _densidade,
                      ],
                      onPressed: (index) => setState(
                        () => _densidade = DensidadeDemanda.values[index],
                      ),
                      children: const [
                        Tooltip(
                          message: 'Visualização normal',
                          child: Icon(Icons.density_medium, size: 20),
                        ),
                        Tooltip(
                          message: 'Visualização compacta',
                          child: Icon(Icons.density_small, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Recarregar demandas',
                    onPressed:
                        _viewModel.carregando ||
                            _viewModel.enviando ||
                            _demandasEmStatus.isNotEmpty
                        ? null
                        : _viewModel.carregarDemandas,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              SizedBox(height: _densidade.espacamentoEntreSecoes),
              LayoutBuilder(
                builder: (context, constraints) {
                  final larguraBusca = constraints.maxWidth < 500
                      ? constraints.maxWidth
                      : 420.0;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: larguraBusca,
                        child: TextField(
                          key: const ValueKey('buscar-demandas'),
                          controller: _buscaController,
                          onChanged: _alterarBusca,
                          decoration: InputDecoration(
                            labelText: 'Buscar por ID ou título...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _buscaController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Limpar busca',
                                    onPressed: () {
                                      _buscaController.clear();
                                      _alterarBusca('');
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 190,
                        child: DropdownButtonFormField<backend.Prioridade?>(
                          key: const ValueKey('filtro-prioridade'),
                          initialValue: _filtroPrioridade,
                          decoration: const InputDecoration(
                            labelText: 'Prioridade',
                          ),
                          items: [
                            const DropdownMenuItem<backend.Prioridade?>(
                              value: null,
                              child: Text('Todas'),
                            ),
                            ...backend.Prioridade.values.map(
                              (prioridade) =>
                                  DropdownMenuItem<backend.Prioridade?>(
                                    value: prioridade,
                                    child: Text(_prioridadeLabel(prioridade)),
                                  ),
                            ),
                          ],
                          onChanged: _alterarPrioridadeFiltro,
                        ),
                      ),
                      if (_filtrosAtivos)
                        IconButton(
                          key: const ValueKey('limpar-filtros-demandas'),
                          tooltip: 'Limpar filtros',
                          onPressed: _limparFiltros,
                          icon: const Icon(Icons.filter_alt_off),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: _densidade.espacamentoEntreSecoes),
              if (_viewModel.carregando)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DemandaTree(
                  // Preserva o quadro quando o aviso de erro muda os índices da lista.
                  key: const ValueKey('demandas-arvore'),
                  horizontalController: _quadroHorizontalController,
                  densidade: _densidade,
                  demandas: resultadoBusca.demandas,
                  autoExpandIds: resultadoBusca.autoExpandIds,
                  focoDemandaId: resultadoBusca.focoDemandaId,
                  focoVersao: _filtroVersao,
                  dragHabilitado: !_filtrosAtivos,
                  acoesHabilitadas: !_viewModel.envioGlobalEmAndamento,
                  demandasEmProcessamento: {
                    ..._viewModel.demandasEmProcessamento,
                    if (_viewModel.envioGlobalEmAndamento) ..._demandasEmStatus,
                  },
                  onAlterarStatus: _alterarStatusDemanda,
                  onMover: _moverDemanda,
                  onConcluir: (demanda) => _alterarStatusDemanda(
                    demanda,
                    backend.DemandaStatus.concluida,
                  ),
                  onReabrir: _reabrirDemanda,
                  onEditar: _editarDemanda,
                  onExcluir: _excluirDemanda,
                  onCriarFilha: _criarDemandaFilha,
                  onLancarTempo: _lancarTempo,
                  onMostrarTudo: _mostrarTudo,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormulario(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _tituloController,
            autofocus: true,
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Tempo estimado (horas)',
            ),
            validator: _validarHorasEstimadas,
          ),
          if (_viewModel.erro != null) ...[
            const SizedBox(height: 16),
            Text(
              _viewModel.erro!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
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

class _ResultadoBusca {
  const _ResultadoBusca({
    required this.demandas,
    required this.autoExpandIds,
    required this.focoDemandaId,
  });

  final List<backend.Demanda> demandas;
  final Set<int> autoExpandIds;
  final int? focoDemandaId;
}
