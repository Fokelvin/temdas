import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../app/app_routes.dart';
import '../data/repositories/demanda_repository.dart';
import '../view_model/todo_view_model.dart';
import 'formatters/demanda_identificacao.dart';
import 'widgets/app_drawer.dart';
import 'widgets/todo_editor.dart';

const todoIcon = Icons.sticky_note_2_outlined;

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) => const PageScaffold(
    title: 'To-dos',
    route: AppRoutes.todos,
    body: TodoBoard(),
  );
}

Future<void> mostrarListaTodo(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => const _ListaTodo(),
);

class _ListaTodo extends StatefulWidget {
  const _ListaTodo();

  @override
  State<_ListaTodo> createState() => _ListaTodoState();
}

class _ListaTodoState extends State<_ListaTodo> {
  final _model = TodoViewModel.daSessao();

  @override
  void initState() {
    super.initState();
    _model.carregar();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('To-dos'),
    content: SizedBox(
      width: 440,
      child: ListenableBuilder(
        listenable: _model,
        builder: (context, _) {
          if (_model.carregando) {
            return const Center(child: CircularProgressIndicator());
          }
          if (_model.erroAoCarregar) {
            return TextButton(
              onPressed: _model.carregar,
              child: const Text('Falha ao carregar. Tentar novamente'),
            );
          }
          final todos = _model.todos;
          if (todos.isEmpty) return const Text('Nenhum To-do.');
          return ListView.builder(
            shrinkWrap: true,
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              final detalhes = [
                if (todo.data case final data?) _dataLocal(data),
                if (todo.demandaId case final id?) 'Demanda #$id',
              ];
              return ListTile(
                dense: true,
                leading: Icon(
                  todo.concluido ? Icons.check_circle : Icons.circle_outlined,
                  semanticLabel: todo.concluido ? 'Concluído' : 'Pendente',
                ),
                title: Text(todo.conteudo),
                subtitle: detalhes.isEmpty ? null : Text(detalhes.join(' · ')),
              );
            },
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Fechar'),
      ),
      FilledButton(
        onPressed: () {
          final navigator = Navigator.of(context);
          navigator.pop();
          navigator.pushNamed(AppRoutes.todos);
        },
        child: const Text('Abrir quadro'),
      ),
    ],
  );
}

class TodoBoard extends StatefulWidget {
  const TodoBoard({super.key, this.demandaId, this.viewModel});

  final int? demandaId;
  final TodoViewModel? viewModel;

