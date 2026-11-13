import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart';

class TodoEditor extends StatefulWidget {
  const TodoEditor({
    super.key,
    required this.todo,
    required this.fontSize,
    required this.enabled,
    required this.onChanged,
  });

  final Todo todo;
  final double fontSize;
  final bool enabled;
  final ValueChanged<List<TodoLinha>> onChanged;

  @override
  State<TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends State<TodoEditor> {
  static final _random = Random.secure();
  late List<TodoLinha> _linhas = _doCartao();
  ({String id, int offset})? _foco;
  _CampoLinhasState? _ativo;

  static TodoLinha _linha(String texto, {bool checklist = false}) => TodoLinha(
    id: List.generate(
      16,
      (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join(),
    tipo: checklist ? TodoTipoLinha.checklist : TodoTipoLinha.texto,
    texto: texto,
    marcado: false,
  );

  List<TodoLinha> _doCartao() =>
      widget.todo.linhas ??
      _quebrar(widget.todo.conteudo).map((texto) => _linha(texto)).toList();

  @override
  void didUpdateWidget(covariant TodoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.todo.conteudo != widget.todo.conteudo ||
        oldWidget.todo.linhas != widget.todo.linhas) {
      if (!identical(_linhas, widget.todo.linhas)) _linhas = _doCartao();
    }
  }

  void _substituir(
    int inicio,
    int fim,
    List<TodoLinha> novas, {
    TodoLinha? focar,
    int offset = 0,
  }) {
    final linhas = [..._linhas]..replaceRange(inicio, fim, novas);
    setState(() {
      _linhas = linhas;
      if (focar != null) _foco = (id: focar.id, offset: offset);
    });
    widget.onChanged(linhas);
  }

  void _editarTexto(int inicio, int fim, String texto, int caret) {
    final atuais = _linhas.sublist(inicio, fim);
    final partes = _quebrar(texto);
    // Match the unchanged tail after an insertion/deletion so its IDs survive.
    var prefixo = 0;
    while (prefixo < atuais.length &&
        prefixo < partes.length &&
        atuais[prefixo].texto == partes[prefixo]) {
      prefixo++;
    }
    var cauda = 0;
    while (cauda < atuais.length - prefixo &&
        cauda < partes.length - prefixo &&
        atuais[atuais.length - 1 - cauda].texto ==
            partes[partes.length - 1 - cauda]) {
      cauda++;
    }
    final novas = <TodoLinha>[
      for (var i = 0; i < partes.length - cauda; i++)
        i < atuais.length - cauda
            ? atuais[i].copyWith(texto: partes[i])
            : _linha(partes[i]),
      ...atuais.skip(atuais.length - cauda),
    ];
    _substituir(
      inicio,
      fim,
      novas,
      focar: novas.first.id == atuais.first.id ? null : novas.first,
      offset: caret,
    );
  }

  void _editarItem(int index, String texto) {
    final atual = _linhas[index];
    final partes = _quebrar(texto);
    if (partes.length == 1) {
      _substituir(index, index + 1, [atual.copyWith(texto: texto)]);
      return;
    }
    if (atual.texto.isEmpty && partes.every((parte) => parte.isEmpty)) {
      _converterItem(index);
      return;
    }
    final novas = [
      atual.copyWith(texto: partes.first),
      for (final parte in partes.skip(1)) _linha(parte, checklist: true),
    ];
    _substituir(index, index + 1, novas, focar: novas.last);
  }

  void _converterItem(int index) {
    final texto = _linhas[index].copyWith(
      tipo: TodoTipoLinha.texto,
      marcado: false,
    );
    _substituir(index, index + 1, [texto], focar: texto);
  }

  void _converterTexto(int inicio, int fim, TextSelection selecao) {
    final atuais = _linhas.sublist(inicio, fim);
    var offset = 0;
    TodoLinha? ultima;
    final novas = <TodoLinha>[];
    for (final linha in atuais) {
      final limite = offset + linha.texto.length;
      final selecionada =
          selecao.isValid &&
          (selecao.isCollapsed
              ? selecao.start >= offset && selecao.start <= limite
              : selecao.start < limite && selecao.end > offset);
      if (selecionada && linha.texto.trim().isNotEmpty) {
        ultima = linha.copyWith(tipo: TodoTipoLinha.checklist);
        novas.add(ultima);
      } else {
        novas.add(linha);
      }
      offset = limite + 1;
    }
    if (ultima != null) {
      _substituir(
        inicio,
        fim,
        novas,
        focar: ultima,
        offset: ultima.texto.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final campos = <Widget>[];
    for (var inicio = 0; inicio < _linhas.length;) {
      final primeira = _linhas[inicio];
      final checklist = primeira.tipo == TodoTipoLinha.checklist;
      var fim = inicio + 1;
      if (!checklist) {
        while (fim < _linhas.length &&
            _linhas[fim].tipo == TodoTipoLinha.texto) {
          fim++;
        }
      }
      final start = inicio;
      final end = fim;
      final grupo = _linhas.sublist(start, end);
      final alvo = grupo.indexWhere((linha) => linha.id == _foco?.id);
      final foco = _foco;
      final offset = alvo < 0
          ? null
          : grupo
                .take(alvo)
                .fold(
                  foco!.offset,
                  (offset, linha) => offset + linha.texto.length + 1,
                );
      campos.add(
        _CampoLinhas(
          key: ValueKey(primeira.id),
          texto: grupo.map((linha) => linha.texto).join('\n'),
          fontSize: widget.fontSize,
          checklist: checklist,
          marcado: primeira.marcado,
          concluido: widget.todo.concluido,
          enabled: widget.enabled,
          offset: offset,
          onFocado: (campo) => _ativo = campo,
          onFocoAplicado: () {
            if (_foco == foco) _foco = null;
          },
          onChanged: (texto, caret) => checklist
              ? _editarItem(start, texto)
              : _editarTexto(start, end, texto, caret),
          onConverter: (selecao) => checklist
              ? _converterItem(start)
              : _converterTexto(start, end, selecao),
          onMarcar: (valor) =>
              _substituir(start, end, [primeira.copyWith(marcado: valor)]),
        ),
      );
      inicio = fim;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: campos,
          ),
        ),
        IconButton(
          tooltip: 'Alternar texto e checklist',
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.checklist, size: 18),
          onPressed: widget.enabled ? () => _ativo?.converter() : null,
        ),
      ],
    );
  }
}

