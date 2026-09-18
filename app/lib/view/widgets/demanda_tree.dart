import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../theme/app_theme.dart';
import '../../theme/temdas_semantic_colors.dart';
import '../../view_model/tempo_executado_total.dart';
import '../formatters/demanda_identificacao.dart';
import 'demanda_card.dart';
import 'densidade_demanda.dart';

class DemandaTree extends StatefulWidget {
  const DemandaTree({
    super.key,
    required this.horizontalController,
    required this.demandas,
    required this.acoesHabilitadas,
    required this.onEditar,
    required this.onExcluir,
    required this.onCriarFilha,
    required this.onLancarTempo,
    required this.onMostrarTudo,
    required this.onAlterarStatus,
    required this.onConcluir,
    this.onReabrir,
    this.onMover,
    this.demandasEmProcessamento = const {},
    this.autoExpandIds = const {},
    this.focoDemandaId,
    this.focoVersao = 0,
    this.dragHabilitado = true,
    this.densidade = DensidadeDemanda.normal,
  });

  final List<backend.Demanda> demandas;
  final ScrollController horizontalController;
  final bool acoesHabilitadas;
  final ValueChanged<backend.Demanda> onEditar;
  final ValueChanged<backend.Demanda> onExcluir;
  final ValueChanged<backend.Demanda> onCriarFilha;
  final ValueChanged<backend.Demanda> onLancarTempo;
  final ValueChanged<backend.Demanda> onMostrarTudo;
  final void Function(backend.Demanda, backend.DemandaStatus) onAlterarStatus;
  final ValueChanged<backend.Demanda> onConcluir;
  final ValueChanged<backend.Demanda>? onReabrir;
  final Future<bool> Function(backend.Demanda, backend.DemandaStatus, int)?
  onMover;
  final Set<int> demandasEmProcessamento;
  final Set<int> autoExpandIds;
  final int? focoDemandaId;
  final int focoVersao;
  final bool dragHabilitado;
  final DensidadeDemanda densidade;

  @override
  State<DemandaTree> createState() => _DemandaTreeState();
}

class _DemandaTreeState extends State<DemandaTree> {
  // O mesmo controller governa os detalhes do card e a visibilidade das filhas.
  final _expansoes = <String, ExpansibleController>{};
  final _chavesNos = <String, GlobalKey>{};
  Timer? _destaqueTimer;
  int? _demandaDestacadaId;
  bool _atualizacaoAgendada = false;
  bool _dragAtivo = false;
  ({backend.DemandaStatus status, int posicao})? _dropHover;
  _DemandaMovimentoPendente? _movimentoPendente;

  String _chaveExpansao(backend.Demanda demanda) =>
      'demanda-expansao-${demanda.id ?? demanda.titulo}';

  ExpansibleController _expansaoDe(backend.Demanda demanda) =>
      _expansoes.putIfAbsent(
        _chaveExpansao(demanda),
        () => ExpansibleController()..addListener(_atualizarVisibilidade),
      );

  GlobalKey _chaveDoNo(backend.Demanda demanda) {
    final chave = demanda.id?.toString() ?? demanda.titulo;
    return _chavesNos.putIfAbsent(
      chave,
      () => GlobalKey(debugLabel: 'demanda-foco-$chave'),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _agendarFoco());
  }