  @override
  State<TodoBoard> createState() => _TodoBoardState();
}

class _TodoBoardState extends State<TodoBoard>
    with AutomaticKeepAliveClientMixin {
  late final _model = widget.viewModel ?? TodoViewModel.daSessao();
  final _tamanhos = <int, Size>{};
  bool _mostrarConcluidos = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _model.carregar();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _model,
      builder: (context, _) {
        final todos = _model.todos.where((todo) {
          final demandaId = widget.demandaId;
          return (demandaId == null || todo.demandaId == demandaId) &&
              (_mostrarConcluidos || !todo.concluido);
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _model.podeCriar
                        ? () => showDialog<void>(
                            context: context,
                            builder: (_) => _CriarTodo(
                              onCriar: (texto) =>
                                  _model.criar(texto, widget.demandaId),
                            ),
                          )
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Novo To-do'),
                  ),
                  FilterChip(
                    label: const Text('Mostrar concluídos'),
                    selected: _mostrarConcluidos,
                    onSelected: (valor) =>
                        setState(() => _mostrarConcluidos = valor),
                  ),
                  if (_model.falhaAoSalvar)
                    TextButton.icon(
                      onPressed: _model.tentarSalvar,
                      icon: const Icon(Icons.sync_problem),
                      label: const Text('Falha ao salvar. Tentar novamente'),
                    )
                  else if (_model.salvando)
                    const Text('Salvando…'),
                ],
              ),
            ),
            Expanded(
              child: _model.carregando && todos.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _model.erroAoCarregar
                  ? Center(
                      child: TextButton(
                        onPressed: _model.carregar,
                        child: const Text(
                          'Falha ao carregar. Tentar novamente',
                        ),
                      ),
                    )
                  : todos.isEmpty
                  ? Center(
                      child: Text(
                        _mostrarConcluidos
                            ? 'Nenhum To-do.'
                            : 'Nenhum To-do pendente.',
                      ),
                    )
                  : _grid(todos),
            ),
          ],
        );
      },
    );
  }

  Widget _grid(List<backend.Todo> todos) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = MediaQuery.sizeOf(context).width < 600;
      final largura = math.max(0.0, constraints.maxWidth - 32);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: largura,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (index, todo) in todos.indexed)
                _card(todo, todos, index, largura, mobile),
            ],
          ),
        ),
      );
    },
  );

  Widget _card(
    backend.Todo todo,
    List<backend.Todo> todos,
    int index,
    double largura,
    bool mobile,
  ) {
    final id = todo.id!;
    final ocupado = _model.excluindo(id);
    final tamanho = _tamanhos[id] ?? Size(todo.largura, todo.altura);
    final larguraVisivel = math.min(largura, tamanho.width);
    return DragTarget<int>(
      key: ValueKey(id),
      onWillAcceptWithDetails: (dados) => dados.data != id && !ocupado,
      onAcceptWithDetails: (dados) {
        final origem = todos.indexWhere((item) => item.id == dados.data);
        if (origem < 0) return;
        _model.mover(dados.data, id, depois: origem < index);
      },
      builder: (context, candidatos, _) => SizedBox(
        width: mobile ? largura : larguraVisivel,
        height: mobile ? null : tamanho.height,
        child: _PostIt(
          todo: todo,
          mobile: mobile,
          ocupado: ocupado,
          alvo: candidatos.isNotEmpty,
          onLinhas: (linhas) => _model.editarLinhas(id, linhas),
          onConclusao: (valor) => _model.alterarConclusao(id, valor),
          onData: () => _editarData(todo),
          onVinculo: () => _editarVinculo(todo),
          onExcluir: () => _excluir(id),
          onRedimensionar: (delta) {
            final atual = _tamanhos[id] ?? Size(larguraVisivel, tamanho.height);
            setState(() {
              _tamanhos[id] = Size(
                (atual.width + delta.dx).clamp(
                  200.0,
                  math.max(200.0, math.min(1600.0, largura)),
                ),
                (atual.height + delta.dy).clamp(180.0, 1200.0),
              );
            });
          },
          onFimRedimensionar: () {
            final novo = _tamanhos.remove(id);
            if (novo != null) {
              _model.redimensionar(id, novo.width, novo.height);
            }
          },
        ),
      ),
    );
  }

  Future<void> _editarData(backend.Todo todo) async {
    final hoje = DateTime.now();
    final atual = todo.data == null ? hoje : DateTime.parse(todo.data!);
    final data = await showDatePicker(
      context: context,
      initialDate: atual,
      helpText: 'Selecionar data',
      cancelText: 'Cancelar',
      confirmText: 'Salvar data',
      firstDate: DateTime(1),
      lastDate: DateTime(9999, 12, 31),
      builder: (context, child) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: child!),
          if (todo.data != null)
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, DateTime(0)),
              child: const Text('Remover data'),
            ),
        ],
      ),
    );
    if (mounted && data != null) {
      _model.alterarData(todo.id!, data.year == 0 ? null : _iso(data));
    }
  }

  Future<void> _editarVinculo(backend.Todo todo) async {
    final destino = await showDialog<int>(
      context: context,
      builder: (_) => _VinculoTodo(demandaId: todo.demandaId),
    );
    if (mounted && destino != null) {
      _model.vincular(todo.id!, destino == 0 ? null : destino);
    }
  }

  Future<void> _excluir(int id) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir To-do?'),
        content: const Text('O To-do será excluído permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (mounted && confirmado == true) _model.excluir(id);
  }
}

