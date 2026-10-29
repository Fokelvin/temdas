import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../view_model/largura_painel_demanda.dart';

/// O conteúdo permanece montado durante arraste, ampliação e resize da viewport.
class DemandaPainelRedimensionavel extends StatefulWidget {
  const DemandaPainelRedimensionavel({
    super.key,
    required this.title,
    required this.child,
    required this.onClose,
    this.actions = const [],
  });
  final String title;
  final Widget child;
  final VoidCallback onClose;
  final List<Widget> actions;
  @override
  State<DemandaPainelRedimensionavel> createState() => _PainelState();
}

class _PainelState extends State<DemandaPainelRedimensionavel> {
  final _largura = LarguraPainelDemanda();
  bool _focoBorda = false;
  double _arraste = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_largura.load());
  }

  @override
  void dispose() {
    _largura.dispose();
    super.dispose();
  }

  Future<void> _salvar(Future<bool> saving) async {
    if (!await saving && mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a largura neste dispositivo.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListenableBuilder(
      listenable: _largura,
      builder: (context, _) {
        final viewport = constraints.maxWidth;
        final mobile = viewport < LarguraPainelDemanda.breakpoint;
        final width = _largura.paraViewport(viewport);
        final ampliado =
            (width - LarguraPainelDemanda.maxima(viewport)).abs() < 1;
        void ajustar(double value) {
          _largura.ajustar(value, viewport);
          unawaited(_salvar(_largura.salvar()));
        }

        return Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: width,
            height: constraints.maxHeight,
            child: Material(
              key: const ValueKey('demanda-detalhe-dialog'),
              color: Theme.of(context).colorScheme.surface,
              elevation: 12,
              child: Stack(
                children: [
                  SafeArea(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                              ...widget.actions,
                              if (!mobile)
                                IconButton(
                                  key: const ValueKey('ampliar-painel-demanda'),
                                  tooltip: ampliado
                                      ? 'Reduzir painel'
                                      : 'Ampliar painel',
                                  icon: Icon(
                                    ampliado
                                        ? Icons.compress
                                        : Icons.swap_horiz,
                                  ),
                                  onPressed: () =>
                                      _salvar(_largura.alternar(viewport)),
                                ),
                              IconButton(
                                tooltip: 'Fechar detalhes',
                                onPressed: widget.onClose,
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: widget.child),
                      ],
                    ),
                  ),
                  if (!mobile)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 12,
                      child: Semantics(
                        label: 'Largura do painel',
                        value: '${width.round()} pixels',
                        increasedValue:
                            '${LarguraPainelDemanda.limitar(width + 20, viewport).round()} pixels',
                        decreasedValue:
                            '${LarguraPainelDemanda.limitar(width - 20, viewport).round()} pixels',
                        slider: true,
                        onIncrease: () => ajustar(width + 20),
                        onDecrease: () => ajustar(width - 20),
                        child: Focus(
                          onFocusChange: (value) =>
                              setState(() => _focoBorda = value),
                          onKeyEvent: (_, event) {
                            if (event is! KeyDownEvent &&
                                event is! KeyRepeatEvent) {
                              return KeyEventResult.ignored;
                            }
                            final key = event.logicalKey;
                            if (key == LogicalKeyboardKey.arrowLeft) {
                              ajustar(width + 20);
                            } else if (key == LogicalKeyboardKey.arrowRight) {
                              ajustar(width - 20);
                            } else if (key == LogicalKeyboardKey.home) {
                              ajustar(LarguraPainelDemanda.padrao);
                            } else if (key == LogicalKeyboardKey.end) {
                              ajustar(LarguraPainelDemanda.maxima(viewport));
                            } else {
                              return KeyEventResult.ignored;
                            }
                            return KeyEventResult.handled;
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeLeftRight,
                            child: GestureDetector(
                              key: const ValueKey(
                                'redimensionar-painel-demanda',
                              ),
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart: (_) => _arraste = width,
                              onHorizontalDragUpdate: (details) {
                                _arraste = LarguraPainelDemanda.limitar(
                                  _arraste - details.delta.dx,
                                  viewport,
                                );
                                _largura.ajustar(_arraste, viewport);
                              },
                              onHorizontalDragEnd: (_) =>
                                  _salvar(_largura.salvar()),
                              onHorizontalDragCancel: () =>
                                  _salvar(_largura.salvar()),
                              child: Center(
                                child: Container(
                                  width: _focoBorda ? 3 : 1,
                                  color: _focoBorda
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
