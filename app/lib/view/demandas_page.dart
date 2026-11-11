import '../ui/theme/tokens.dart';
import 'widgets/sprint_vinculos_editor.dart';
import 'widgets/sprints_da_demanda.dart';
import 'formatters/sprint_apresentacao.dart';
import '../ui/components/app_shell.dart';
import '../ui/components/demand_components.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import 'formatters/demanda_identificacao.dart';
import 'formatters/texto_busca.dart';
import '../view_model/demandas_visualizacao.dart';
import '../view_model/demandas_densidade.dart';
import '../view_model/tempo_executado_total.dart';
import '../view_model/demandas_view_model.dart';
import '../view_model/sprint_view_model.dart';
import 'sprint_page.dart';
import 'demanda_detalhe_page.dart';
import 'widgets/demanda_dialog.dart';
import 'widgets/demanda_status_dialog.dart';
import 'widgets/demanda_tree.dart';
import 'widgets/densidade_demanda.dart';
import 'widgets/log_time_dialog.dart';

class DemandasPage extends StatefulWidget {
  const DemandasPage({super.key, this.viewModel, this.sprintViewModel});

  final DemandasViewModel? viewModel;
  final SprintViewModel? sprintViewModel;

  @override
  State<DemandasPage> createState() => _DemandasPageState();
}

class _DemandasPageState extends State<DemandasPage> {
  final _buscaController = TextEditingController();
  final _quadroHorizontalController = ScrollController();
  late final DemandasViewModel _viewModel;
  late final bool _possuiViewModel;
  late final SprintViewModel _sprintViewModel;
  Map<int, List<backend.Sprint>> _sprintsPorDemanda = const {};
  bool _carregandoSprints = true;
  String? _erroSprints;
  bool _aguardandoConsultaSprint = false;
  bool _selecionando = false;
  bool _vinculandoLote = false;
  final _selecionadas = <int>{};

  backend.Prioridade? _filtroPrioridade;
  final _preferenciaDensidade = DemandasDensidade();
  DensidadeDemanda get _densidade => _preferenciaDensidade.value;
  int?
  _filtroSprint; // null: todas; -1: sem Sprint aberta; demais: SprintDemanda.
  final _visualizacao = DemandasVisualizacao();
  int _filtroVersao = 0;
  final Set<int> _demandasEmStatus = {};

  @override
  void initState() {
    super.initState();
    unawaited(_visualizacao.load());
    unawaited(_preferenciaDensidade.load());
    _possuiViewModel = widget.viewModel == null;
    _viewModel = widget.viewModel ?? DemandasViewModel();
    _viewModel.carregarDemandas();
    _sprintViewModel = widget.sprintViewModel ?? SprintViewModel();
    _sprintViewModel.addListener(_consultarSprintsQuandoLivre);
    unawaited(_carregarSprints());
  }