class _PostIt extends StatefulWidget {
  const _PostIt({
    required this.todo,
    required this.mobile,
    required this.ocupado,
    required this.alvo,
    required this.onLinhas,
    required this.onConclusao,
    required this.onData,
    required this.onVinculo,
    required this.onExcluir,
    required this.onRedimensionar,
    required this.onFimRedimensionar,
  });

  final backend.Todo todo;
  final bool mobile, ocupado, alvo;
  final ValueChanged<List<backend.TodoLinha>> onLinhas;
  final ValueChanged<bool> onConclusao;
  final VoidCallback onData, onVinculo, onExcluir, onFimRedimensionar;
  final ValueChanged<Offset> onRedimensionar;

  @override
  State<_PostIt> createState() => _PostItState();
}

class _PostItState extends State<_PostIt> {
  EdgeDraggingAutoScroller? _autoScroll;

  void _acompanharArraste(DragUpdateDetails detalhes) {
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    _autoScroll ??= EdgeDraggingAutoScroller(scrollable, velocityScalar: 8);
    _autoScroll!.startAutoScrollIfNecessary(
      Rect.fromCenter(center: detalhes.globalPosition, width: 1, height: 48),
    );
  }

  @override
  void dispose() {
    _autoScroll?.stopAutoScroll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final esquema = Theme.of(context).colorScheme;
    final escuro = esquema.brightness == Brightness.dark;
    final prazo = todo.data;
    final comparacao = prazo?.compareTo(_iso(DateTime.now()));
    final urgente = !todo.concluido && comparacao != null && comparacao <= 0;
    final papel = todo.concluido
        ? esquema.surfaceContainerHighest
        : escuro
        ? const Color(0xff3c3421)
        : const Color(0xfffff4ca);
    final borda = widget.alvo
        ? esquema.primary
        : urgente
        ? esquema.error
        : esquema.outlineVariant;
    final campo = TodoEditor(
      todo: todo,
      enabled: !widget.ocupado,
      onChanged: widget.onLinhas,
    );

    return Material(
      color: papel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5),
        side: BorderSide(color: borda, width: urgente || widget.alvo ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 2, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Draggable<int>(
                  data: todo.id!,
                  onDragUpdate: _acompanharArraste,
                  onDragEnd: (_) => _autoScroll?.stopAutoScroll(),
                  maxSimultaneousDrags: widget.ocupado ? 0 : 1,
                  feedback: Material(
                    color: papel,
                    elevation: 4,
                    borderRadius: BorderRadius.circular(5),
                    child: SizedBox(
                      width: 180,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          todo.conteudo,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Tooltip(
                      message: 'Arrastar To-do',
                      child: SizedBox(
                        width: 40,
                        height: 44,
                        child: Icon(Icons.drag_indicator),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: todo.concluido ? 'Reabrir To-do' : 'Concluir To-do',
                  child: Checkbox(
                    value: todo.concluido,
                    onChanged: widget.ocupado
                        ? null
                        : (valor) => widget.onConclusao(valor!),
                  ),
                ),
                PopupMenuButton<VoidCallback>(
                  enabled: !widget.ocupado,
                  tooltip: 'Ações do To-do',
                  onSelected: (acao) => acao(),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: widget.onData,
                      child: Text(
                        prazo == null ? 'Definir data' : 'Editar data',
                      ),
                    ),
                    PopupMenuItem(
                      value: widget.onVinculo,
                      child: const Text('Vínculo com Demanda'),
                    ),
                    PopupMenuItem(
                      value: widget.onExcluir,
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.mobile)
              campo
            else
              Expanded(child: SingleChildScrollView(child: campo)),
            if (todo.conteudo.trim().isEmpty)
              Text(
                'Informe o conteúdo.',
                style: TextStyle(color: esquema.error),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (prazo != null)
                        Text(
                          urgente
                              ? '${comparacao < 0 ? 'Atrasado' : 'Hoje'} · ${_dataLocal(prazo)}'
                              : _dataLocal(prazo),
                          style: TextStyle(
                            color: urgente ? esquema.error : esquema.onSurface,
                            fontWeight: urgente ? FontWeight.w600 : null,
                          ),
                        ),
                      if (todo.demandaId case final id?) Text('Demanda #$id'),
                    ],
                  ),
                ),
                if (!widget.mobile)
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeDownRight,
                    child: Tooltip(
                      message: 'Redimensionar To-do',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: widget.ocupado
                            ? null
                            : (evento) => widget.onRedimensionar(evento.delta),
                        onPanEnd: (_) => widget.onFimRedimensionar(),
                        onPanCancel: widget.onFimRedimensionar,
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(Icons.south_east, size: 16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CriarTodo extends StatefulWidget {
  const _CriarTodo({required this.onCriar});

  final Future<void> Function(String) onCriar;

  @override
  State<_CriarTodo> createState() => _CriarTodoState();
}

class _CriarTodoState extends State<_CriarTodo> {
  final _form = GlobalKey<FormState>();
  String _texto = '';
  bool _criando = false;
  bool _erro = false;

  Future<void> _criar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _criando = true;
      _erro = false;
    });
    try {
      await widget.onCriar(_texto);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _criando = false;
          _erro = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_criando,
    child: AlertDialog(
      title: const Text('Novo To-do'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _form,
          child: TextFormField(
            autofocus: true,
            enabled: !_criando,
            minLines: 3,
            maxLines: 7,
            onChanged: (texto) => _texto = texto,
            validator: (texto) =>
                texto!.trim().isEmpty ? 'Informe o conteúdo.' : null,
            decoration: InputDecoration(
              labelText: 'Conteúdo',
              errorText: _erro
                  ? 'Não foi possível criar. Tente novamente.'
                  : null,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _criando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _criando ? null : _criar,
          child: Text(_criando ? 'Criando…' : 'Criar'),
        ),
      ],
    ),
  );
}

class _VinculoTodo extends StatefulWidget {
  const _VinculoTodo({required this.demandaId});

  final int? demandaId;

  @override
  State<_VinculoTodo> createState() => _VinculoTodoState();
}

class _VinculoTodoState extends State<_VinculoTodo> {
  late var _demandas = DemandaRepository().listarDemandas();
  String _busca = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Vincular Demanda'),
    content: SizedBox(
      width: 440,
      height: 320,
      child: Column(
        children: [
          TextField(
            onChanged: (texto) => setState(() => _busca = texto.toLowerCase()),
            decoration: const InputDecoration(labelText: 'Buscar Demanda'),
          ),
          Expanded(
            child: FutureBuilder(
              future: _demandas,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return TextButton(
                    onPressed: () => setState(
                      () => _demandas = DemandaRepository().listarDemandas(),
                    ),
                    child: const Text('Falha ao carregar. Tentar novamente'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final opcoes = snapshot.data!
                    .where(
                      (demanda) => formatarIdentificacaoDemanda(
                        demanda,
                      ).toLowerCase().contains(_busca),
                    )
                    .toList();
                if (opcoes.isEmpty) {
                  return const Center(child: Text('Nenhuma Demanda.'));
                }
                return ListView.builder(
                  itemCount: opcoes.length,
                  itemBuilder: (context, index) {
                    final demanda = opcoes[index];
                    return ListTile(
                      selected: demanda.id == widget.demandaId,
                      title: Text(formatarIdentificacaoDemanda(demanda)),
                      onTap: () => Navigator.pop(context, demanda.id),
                    );
                  },
                );
              },
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
      if (widget.demandaId != null)
        TextButton(
          onPressed: () => Navigator.pop(context, 0),
          child: const Text('Remover vínculo'),
        ),
    ],
  );
}

String _iso(DateTime data) => data.toIso8601String().split('T').first;

String _dataLocal(String data) {
  final [ano, mes, dia] = data.split('-');
  return '$dia/$mes/$ano';
}