List<String> _quebrar(String texto) =>
    texto.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');

class _CampoLinhas extends StatefulWidget {
  const _CampoLinhas({
    super.key,
    required this.texto,
    required this.fontSize,
    required this.checklist,
    required this.marcado,
    required this.concluido,
    required this.enabled,
    required this.offset,
    required this.onFocado,
    required this.onFocoAplicado,
    required this.onChanged,
    required this.onConverter,
    required this.onMarcar,
  });

  final String texto;
  final double fontSize;
  final bool checklist, marcado, concluido, enabled;
  final int? offset;
  final ValueChanged<_CampoLinhasState> onFocado;
  final VoidCallback onFocoAplicado;
  final void Function(String, int) onChanged;
  final ValueChanged<TextSelection> onConverter;
  final ValueChanged<bool> onMarcar;

  @override
  State<_CampoLinhas> createState() => _CampoLinhasState();
}

class _CampoLinhasState extends State<_CampoLinhas> {
  // Gives mobile IMEs a character to delete when backspacing an empty item.
  static const _vazio = '\u200b';
  late final _controller = TextEditingController(text: _textoDoCampo);
  final _focus = FocusNode();

  String get _textoDoCampo =>
      widget.checklist && widget.texto.isEmpty ? _vazio : widget.texto;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_aoFocar);
    _aplicarFoco();
  }

  void _aoFocar() {
    if (!_focus.hasFocus) return;
    widget.onFocado(this);
    if (_controller.text == _vazio && widget.checklist) {
      _controller.selection = const TextSelection.collapsed(offset: 1);
    }
  }

  @override
  void didUpdateWidget(covariant _CampoLinhas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != _textoDoCampo) {
      final caret = _controller.selection.extentOffset.clamp(
        0,
        _textoDoCampo.length,
      );
      _controller.value = TextEditingValue(
        text: _textoDoCampo,
        selection: TextSelection.collapsed(offset: caret),
      );
    }
    _aplicarFoco();
  }

  void _aplicarFoco() {
    final offset = widget.offset;
    if (offset == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.offset != offset) return;
      _focus.requestFocus();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text == _vazio && widget.checklist
            ? 1
            : offset.clamp(0, _controller.text.length),
      );
      widget.onFocoAplicado();
    });
  }

  void converter() {
    if (mounted && widget.enabled) widget.onConverter(_controller.selection);
  }

  void _alterar(String texto) {
    if (!widget.checklist) {
      widget.onChanged(texto, _controller.selection.extentOffset);
      return;
    }
    if (texto.isEmpty && widget.texto.isEmpty) {
      converter();
      return;
    }
    if (widget.texto.isEmpty) texto = texto.replaceFirst(_vazio, '');
    widget.onChanged(texto, _controller.selection.extentOffset);
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final campo = Focus(
      canRequestFocus: false,
      onKeyEvent: (_, evento) {
        if (widget.checklist &&
            widget.texto.isEmpty &&
            evento is KeyDownEvent &&
            evento.logicalKey == LogicalKeyboardKey.backspace) {
          converter();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        enabled: widget.enabled,
        onChanged: _alterar,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        style: TextStyle(
          fontSize: widget.fontSize,
          decoration: widget.marcado || widget.concluido
              ? TextDecoration.lineThrough
              : null,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: const InputDecoration(
          filled: false,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          hintText: 'Conteúdo do To-do',
        ),
        contextMenuBuilder: (context, editable) =>
            AdaptiveTextSelectionToolbar.buttonItems(
              anchors: editable.contextMenuAnchors,
              buttonItems: [
                ...editable.contextMenuButtonItems,
                ContextMenuButtonItem(
                  label: widget.checklist
                      ? 'Converter em texto'
                      : 'Converter em checklist',
                  onPressed: () {
                    ContextMenuController.removeAny();
                    converter();
                  },
                ),
              ],
            ),
      ),
    );
    if (!widget.checklist) return campo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: widget.marcado,
          onChanged: widget.enabled ? (valor) => widget.onMarcar(valor!) : null,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(child: campo),
      ],
    );
  }
}