  @override
  void dispose() {
    _sprintViewModel.removeListener(_consultarSprintsQuandoLivre);
    if (widget.sprintViewModel == null) _sprintViewModel.dispose();
    _visualizacao.dispose();
    _preferenciaDensidade.dispose();
    _buscaController.dispose();
    _quadroHorizontalController.dispose();
    if (_possuiViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _consultarSprintsQuandoLivre() {
    if (!_aguardandoConsultaSprint ||
        _sprintViewModel.carregando ||
        _sprintViewModel.enviando) {
      return;
    }
    _aguardandoConsultaSprint = false;
    unawaited(_carregarSprints());
  }

  Future<void> _carregarSprints() async {
    if (!mounted) return;
    setState(() {
      _carregandoSprints = true;
      _erroSprints = null;
    });
    // Fechar o resumo não cancela uma consulta que já chegou ao repositório.
    if (_sprintViewModel.carregando || _sprintViewModel.enviando) {
      _aguardandoConsultaSprint = true;
      return;
    }
    final vinculos = await _sprintViewModel.carregarSprintsDasDemandas();
    if (!mounted) return;
    setState(() {
      _carregandoSprints = false;
      if (vinculos == null) {
        _erroSprints =
            _sprintViewModel.erro ??
            'Não foi possível consultar as Sprints vinculadas.';
      } else {
        _sprintsPorDemanda = vinculos;
      }
    });
  }

  Widget _vinculoSprint(backend.Demanda demanda) {
    final id = demanda.id;
    if (_selecionando && id != null) {
      return Checkbox(
        key: ValueKey('selecionar-demanda-sprint-$id'),
        semanticLabel: 'Selecionar ${formatarIdentificacaoDemanda(demanda)}',
        value: _selecionadas.contains(id),
        onChanged: _vinculandoLote
            ? null
            : (marcada) => setState(() {
                if (marcada == true) {
                  _selecionadas.add(id);
                } else {
                  _selecionadas.remove(id);
                }
              }),
      );
    }
    if (_carregandoSprints || _erroSprints != null) {
      return Text(
        _carregandoSprints ? 'Consultando Sprint…' : 'Sprint indisponível',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return SprintsDaDemanda(
      compacta: _densidade.isCompacta,
      sprints: _sprintsPorDemanda[demanda.id] ?? const [],
      demandaId: demanda.id,
      onAbrir: (sprint) async {
        if (sprint == null) {
          await Navigator.of(context).pushNamed(AppRoutes.sprint);
        } else {
          await mostrarResumoSprint(
            context,
            sprint: sprint,
            viewModel: _sprintViewModel,
            demandasViewModel: _viewModel,
          );
        }
        if (mounted) await _carregarSprints();
      },
    );
  }

  bool get _filtrosAtivos =>
      _buscaController.text.trim().isNotEmpty || _quantidadeFiltros > 0;

  int get _quantidadeFiltros =>
      (_filtroPrioridade == null ? 0 : 1) + (_filtroSprint == null ? 0 : 1);

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
    setState(() {
      _filtroPrioridade = null;
      _filtroSprint = null;
      _filtroVersao++;
    });
  }

  _ResultadoBusca _resultadoBusca() {
    final busca = normalizarTextoBusca(_buscaController.text.trim());
    final idBuscado = int.tryParse(busca.replaceFirst(RegExp(r'^#'), ''));
    final demandasComPrioridade = _viewModel.demandas.where(
      (demanda) =>
          (_filtroPrioridade == null ||
              demanda.prioridade == _filtroPrioridade) &&
          (_filtroSprint == null ||
              (_filtroSprint == -1
                  ? !(_sprintsPorDemanda[demanda.id] ??
                            const <backend.Sprint>[])
                        .any(sprintAberta)
                  : (_sprintsPorDemanda[demanda.id] ?? const <backend.Sprint>[])
                        .any((s) => sprintAberta(s) && s.id == _filtroSprint))),
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
          .where(
            (demanda) =>
                normalizarTextoBusca(demanda.titulo).contains(busca) ||
                (demanda.id?.toString().contains(busca.replaceFirst('#', '')) ??
                    false),
          )
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
      final visitados = <int>{};
      while (true) {
        if (atual.id != null && !visitados.add(atual.id!)) break;
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
    final criada = await showDialog<backend.Demanda>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CriarDemandaDialog(
        viewModel: _viewModel,
        sprintViewModel: _sprintViewModel,
      ),
    );
    if (criada != null && mounted) {
      await _carregarSprints();
      if (mounted) _mostrarFeedback('Demanda criada com sucesso.', erro: false);
    }
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
        sprintViewModel: _sprintViewModel,
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
    if (atualizada) await _carregarSprints();
    if (!mounted) return;
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
            observacao: dados.observacao,
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

  Future<void> _mostrarTudo(backend.Demanda demanda) async {
    final id = demanda.id;
    if (id == null) {
      _mostrarFeedback('A demanda não possui um ID válido.', erro: true);
      return;
    }
    await mostrarDetalhesDemandaDialog(
      context,
      id,
      onVinculosAlterados: _carregarSprints,
    );
    if (!mounted) return;
    await _viewModel.carregarDemandas();
    if (mounted) await _carregarSprints();
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

  Future<void> _vincularLote(List<int> ids) async {
    if (_vinculandoLote || ids.isEmpty) return;
    setState(() => _vinculandoLote = true);
    try {
      final sprint = await selecionarSprintParaVincular(
        context,
        viewModel: _sprintViewModel,
        descricao:
            'Vincular ${ids.length} Demandas selecionadas. O vínculo pode incluir suas filhas.',
      );
      if (!mounted || sprint == null) return;
      final sucesso = await _sprintViewModel.vincularDemandas(
        sprintId: sprint.id!,
        demandaIds: ids,
      );
      if (!mounted) return;
      final erro = _sprintViewModel.erro;
      if (sucesso) {
        setState(() {
          _selecionadas.clear();
          _selecionando = false;
        });
      }
      await _carregarSprints();
      if (mounted) {
        _mostrarFeedback(
          sucesso
              ? 'Demandas vinculadas à ${nomeSprint(sprint.nome)}.'
              : erro ?? 'Não foi possível confirmar os vínculos.',
          erro: !sucesso,
        );
      }
    } finally {
      if (mounted) setState(() => _vinculandoLote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _viewModel,
        _visualizacao,
        _preferenciaDensidade,
      ]),
      builder: (context, _) {
        final resultadoBusca = _resultadoBusca();
        final selecionadasVisiveis = resultadoBusca.demandas
            .map((d) => d.id)
            .whereType<int>()
            .where(_selecionadas.contains)
            .toList();
        final lista = _visualizacao.value == VisualizacaoDemandas.lista;
        final mobile = MediaQuery.sizeOf(context).width < 600;
        final tree = DemandaTree(
          // Preserva o quadro quando o aviso de erro muda os índices da lista.
          key: const ValueKey('demandas-arvore'),
          horizontalController: _quadroHorizontalController,
          densidade: _densidade,
          lista: _visualizacao.value == VisualizacaoDemandas.lista,
          sprintBuilder: _vinculoSprint,
          demandas: resultadoBusca.demandas,
          temposExecutadosTotais: calcularTemposExecutadosTotais(
            _viewModel.demandas,
          ),
          autoExpandIds: resultadoBusca.autoExpandIds,
          focoDemandaId: resultadoBusca.focoDemandaId,
          focoVersao: _filtroVersao,
          dragHabilitado: !_filtrosAtivos && !_selecionando,
          acoesHabilitadas:
              !_viewModel.envioGlobalEmAndamento && !_viewModel.carregando,
          demandasEmProcessamento: {
            ..._viewModel.demandasEmProcessamento,
            if (_viewModel.envioGlobalEmAndamento) ..._demandasEmStatus,
          },
          onAlterarStatus: _alterarStatusDemanda,
          onMover: _moverDemanda,
          onConcluir: (demanda) =>
              _alterarStatusDemanda(demanda, backend.DemandaStatus.concluida),
          onReabrir: _reabrirDemanda,
          onEditar: _editarDemanda,
          onExcluir: _excluirDemanda,
          onCriarFilha: _criarDemandaFilha,
          onLancarTempo: _lancarTempo,
          onMostrarTudo: _mostrarTudo,
        );
        return AppShell(
          route: AppRoutes.demandas,
          header: _toolbar(),
          fab: AppFab(
            onPressed: _viewModel.enviando || _demandasEmStatus.isNotEmpty
                ? null
                : _abrirFormulario,
          ),
          body: Padding(
            padding: EdgeInsets.fromLTRB(
              mobile ? 8 : 16,
              8,
              mobile ? 8 : 16,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_viewModel.erro != null)
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(_viewModel.erro!),
                      TextButton(
                        onPressed: _refresh,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                if (_carregandoSprints)
                  const LinearProgressIndicator(
                    key: ValueKey('carregando-sprints-demandas'),
                  ),
                if (_erroSprints != null)
                  ListTile(
                    leading: const Icon(Symbols.info_rounded),
                    title: Text(_erroSprints!),
                    trailing: IconButton(
                      tooltip: 'Tentar consultar Sprints novamente',
                      onPressed: _carregarSprints,
                      icon: const Icon(Symbols.refresh_rounded),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _vinculandoLote
                          ? null
                          : () => setState(() {
                              _selecionando = !_selecionando;
                              _selecionadas.clear();
                            }),
                      icon: Icon(_selecionando ? Icons.close : Icons.checklist),
                      label: Text(
                        _selecionando
                            ? 'Cancelar seleção'
                            : 'Selecionar Demandas',
                      ),
                    ),
                    if (_selecionando)
                      FilledButton(
                        onPressed:
                            _vinculandoLote ||
                                _carregandoSprints ||
                                selecionadasVisiveis.isEmpty
                            ? null
                            : () => _vincularLote(selecionadasVisiveis),
                        child: Text(
                          'Vincular à Sprint (${selecionadasVisiveis.length})',
                        ),
                      ),
                  ],
                ),
                if (lista && resultadoBusca.demandas.isNotEmpty)
                  DemandTableHeader(densidade: _densidade),
                Expanded(
                  child: _viewModel.carregando && _viewModel.demandas.isEmpty
                      ? (lista
                            ? Column(
                                children: [
                                  for (var i = 0; i < 8; i++) SkeletonRow(),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < (mobile ? 1 : 3); i++)
                                      const Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(8),
                                          child: Column(
                                            children: [
                                              SkeletonCard(),
                                              SkeletonCard(),
                                              SkeletonCard(),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ))
                      : resultadoBusca.demandas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _filtrosAtivos
                                    ? 'Nenhuma demanda encontrada'
                                    : 'Nenhuma demanda ainda.',
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: _filtrosAtivos
                                    ? () {
                                        _buscaController.clear();
                                        _limparFiltros();
                                      }
                                    : _abrirFormulario,
                                child: Text(
                                  _filtrosAtivos
                                      ? 'Limpar busca'
                                      : 'Criar demanda',
                                ),
                              ),
                            ],
                          ),
                        )
                      : lista
                      ? SingleChildScrollView(
                          key: const ValueKey('demandas-pagina-scroll'),
                          padding: EdgeInsets.only(bottom: mobile ? 80 : 16),
                          child: tree,
                        )
                      : tree,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _refresh() async {
    await _viewModel.carregarDemandas();
    if (mounted) await _carregarSprints();
  }

  Widget _toolbar() {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final t = AppTokens.of(context);
    final larguraRotulo = 80 * MediaQuery.textScalerOf(context).scale(12) / 12;
    ButtonSegment<VisualizacaoDemandas> segmento(
      VisualizacaoDemandas value,
      String texto,
      IconData icon,
    ) => ButtonSegment(
      value: value,
      tooltip: texto,
      icon: mobile ? Icon(icon, size: 16) : null,
      label: mobile
          ? null
          : ConstrainedBox(
              constraints: BoxConstraints(minWidth: larguraRotulo),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 8),
                  Text(texto, softWrap: false),
                ],
              ),
            ),
    );
    return PageHeader(
      count: _viewModel.demandas.length,
      search: SearchField(
        controller: _buscaController,
        onChanged: _alterarBusca,
        onClear: () {
          _buscaController.clear();
          _alterarBusca('');
        },
      ),
      filters: OutlinedButton.icon(
        key: const ValueKey('abrir-filtros-demandas'),
        style: t.darkContrast
            ? ButtonStyle(
                iconColor: WidgetStatePropertyAll(t.secondaryLabel),
                side: WidgetStateProperty.resolveWith(
                  (states) => BorderSide(
                    color: states.contains(WidgetState.focused)
                        ? AppTokens.accent
                        : t.controlBorder,
                  ),
                ),
              )
            : null,
        onPressed: _abrirFiltros,
        icon: const Icon(Symbols.filter_alt_rounded, size: 16),
        label: Text(
          _quantidadeFiltros == 0 ? 'Filtros' : 'Filtros ($_quantidadeFiltros)',
        ),
      ),
      toggle: SegmentedToggle<VisualizacaoDemandas>(
        value: _visualizacao.value,
        segments: [
          segmento(
            VisualizacaoDemandas.kanban,
            'Kanban',
            Symbols.view_kanban_rounded,
          ),
          segmento(
            VisualizacaoDemandas.lista,
            'Lista',
            Symbols.view_list_rounded,
          ),
        ],
        onChanged: (values) async {
          final saved = await _visualizacao.select(values.single);
          if (!saved && mounted) {
            _mostrarFeedback(
              'Não foi possível salvar a visualização neste dispositivo.',
              erro: true,
            );
          }
        },
      ),
      create: AppButton(
        key: const ValueKey('abrir-criar-demanda'),
        label: 'Criar demanda',
        icon: Symbols.add_rounded,
        primary: true,
        onPressed: _viewModel.enviando || _demandasEmStatus.isNotEmpty
            ? null
            : _abrirFormulario,
      ),
      density: PopupMenuButton<DensidadeDemanda>(
        tooltip: 'Densidade dos cards',
        initialValue: _densidade,
        icon: Icon(
          Symbols.density_small_rounded,
          size: 16,
          color: t.darkContrast ? t.secondaryLabel : null,
        ),
        onSelected: (v) async {
          final saved = await _preferenciaDensidade.select(v);
          if (!saved && mounted) {
            _mostrarFeedback(
              'Não foi possível salvar a densidade neste dispositivo.',
              erro: true,
            );
          }
        },
        itemBuilder: (_) => [
          for (final v in DensidadeDemanda.values)
            CheckedPopupMenuItem(
              value: v,
              checked: _densidade == v,
              child: Text(
                v.isCompacta ? 'Visualização compacta' : 'Visualização normal',
              ),
            ),
        ],
      ),
      refresh: RefreshAction(
        loading: _viewModel.carregando,
        onPressed:
            _viewModel.carregando ||
                _viewModel.enviando ||
                _demandasEmStatus.isNotEmpty
            ? null
            : _refresh,
      ),
    );
  }

  Future<void> _abrirFiltros() => showDialog<void>(
    context: context,
    builder: (dialogContext) => ListenableBuilder(
      listenable: _sprintViewModel,
      builder: (context, _) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: const Text('Filtrar Demandas'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<backend.Prioridade?>(
                    dropdownColor: AppTokens.of(context).dropdownSurface,
                    key: ValueKey('filtro-prioridade-$_filtroPrioridade'),
                    initialValue: _filtroPrioridade,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Prioridade'),
                    items: [
                      const DropdownMenuItem<backend.Prioridade?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      for (final prioridade in backend.Prioridade.values)
                        DropdownMenuItem(
                          value: prioridade,
                          child: Text(_prioridadeLabel(prioridade)),
                        ),
                    ],
                    onChanged: (value) {
                      _alterarPrioridadeFiltro(value);
                      updateDialog(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    dropdownColor: AppTokens.of(context).dropdownSurface,
                    key: ValueKey('filtro-sprint-$_filtroSprint'),
                    initialValue: _filtroSprint,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Sprint aberta',
                      helperText: _carregandoSprints
                          ? 'Consultando vínculos…'
                          : _erroSprints != null
                          ? 'Vínculos indisponíveis. Tente novamente na página.'
                          : null,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Todas'),
                      ),
                      const DropdownMenuItem<int?>(
                        value: -1,
                        child: Text('Sem Sprint'),
                      ),
                      if (_filtroSprint != null &&
                          _filtroSprint != -1 &&
                          !_sprintsDisponiveis.any(
                            (s) => s.id == _filtroSprint,
                          ))
                        DropdownMenuItem(
                          value: _filtroSprint,
                          child: const Text('Sprint sem vínculos abertos'),
                        ),
                      for (final sprint in _sprintsDisponiveis)
                        DropdownMenuItem(
                          value: sprint.id,
                          child: Text(
                            nomeSprint(sprint.nome),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _carregandoSprints || _erroSprints != null
                        ? null
                        : (value) {
                            setState(() {
                              _filtroSprint = value;
                              _filtroVersao++;
                            });
                            updateDialog(() {});
                          },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              key: const ValueKey('limpar-filtros-demandas'),
              onPressed: _quantidadeFiltros == 0
                  ? null
                  : () {
                      _limparFiltros();
                      updateDialog(() {});
                    },
              child: const Text('Limpar filtros'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Concluir'),
            ),
          ],
        ),
      ),
    ),
  );

  List<backend.Sprint> get _sprintsDisponiveis {
    final porId = {
      for (final sprint in _sprintViewModel.sprints)
        if (sprint.status == backend.SprintStatus.planejada ||
            sprint.status == backend.SprintStatus.ativa)
          sprint.id: sprint,
      for (final lista in _sprintsPorDemanda.values)
        for (final sprint in lista.where(sprintAberta)) sprint.id: sprint,
    };
    final sprints = porId.values.toList()
      ..sort(
        (a, b) => normalizarTextoBusca(
          a.nome,
        ).compareTo(normalizarTextoBusca(b.nome)),
      );
    return sprints;
  }
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
