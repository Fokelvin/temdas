import '../../ui/components/demand_components.dart';
import '../../ui/theme/tokens.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../../theme/app_theme.dart';
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
    this.sprintBuilder,
    this.lista = false,
    this.temposExecutadosTotais,
    this.onMover,
    this.demandasEmProcessamento = const {},
    this.autoExpandIds = const {},
    this.focoDemandaId,
    this.focoVersao = 0,
    this.dragHabilitado = true,
    this.densidade = DensidadeDemanda.normal,
  });

  final bool lista;
  final Map<int, int>? temposExecutadosTotais;
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
  final Widget Function(backend.Demanda)? sprintBuilder;

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
  final _gruposRecolhidos = <backend.DemandaStatus>{};
  backend.DemandaStatus? _abaAtiva;
  final _tabKeys = {
    for (final s in backend.DemandaStatus.values) s: GlobalKey(),
  };
  void _selecionarAba(backend.DemandaStatus s) {
    setState(() => _abaAtiva = s);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alvo = _tabKeys[s]?.currentContext;
      if (alvo != null) {
        Scrollable.ensureVisible(
          alvo,
          alignment: .5,
          duration: AppTokens.motion(context),
        );
      }
    });
  }

  ({backend.DemandaStatus status, int posicao})? _dropHover;
  _DemandaMovimentoPendente? _movimentoPendente;

  DensidadeDemanda get _densidade =>
      widget.lista ? DensidadeDemanda.compacta : widget.densidade;

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
    if (oldWidget.focoVersao != widget.focoVersao) _abaAtiva = null;
    if (oldWidget.lista != widget.lista ||
        oldWidget.focoVersao != widget.focoVersao ||
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
    final temposTotais =
        widget.temposExecutadosTotais ??
        calcularTemposExecutadosTotais(demandas);
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

    if (widget.lista) {
      return Column(
        key: const ValueKey('demandas-lista-status'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final grupo in porStatus.entries.where(
            (g) => g.value.isNotEmpty,
          )) ...[
            GroupHeader(
              status: grupo.key,
              count: grupo.value.where((no) => no.nivel == 0).length,
              collapsed: _gruposRecolhidos.contains(grupo.key),
              onTap: () => setState(() {
                if (!_gruposRecolhidos.remove(grupo.key)) {
                  _gruposRecolhidos.add(grupo.key);
                }
              }),
            ),
            if (!_gruposRecolhidos.contains(grupo.key))
              for (final no in grupo.value)
                _construirNo(
                  no,
                  temposTotais[no.demanda.id] ??
                      no.demanda.tempoExecutadoMinutos,
                ),
          ],
          EmptyStatusesLine(
            statuses: porStatus.entries
                .where((g) => g.value.isEmpty)
                .map((g) => g.key)
                .toList(),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = MediaQuery.sizeOf(context).width < 600;
        final active =
            _abaAtiva ??
            (porStatus[backend.DemandaStatus.emAndamento]!.isNotEmpty
                ? backend.DemandaStatus.emAndamento
                : porStatus.entries
                      .firstWhere(
                        (g) => g.value.isNotEmpty,
                        orElse: () => porStatus.entries.first,
                      )
                      .key);
        if (mobile) {
          final entries = porStatus[active]!;
          return Column(
            children: [
              StatusTabs(
                children: [
                  for (final s in porStatus.keys)
                    Padding(
                      key: _tabKeys[s],
                      padding: const EdgeInsets.only(right: 8, bottom: 8),
                      child: DragTarget<_DemandaDragData>(
                        onWillAcceptWithDetails: (d) =>
                            _podeReceberDrop(d.data),
                        onAcceptWithDetails: (d) {
                          _selecionarAba(s);
                          _aceitarMovimento(
                            d.data,
                            s,
                            porStatus[s]!.where((n) => n.nivel == 0).length,
                          );
                        },
                        builder: (context, candidates, rejected) => InkWell(
                          onTap: () => _selecionarAba(s),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 44),
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: s == active
                                  ? AppTokens.of(context).accentSoft
                                  : null,
                              border: Border.all(
                                color: candidates.isNotEmpty || s == active
                                    ? AppTokens.accent
                                    : AppTokens.of(context).borderStrong,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                StatusDot(color: statusColor(s), size: 6),
                                const SizedBox(width: 8),
                                Text(
                                  statusLabel(s),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${porStatus[s]!.where((n) => n.nivel == 0).length}',
                                  style: TextStyle(
                                    color: AppTokens.of(context).text2,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity.abs() < 100) return;
                    final index = backend.DemandaStatus.values.indexOf(active);
                    final next = (index + (velocity < 0 ? 1 : -1)).clamp(
                      0,
                      backend.DemandaStatus.values.length - 1,
                    );
                    _selecionarAba(backend.DemandaStatus.values[next]);
                  },
                  child: SingleChildScrollView(
                    key: const ValueKey('demandas-quadro-status'),
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: entries.isEmpty
                          ? [_alvoColunaVazia(active)]
                          : _construirUnidades(
                              active,
                              entries,
                              temposTotais,
                              constraints.maxWidth,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }
        final gap = MediaQuery.sizeOf(context).width < 1024 ? 8.0 : 12.0;
        final emptyCount = porStatus.values.where((g) => g.isEmpty).length;
        final filledCount = porStatus.length - emptyCount;
        final width =
            ((constraints.maxWidth - emptyCount * 44 - gap * 4) /
                    math.max(1, filledCount))
                .clamp(
                  MediaQuery.sizeOf(context).width < 1024 ? 230.0 : 260.0,
                  360.0,
                );
        final stops = <double>[];
        var offset = 0.0;
        for (final g in porStatus.entries) {
          stops.add(offset);
          offset += (g.value.isEmpty && _dropHover?.status != g.key ? 44 : width) + gap;
        }
        return Scrollbar(
          key: const ValueKey('demandas-quadro-scrollbar'),
          controller: widget.horizontalController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            key: const ValueKey('demandas-quadro-status'),
            controller: widget.horizontalController,
            scrollDirection: Axis.horizontal,
            physics: ColumnSnapPhysics(stops: stops),
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final grupo in porStatus.entries) ...[
                  if (grupo.key != porStatus.keys.first) SizedBox(width: gap),
                  _colunaDoQuadro(grupo.key, grupo.value, temposTotais, width),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colunaDoQuadro(
    backend.DemandaStatus status,
    List<_DemandaNivel> nos,
    Map<int?, int> tempos,
    double width,
  ) {
    final collapsed = nos.isEmpty && _dropHover?.status != status;
    final visualWidth = collapsed ? 44.0 : width;
    final column = AnimatedContainer(
      key: ValueKey('demanda-coluna-${status.name}'),
      width: visualWidth,
      duration: AppTokens.motion(context, 200),
      curve: AppTokens.curve,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: visualWidth,
          maxWidth: visualWidth,
          child: KanbanColumn(
            status: status,
            count: nos.where((n) => n.nivel == 0).length,
            collapsed: collapsed,
            target: _dropHover?.status == status,
            child: nos.isEmpty
                ? const SizedBox(height: 320)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _construirUnidades(status, nos, tempos, width),
                  ),
          ),
        ),
      ),
    );
    // Keep the target mounted while the empty rail expands under the pointer.
    return nos.isEmpty ? _zonaDeDrop(status, 0, child: column) : column;
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
      nivel * _densidade.recuoPorNivel,
      _densidade.recuoMaximo,
    );

    return Padding(
      key: ValueKey('demanda-tree-node-${demanda.id ?? demanda.titulo}-$nivel'),
      padding: EdgeInsets.only(
        left: widget.lista ? math.min(nivel * 20.0, 60) : recuo,
        bottom: widget.lista ? 0 : 8,
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
              left: nivel == 0 ? 0 : _densidade.espacoAposLinhaArvore,
            ),
            child: DemandaCard(
              redesign: true,
              // A expansão acompanha a demanda quando ela muda de coluna.
              key: PageStorageKey(_chaveExpansao(demanda)),
              expansionController: _expansaoDe(demanda),
              densidade: _densidade,
              emLista: widget.lista,
              demanda: demanda,
              sprintContexto: widget.sprintBuilder?.call(demanda),
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

  Widget _alvoColunaVazia(backend.DemandaStatus status) => _zonaDeDrop(
    status,
    0,
    child: const SizedBox(height: 320, width: double.infinity),
  );

  Widget _unidadeArrastavel(
    List<_DemandaNivel> unidade,
    Map<int?, int> temposTotais,
    double larguraColuna,
  ) {
    final content = _construirConteudo(unidade, temposTotais, larguraColuna);
    final raiz = unidade.first.demanda;
    if (MediaQuery.sizeOf(context).width >= 600 ||
        widget.onMover == null ||
        !widget.dragHabilitado ||
        raiz.id == null) {
      return content;
    }
    return LongPressDraggable<_DemandaDragData>(
      key: ValueKey('demanda-long-press-${raiz.id}'),
      data: _DemandaDragData(demanda: raiz, status: raiz.status),
      maxSimultaneousDrags:
          widget.acoesHabilitadas &&
              _movimentoPendente == null &&
              !_dragAtivo &&
              !widget.demandasEmProcessamento.contains(raiz.id)
          ? 1
          : 0,
      onDragStarted: _iniciarDrag,
      onDragEnd: (_) => _finalizarDrag(),
      feedback: _feedback(raiz, unidade.length, larguraColuna),
      child: content,
    );
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
    if (MediaQuery.sizeOf(context).width < 600) return _visualHandle();
    return Draggable<_DemandaDragData>(
      key: ValueKey('demanda-drag-handle-${raiz.id}'),
      data: _DemandaDragData(demanda: raiz, status: raiz.status),
      maxSimultaneousDrags: podeArrastar ? 1 : 0,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: _iniciarDrag,
      onDragEnd: (_) => _finalizarDrag(),
      feedback: _feedback(raiz, quantidadeNos, larguraColuna),
      childWhenDragging: Opacity(opacity: .35, child: _visualHandle()),
      child: _visualHandle(),
    );
  }

  Widget _feedback(backend.Demanda raiz, int count, double width) =>
      Transform.rotate(
        angle: MediaQuery.disableAnimationsOf(context) ? 0 : .02094,
        child: Material(
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: .35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTokens.accent),
          ),
          color: AppTokens.of(context).bg,
          child: SizedBox(width: width, child: _arrastoPreview(raiz, count)),
        ),
      );

  Widget _visualHandle() => Tooltip(
    message: 'Arrastar demanda',
    child: Semantics(
      button: true,
      label: 'Arrastar demanda',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: SizedBox.square(
          dimension: MediaQuery.sizeOf(context).width < 1024 ? 44 : 24,
          child: Center(
            child: Icon(
              Symbols.drag_indicator_rounded,
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
            ? (_dragAtivo || estaCarregando ? 44.0 : 4.0)
            : null;
        return AnimatedContainer(
          duration: AppTokens.motion(context, 120),
          height: altura,
          margin: const EdgeInsets.symmetric(vertical: 0),
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
    return CustomPaint(
      foregroundPainter: const DashedOutline(),
      child: AnimatedContainer(
        duration: AppTokens.motion(context, 100),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: .92),

          borderRadius: BorderRadius.circular(8),
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
                    Flexible(
                      child: Text(
                        'Movendo demanda...',
                        style: TextStyle(color: colors.onPrimaryContainer),
                      ),
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