  @override
  void didUpdateWidget(covariant DemandaTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focoVersao != widget.focoVersao ||
        oldWidget.focoDemandaId != widget.focoDemandaId) {
      _agendarFoco();
    }
  }

  void _agendarFoco() {
    _destaqueTimer?.cancel();
    _destaqueTimer = null;
    _demandaDestacadaId = null;
    final demandaId = widget.focoDemandaId;
    final versao = widget.focoVersao;
    if (demandaId == null) {
      if (mounted) setState(() {});
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          widget.focoDemandaId != demandaId ||
          widget.focoVersao != versao) {
        return;
      }
      final alvo = _chaveDoNoPorId(demandaId)?.currentContext;
      if (alvo == null) return;
      await Scrollable.ensureVisible(
        alvo,
        alignment: .45,
        duration: Duration.zero,
      );
      if (!mounted ||
          widget.focoDemandaId != demandaId ||
          widget.focoVersao != versao) {
        return;
      }
      setState(() => _demandaDestacadaId = demandaId);
      _destaqueTimer = Timer(const Duration(milliseconds: 1800), () {
        if (mounted && _demandaDestacadaId == demandaId) {
          setState(() => _demandaDestacadaId = null);
        }
      });
    });
  }

  GlobalKey? _chaveDoNoPorId(int id) {
    for (final entry in _chavesNos.entries) {
      if (entry.key == id.toString()) return entry.value;
    }
    return null;
  }

  void _atualizarVisibilidade() {
    if (_atualizacaoAgendada) return;
    _atualizacaoAgendada = true;
    // PageStorage também restaura a expansão durante a montagem de um card.
    // Aguarda o fim do frame para não reconstruir a árvore durante esse build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _atualizacaoAgendada = false;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _destaqueTimer?.cancel();
    for (final controller in _expansoes.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demandas = widget.demandas;
    final temposTotais = calcularTemposExecutadosTotais(demandas);
    final ids = demandas.map((demanda) => demanda.id).whereType<int>().toSet();
    final porPai = <int, List<backend.Demanda>>{};
    for (final demanda in demandas) {
      final paiId = demanda.demandaPaiId;
      if (paiId != null) {
        porPai.putIfAbsent(paiId, () => []).add(demanda);
      }
    }

    final raizes = demandas
        .where(
          (demanda) =>
              demanda.demandaPaiId == null ||
              !ids.contains(demanda.demandaPaiId),
        )
        .toList();
    final idsVisitados = <int>{};
    final porStatus = {
      for (final status in backend.DemandaStatus.values)
        status: <_DemandaNivel>[],
    };

    // A raiz define a coluna de toda a árvore; a visita mantém a ordem,
    // os níveis e o status próprio de cada descendente.
    for (final raiz in raizes) {
      _visitar(
        raiz,
        nivel: 0,
        visivel: true,
        porPai: porPai,
        caminho: const {},
        idsVisitados: idsVisitados,
        nos: porStatus[raiz.status]!,
      );
    }

    // Relações inválidas ou cíclicas não devem fazer uma demanda desaparecer.
    for (final demanda in demandas) {
      final id = demanda.id;
      if (id != null && idsVisitados.contains(id)) continue;
      _visitar(
        demanda,
        nivel: 0,
        visivel: true,
        porPai: porPai,
        caminho: const {},
        idsVisitados: idsVisitados,
        nos: porStatus[demanda.status]!,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final espacamento = widget.densidade.espacamentoEntreColunas;
        final larguraColuna = widget.densidade.larguraColunaPara(
          constraints.maxWidth,
          porStatus.length,
        );

        final possuiOverflow =
            larguraColuna * porStatus.length +
                espacamento * (porStatus.length - 1) >
            constraints.maxWidth;

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Scrollbar(
            key: const ValueKey('demandas-quadro-scrollbar'),
            controller: widget.horizontalController,
            thumbVisibility: possuiOverflow,
            trackVisibility: false,
            interactive: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              key: const ValueKey('demandas-quadro-status'),
              controller: widget.horizontalController,
              scrollDirection: Axis.horizontal,
              // A Row assume a altura da maior coluna. A faixa inferior reserva
              // espaço para a barra no fim do conteúdo, inclusive durante hover.
              padding: EdgeInsets.only(bottom: possuiOverflow ? 18 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final grupo in porStatus.entries) ...[
                    if (grupo.key != porStatus.keys.first)
                      SizedBox(width: espacamento),
                    SizedBox(
                      width: larguraColuna,
                      child: Column(
                        key: ValueKey('demanda-coluna-${grupo.key.name}'),
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _cabecalhoColuna(
                            grupo.key,
                            grupo.value.where((no) => no.nivel == 0).length,
                          ),
                          if (grupo.value.isEmpty)
                            _alvoColunaVazia(grupo.key)
                          else
                            ..._construirUnidades(
                              grupo.key,
                              grupo.value,
                              temposTotais,
                              larguraColuna,
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _cabecalhoColuna(backend.DemandaStatus status, int quantidade) {
    final theme = Theme.of(context);
    final semantic = TemdasSemanticColors.of(context);
    final cor = switch (status) {
      backend.DemandaStatus.aberta => semantic.aberta,
      backend.DemandaStatus.emAndamento => semantic.emAndamento,
      backend.DemandaStatus.pausada => semantic.pausada,
      backend.DemandaStatus.concluida => semantic.concluida,
      backend.DemandaStatus.cancelada => semantic.cancelada,
    };
    return Padding(
      key: ValueKey('demanda-status-${status.name}'),
      padding: EdgeInsets.only(
        top: TemdasTokens.smallGap,
        bottom: widget.densidade.espacamentoEntreCards,
      ),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Icon(Icons.circle, size: 7, color: cor),
            const SizedBox(width: TemdasTokens.smallGap),
            Flexible(
              child: Text(
                _statusLabel(status),
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(width: TemdasTokens.smallGap),
            Text('($quantidade)', style: theme.textTheme.bodySmall),
            const SizedBox(width: TemdasTokens.smallGap),
            const Expanded(child: Divider()),
          ],
        ),
      ),
    );
  }

  void _visitar(
    backend.Demanda demanda, {
    required int nivel,
    required bool visivel,
    required Map<int, List<backend.Demanda>> porPai,
    required Set<int> caminho,
    required Set<int> idsVisitados,
    required List<_DemandaNivel> nos,
  }) {
    final id = demanda.id;
    final proximoCaminho = {...caminho};
    if (id != null) {
      if (!proximoCaminho.add(id)) return;
      idsVisitados.add(id);
    }

    if (visivel) nos.add(_DemandaNivel(demanda: demanda, nivel: nivel));
    final filhasVisiveis =
        visivel &&
        (_expansaoDe(demanda).isExpanded ||
            (id != null && widget.autoExpandIds.contains(id)));
    final filhas = id == null
        ? const <backend.Demanda>[]
        : porPai[id] ?? const [];
    for (final filha in filhas) {
      if (filha.id != null && proximoCaminho.contains(filha.id)) continue;
      _visitar(
        filha,
        nivel: nivel + 1,
        visivel: filhasVisiveis,
        porPai: porPai,
        caminho: proximoCaminho,
        // Mesmo ocultos, descendentes são visitados para não virarem raízes
        // na passagem que recupera relações inválidas ou cíclicas.
        idsVisitados: idsVisitados,
        nos: nos,
      );
    }
  }

  Widget _construirNo(
    _DemandaNivel no,
    int tempoExecutadoTotalMinutos, {
    Widget? dragHandle,
  }) {
    final demanda = no.demanda;
    final emProcessamento = widget.demandasEmProcessamento.contains(demanda.id);
    final nivel = no.nivel;
    final recuo = math.min(
      nivel * widget.densidade.recuoPorNivel,
      widget.densidade.recuoMaximo,
    );

    return Padding(
      key: ValueKey('demanda-tree-node-${demanda.id ?? demanda.titulo}-$nivel'),
      padding: EdgeInsets.only(
        left: recuo,
        bottom: widget.densidade.espacamentoEntreCards,
      ),
      child: KeyedSubtree(
        key: _chaveDoNo(demanda),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: nivel == 0
                ? null
                : Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      width: TemdasTokens.borderWidth,
                    ),
                  ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: nivel == 0 ? 0 : widget.densidade.espacoAposLinhaArvore,
            ),
            child: DemandaCard(
              // A expansão acompanha a demanda quando ela muda de coluna.
              key: PageStorageKey(_chaveExpansao(demanda)),
              expansionController: _expansaoDe(demanda),
              densidade: widget.densidade,
              demanda: demanda,
              tempoExecutadoTotalMinutos: tempoExecutadoTotalMinutos,
              dragHandle: dragHandle,
              destacado: _demandaDestacadaId == demanda.id,
              acoesHabilitadas: widget.acoesHabilitadas && !emProcessamento,
              emProcessamento: emProcessamento,
              onAlterarStatus: (status) =>
                  widget.onAlterarStatus(demanda, status),
              onConcluir: () => widget.onConcluir(demanda),
              onReabrir: widget.onReabrir == null
                  ? null
                  : () => widget.onReabrir!(demanda),
              onEditar: () => widget.onEditar(demanda),
              onExcluir: () => widget.onExcluir(demanda),
              onCriarFilha: () => widget.onCriarFilha(demanda),
              onLancarTempo: () => widget.onLancarTempo(demanda),
              onMostrarTudo: () => widget.onMostrarTudo(demanda),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _construirUnidades(
    backend.DemandaStatus status,
    List<_DemandaNivel> nos,
    Map<int?, int> temposTotais,
    double larguraColuna,
  ) {
    final widgets = <Widget>[];
    var indiceRaiz = 0;
    for (var inicio = 0; inicio < nos.length;) {
      if (nos[inicio].nivel != 0) {
        inicio++;
        continue;
      }
      var fim = inicio + 1;
      while (fim < nos.length && nos[fim].nivel != 0) {
        fim++;
      }
      final unidade = nos.sublist(inicio, fim);
      widgets.add(_zonaDeDrop(status, indiceRaiz));
      widgets.add(_unidadeArrastavel(unidade, temposTotais, larguraColuna));
      indiceRaiz++;
      inicio = fim;
    }
    widgets.add(_zonaDeDrop(status, indiceRaiz));
    return widgets;
  }

  Widget _alvoColunaVazia(backend.DemandaStatus status) {
    const alturaMinima = 128.0;
    return _zonaDeDrop(
      status,
      0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: alturaMinima),
        child: Center(
          child: Text(
            'Nenhuma demanda neste status.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _unidadeArrastavel(
    List<_DemandaNivel> unidade,
    Map<int?, int> temposTotais,
    double larguraColuna,
  ) {
    return _construirConteudo(unidade, temposTotais, larguraColuna);
  }

  Widget _construirConteudo(
    List<_DemandaNivel> unidade,
    Map<int?, int> temposTotais,
    double larguraColuna,
  ) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var index = 0; index < unidade.length; index++)
        _construirNo(
          unidade[index],
          temposTotais[unidade[index].demanda.id] ??
              unidade[index].demanda.tempoExecutadoMinutos,
          dragHandle:
              index == 0 &&
                  widget.onMover != null &&
                  widget.dragHabilitado &&
                  unidade.first.demanda.id != null
              ? _arrastoHandle(
                  unidade.first.demanda,
                  unidade.length,
                  larguraColuna,
                )
              : null,
        ),
    ],
  );

  Widget _arrastoHandle(
    backend.Demanda raiz,
    int quantidadeNos,
    double larguraColuna,
  ) {
    final podeArrastar =
        widget.acoesHabilitadas &&
        widget.dragHabilitado &&
        _movimentoPendente == null &&
        !_dragAtivo &&
        !widget.demandasEmProcessamento.contains(raiz.id);
    return Draggable<_DemandaDragData>(
      key: ValueKey('demanda-drag-handle-${raiz.id}'),
      data: _DemandaDragData(demanda: raiz, status: raiz.status),
      maxSimultaneousDrags: podeArrastar ? 1 : 0,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: _iniciarDrag,
      onDragEnd: (_) => _finalizarDrag(),
      feedback: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: larguraColuna,
          child: _arrastoPreview(raiz, quantidadeNos),
        ),
      ),
      childWhenDragging: Opacity(opacity: .35, child: _visualHandle()),
      child: _visualHandle(),
    );
  }

  Widget _visualHandle() => Tooltip(
    message: 'Arrastar demanda',
    child: Semantics(
      button: true,
      label: 'Arrastar demanda',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: SizedBox.square(
          dimension: 40,
          child: Center(
            child: Icon(
              Icons.drag_indicator,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    ),
  );

  void _iniciarDrag() {
    if (mounted) setState(() => _dragAtivo = true);
  }

  void _finalizarDrag() {
    if (!mounted) return;
    setState(() {
      _dragAtivo = false;
      _dropHover = null;
    });
  }

  Widget _zonaDeDrop(
    backend.DemandaStatus status,
    int posicao, {
    Widget? child,
  }) {
    bool movimentoCarregando() =>
        _movimentoPendente?.statusDestino == status &&
        _movimentoPendente?.posicaoVisual == posicao;
    return DragTarget<_DemandaDragData>(
      key: ValueKey('demanda-drop-${status.name}-$posicao'),
      onWillAcceptWithDetails: (details) {
        if (!_podeReceberDrop(details.data)) return false;
        _atualizarDropHover(status, posicao);
        return true;
      },
      onMove: (details) {
        if (_podeReceberDrop(details.data)) {
          _atualizarDropHover(status, posicao);
        }
      },
      onLeave: (_) {
        if (_dropHover?.status == status) {
          setState(() => _dropHover = null);
        }
      },
      onAcceptWithDetails: (details) {
        _aceitarMovimento(details.data, status, posicao);
      },
      builder: (context, candidates, rejected) {
        final ativo =
            _dropHover?.status == status && _dropHover?.posicao == posicao;
        final estaCarregando = movimentoCarregando();
        final altura = child == null
            ? (_dragAtivo || estaCarregando ? 112.0 : 6.0)
            : null;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: altura,
          margin: const EdgeInsets.symmetric(vertical: 1),
          child: Stack(
            fit: child == null ? StackFit.expand : StackFit.passthrough,
            children: [
              ?child,
              if (ativo || estaCarregando)
                _overlayDoAlvo(carregando: estaCarregando),
            ],
          ),
        );
      },
    );
  }

  bool _podeReceberDrop(_DemandaDragData data) =>
      data.demanda.id != null &&
      widget.onMover != null &&
      _movimentoPendente == null;

  void _atualizarDropHover(backend.DemandaStatus status, int posicao) {
    if (_dropHover?.status == status && _dropHover?.posicao == posicao) {
      return;
    }
    setState(() => _dropHover = (status: status, posicao: posicao));
  }

  void _aceitarMovimento(
    _DemandaDragData data,
    backend.DemandaStatus statusDestino,
    int posicaoVisual,
  ) {
    setState(() => _dropHover = null);
    final origem = data.status;
    final raizesOrigem = widget.demandas
        .where(
          (demanda) => demanda.demandaPaiId == null && demanda.status == origem,
        )
        .toList();
    final indiceOrigem = raizesOrigem.indexWhere(
      (demanda) => demanda.id == data.demanda.id,
    );
    final posicaoDestino =
        origem == statusDestino &&
            indiceOrigem >= 0 &&
            indiceOrigem < posicaoVisual
        ? posicaoVisual - 1
        : posicaoVisual;
    final movimento = _DemandaMovimentoPendente(
      statusDestino: statusDestino,
      posicaoVisual: posicaoVisual,
    );
    setState(() => _movimentoPendente = movimento);
    unawaited(_aguardarMovimento(data, statusDestino, posicaoDestino));
  }

  Future<void> _aguardarMovimento(
    _DemandaDragData data,
    backend.DemandaStatus statusDestino,
    int posicaoDestino,
  ) async {
    try {
      await widget.onMover!(data.demanda, statusDestino, posicaoDestino);
    } finally {
      if (mounted) setState(() => _movimentoPendente = null);
    }
  }

  Widget _overlayDoAlvo({required bool carregando}) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .92),
        border: Border.all(color: colors.primary, width: 2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: carregando
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Movendo demanda...',
                    style: TextStyle(color: colors.onPrimaryContainer),
                  ),
                ],
              )
            : Text(
                'Soltar demanda aqui',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _arrastoPreview(backend.Demanda raiz, int quantidadeNos) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formatarIdentificacaoDemanda(raiz),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (quantidadeNos > 1)
          Text(
            '${quantidadeNos - 1} ${quantidadeNos == 2 ? 'filha' : 'filhas'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    ),
  );

  String _statusLabel(backend.DemandaStatus status) => switch (status) {
    backend.DemandaStatus.aberta => 'Abertas',
    backend.DemandaStatus.emAndamento => 'Em andamento',
    backend.DemandaStatus.pausada => 'Pausadas',
    backend.DemandaStatus.concluida => 'Concluídas',
    backend.DemandaStatus.cancelada => 'Canceladas',
  };
}

class _DemandaNivel {
  const _DemandaNivel({required this.demanda, required this.nivel});

  final backend.Demanda demanda;
  final int nivel;
}

class _DemandaDragData {
  const _DemandaDragData({required this.demanda, required this.status});

  final backend.Demanda demanda;
  final backend.DemandaStatus status;
}

class _DemandaMovimentoPendente {
  const _DemandaMovimentoPendente({
    required this.statusDestino,
    required this.posicaoVisual,
  });

  final backend.DemandaStatus statusDestino;
  final int posicaoVisual;
}
