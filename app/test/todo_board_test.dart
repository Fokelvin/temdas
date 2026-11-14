import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/view/todo_page.dart';
import 'package:temdas/view_model/todo_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

class _Client extends backend.Client {
  _Client(this.todos) : super('http://localhost:8080/');

  final List<backend.Todo> todos;
  final operacoes = <(String, Map<String, dynamic>)>[];
  final textos = <Completer<void>>[];
  final titulos = <Completer<void>>[];

  @override
  Future<T> callServerEndpoint<T>(
    String endpoint,
    String method,
    Map<String, dynamic> args, {
    bool authenticated = true,
  }) async {
    if (method == 'listar') return todos as T;
    operacoes.add((method, args));
    if (method == 'editarLinhas') {
      final resposta = Completer<void>();
      textos.add(resposta);
      await resposta.future;
    }
    if (method == 'editarTitulo') {
      final resposta = Completer<void>();
      titulos.add(resposta);
      await resposta.future;
    }
    return null as T;
  }
}

backend.Todo _todo(
  int id,
  String texto, {
  bool concluido = false,
  double largura = 232,
  double altura = 232,
  List<backend.TodoLinha>? linhas,
  String? titulo,
}) => backend.Todo(
  id: id,
  usuarioId: 1,
  conteudo: texto,
  concluido: concluido,
  criadoEm: DateTime.utc(2026),
  titulo: titulo,
  largura: largura,
  altura: altura,
  linhas: linhas,
);

backend.Demanda _demanda(int id, String titulo, {int? pai}) => backend.Demanda(
  id: id,
  usuarioId: 1,
  demandaPaiId: pai,
  titulo: titulo,
  status: backend.DemandaStatus.aberta,
  prioridade: backend.Prioridade.media,
  tempoEstimadoMinutos: 10,
  tempoExecutadoMinutos: 0,
  criadoEm: DateTime.utc(2026),
  atualizadoEm: DateTime.utc(2026),
);

Future<void> _abrir(
  WidgetTester tester,
  TodoViewModel model, {
  String? userId,
  List<backend.Demanda> demandas = const [],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TodoBoard(
          viewModel: model,
          userId: userId,
          demandas: Future.value(demandas),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('fonte tem três níveis, limites e escopo por usuário e cartão', (
    tester,
  ) async {
    final todos = [
      _todo(1, 'Primeiro'),
      _todo(
        2,
        'Checklist',
        linhas: [
          backend.TodoLinha(
            id: 'linha-1',
            tipo: backend.TodoTipoLinha.checklist,
            texto: 'Item',
            marcado: false,
          ),
        ],
      ),
    ];
    TodoViewModel modelo() => TodoViewModel(_Client(todos));
    final model = modelo();
    addTearDown(model.dispose);
    await _abrir(tester, model, userId: 'usuario-a');

    TextField campo(int id) => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(TextField),
      ),
    );

    expect(campo(1).style!.fontSize, 13);
    expect(campo(2).style!.fontSize, 13);
    final mais = find.descendant(
      of: find.byKey(const ValueKey(1)),
      matching: find.text('A+'),
    );
    final menos = find.descendant(
      of: find.byKey(const ValueKey(1)),
      matching: find.text('A−'),
    );

    await tester.tap(mais);
    await tester.pumpAndSettle();
    expect(campo(1).style!.fontSize, 15);
    expect(campo(2).style!.fontSize, 13);
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(of: mais, matching: find.byType(TextButton)),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(menos);
    await tester.pumpAndSettle();
    await tester.tap(menos);
    await tester.pumpAndSettle();
    expect(campo(1).style!.fontSize, 11);
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(of: menos, matching: find.byType(TextButton)),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey(2)),
        matching: find.text('A+'),
      ),
    );
    await tester.pumpAndSettle();
    expect(campo(2).style!.fontSize, 15);

    await tester.pumpWidget(const SizedBox.shrink());
    final recarregado = modelo();
    addTearDown(recarregado.dispose);
    await _abrir(tester, recarregado, userId: 'usuario-a');
    expect(campo(1).style!.fontSize, 11);
    expect(campo(2).style!.fontSize, 15);

    await tester.pumpWidget(const SizedBox.shrink());
    final outroUsuario = modelo();
    addTearDown(outroUsuario.dispose);
    await _abrir(tester, outroUsuario, userId: 'usuario-b');
    expect(campo(1).style!.fontSize, 13);
    expect(campo(2).style!.fontSize, 13);
  });

  testWidgets('título opcional é editável no cabeçalho e salva sozinho', (
    tester,
  ) async {
    final client = _Client([_todo(1, 'Conteúdo')]);
    final model = TodoViewModel(client);
    addTearDown(model.dispose);
    await _abrir(tester, model);

    expect(find.byTooltip('Adicionar título'), findsOneWidget);
    await tester.tap(find.byTooltip('Adicionar título'));
    await tester.pump();
    final editor = find.byKey(const ValueKey('titulo-todo-1'));
    expect(editor, findsOneWidget);
    await tester.enterText(editor, 'Título novo');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(model.todos.single.titulo, 'Título novo');
    expect(client.operacoes.last.$1, 'editarTitulo');
    expect(client.operacoes.last.$2['titulo'], 'Título novo');
    expect(find.text('Conteúdo'), findsOneWidget);
    client.titulos.single.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('falha de autosave mantém o título e permite nova tentativa', (
    tester,
  ) async {
    final client = _Client([_todo(1, 'Conteúdo')]);
    final model = TodoViewModel(client);
    addTearDown(model.dispose);
    await _abrir(tester, model);
    await tester.tap(find.byTooltip('Adicionar título'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('titulo-todo-1')),
      'Não perder este título',
    );
    await tester.pump(const Duration(milliseconds: 350));
    client.titulos.first.completeError(StateError('sem rede'));
    await tester.pumpAndSettle();

    expect(model.falhaAoSalvar, isTrue);
    expect(model.todos.single.titulo, 'Não perder este título');
    await tester.tap(find.text('Falha ao salvar. Tentar novamente'));
    await tester.pump();
    expect(client.operacoes.last.$2['titulo'], 'Não perder este título');
    client.titulos.last.complete();
    await tester.pumpAndSettle();
    expect(model.todos.single.titulo, 'Não perder este título');
  });

  testWidgets('mostra nome de Demanda vinculada em uma linha no cabeçalho', (
    tester,
  ) async {
    final demanda = _demanda(
      42,
      'Demanda com um nome muito extenso para o cartão',
    );
    final todo = _todo(1, 'Conteúdo').copyWith(demandaId: 42);
    final model = TodoViewModel(_Client([todo]));
    addTearDown(model.dispose);
    await _abrir(tester, model, demandas: [demanda]);

    final identificacao = find.byKey(const ValueKey('demanda-vinculada-42'));
    expect(identificacao, findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.descendant(of: identificacao, matching: find.byType(Text)),
          )
          .maxLines,
      1,
    );
    expect(find.text('Demanda #42'), findsNothing);
  });

  testWidgets('seletor busca por ID e mostra hierarquia da Demanda', (
    tester,
  ) async {
    final cliente = _Client([_todo(1, 'Cartão')]);
    final model = TodoViewModel(cliente);
    addTearDown(model.dispose);
    await _abrir(
      tester,
      model,
      demandas: [_demanda(42, 'Mãe'), _demanda(43, 'Filha', pai: 42)],
    );

    await tester.tap(find.byTooltip('Ações do To-do'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vínculo com Demanda'));
    await tester.pumpAndSettle();
    final busca = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(busca, '43');
    await tester.pumpAndSettle();

    final filha = find.byKey(const ValueKey('opcao-vinculo-demanda-43'));
    expect(filha, findsOneWidget);
    expect(find.text('↳ Mãe'), findsOneWidget);
    await tester.tap(filha);
    await tester.pumpAndSettle();
    expect(model.todos.single.demandaId, 43);
  });

  testWidgets(
    'mantém a edição mais recente durante falhas e novas tentativas',
    (tester) async {
      final client = _Client([_todo(1, 'Inicial')]);
      final model = TodoViewModel(client);
      addTearDown(model.dispose);
      await _abrir(tester, model);

      final campo = find.byType(TextField);
      await tester.enterText(campo, 'Primeira alteração');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.enterText(campo, 'Segunda\nlinha nova');
      await tester.pump(const Duration(milliseconds: 350));
      expect(client.textos, hasLength(1));

      client.textos.first.completeError(StateError('falha anterior'));
      await tester.pump();
      expect(client.textos, hasLength(2));
      expect(
        (client.operacoes.last.$2['linhas'] as List<backend.TodoLinha>).map(
          (linha) => linha.texto,
        ),
        ['Segunda', 'linha nova'],
      );

      client.textos.last.completeError(StateError('sem rede'));
      await tester.pumpAndSettle();
      expect(model.falhaAoSalvar, isTrue);
      expect(model.todos.single.conteudo, 'Segunda\nlinha nova');
      await tester.tap(find.text('Falha ao salvar. Tentar novamente'));
      await tester.pump();
      expect(
        (client.operacoes.last.$2['linhas'] as List<backend.TodoLinha>).map(
          (linha) => linha.texto,
        ),
        ['Segunda', 'linha nova'],
      );
      client.textos.last.complete();
      await tester.pumpAndSettle();
      expect(find.text('Falha ao salvar. Tentar novamente'), findsNothing);
    },
  );

  testWidgets('converte seleção multilinha e preserva linhas externas e IDs', (
    tester,
  ) async {
    final client = _Client([_todo(1, 'Antes\nComprar\nPagar\nDepois')]);
    final model = TodoViewModel(client);
    addTearDown(model.dispose);
    await _abrir(tester, model);
    final texto = find.byType(TextField);
    await tester.tap(texto);
    tester.widget<TextField>(texto).controller!.selection = const TextSelection(
      baseOffset: 6,
      extentOffset: 19,
    );
    await tester.tap(find.byTooltip('Alternar texto e checklist'));
    await tester.pump();
    final linhas = model.todos.single.linhas!;
    expect(linhas.map((linha) => linha.texto), [
      'Antes',
      'Comprar',
      'Pagar',
      'Depois',
    ]);
    expect(linhas.map((linha) => linha.tipo), [
      backend.TodoTipoLinha.texto,
      backend.TodoTipoLinha.checklist,
      backend.TodoTipoLinha.checklist,
      backend.TodoTipoLinha.texto,
    ]);
    final itens = find.byWidgetPredicate(
      (widget) =>
          widget is Checkbox && widget.visualDensity == VisualDensity.compact,
    );
    await tester.tap(itens.first);
    await tester.pump();
    expect(model.todos.single.linhas![1].marcado, isTrue);
    expect(model.todos.single.concluido, isFalse);
    expect(
      model.todos.single.linhas!.map((linha) => linha.id),
      linhas.map((linha) => linha.id),
    );
    await tester.pump(const Duration(milliseconds: 350));
    client.textos.single.complete();
    await tester.pumpAndSettle();

    final recarregado = TodoViewModel(_Client([model.todos.single]));
    addTearDown(recarregado.dispose);
    await tester.pumpWidget(const SizedBox());
    await _abrir(tester, recarregado);
    expect(tester.widget<Checkbox>(itens.first).value, isTrue);
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Comprar'))
          .style!
          .decoration,
      TextDecoration.lineThrough,
    );
  });

  testWidgets('Enter divide o item e Backspace em item vazio volta a texto', (
    tester,
  ) async {
    final original = _todo(1, 'Item').copyWith(
      linhas: [
        backend.TodoLinha(
          id: 'item',
          tipo: backend.TodoTipoLinha.checklist,
          texto: 'Item',
          marcado: true,
        ),
      ],
    );
    final client = _Client([original]);
    final model = TodoViewModel(client);
    addTearDown(model.dispose);
    await _abrir(tester, model);
    await tester.tap(find.byType(TextField));
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'Item\n',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    await tester.pumpAndSettle();
    expect(model.todos.single.linhas!.map((linha) => linha.tipo), [
      backend.TodoTipoLinha.checklist,
      backend.TodoTipoLinha.checklist,
    ]);
    expect(model.todos.single.linhas!.first.marcado, isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).focusNode!.hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(model.todos.single.linhas!.last.tipo, backend.TodoTipoLinha.texto);

    await tester.tap(find.byType(TextField).first);
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'Item\n',
        selection: TextSelection.collapsed(offset: 5),
      ),
    );
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '\u200b\n',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    await tester.pumpAndSettle();
    expect(model.todos.single.linhas!.map((linha) => linha.tipo), [
      backend.TodoTipoLinha.checklist,
      backend.TodoTipoLinha.texto,
      backend.TodoTipoLinha.texto,
    ]);
    expect(model.todos.single.linhas!.first.id, 'item');
    await tester.pump(const Duration(milliseconds: 350));
    client.textos.single.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('filtra concluídos e reabre sem esperar a rede', (tester) async {
    final client = _Client([
      _todo(1, 'Pendente'),
      _todo(2, 'Feito', concluido: true),
    ]);
    final model = TodoViewModel(client);
    addTearDown(model.dispose);
    await _abrir(tester, model);

    expect(find.text('Feito'), findsNothing);
    await tester.tap(find.text('Mostrar concluídos'));
    await tester.pumpAndSettle();
    expect(find.text('Feito'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(model.todos.last.concluido, isFalse);
    expect(client.operacoes.single.$1, 'alterarConclusao');
    expect(client.operacoes.single.$2, {'id': 2, 'concluido': false});
  });

  testWidgets('arrasta pela alça e usa altura automática no mobile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(380, 680);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final client = _Client([
      _todo(1, 'Primeiro'),
      _todo(2, 'Segundo\nMais texto'),
    ]);
    final model = TodoViewModel(client);
    addTearDown(model.dispose);
    await _abrir(tester, model);

    expect(find.byTooltip('Redimensionar To-do'), findsNothing);
    await tester.tap(find.byTooltip('Aumentar fonte').first);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).style!.fontSize,
      15,
    );
    final alvo = find.byKey(const ValueKey(2));
    final origem = tester.getCenter(find.byTooltip('Arrastar To-do').first);
    final destino = tester.getCenter(alvo);
    final gesto = await tester.startGesture(origem);
    await gesto.moveBy(const Offset(0, 28));
    await tester.pump();
    await gesto.moveTo(destino);
    await tester.pump();
    await gesto.up();
    await tester.pumpAndSettle();

    expect(model.todos.map((todo) => todo.id), [2, 1]);
    expect(client.operacoes.single.$1, 'mover');
  });

  testWidgets('redimensiona no desktop e confirma a exclusão', (tester) async {
    final client = _Client([_todo(1, 'Post-it')]);
    final model = TodoViewModel(client);
    addTearDown(model.dispose);
    await _abrir(tester, model);

    await tester.drag(
      find.byTooltip('Redimensionar To-do'),
      const Offset(60, 45),
    );
    await tester.pumpAndSettle();
    expect(model.todos.single.largura, greaterThan(232));
    expect(model.todos.single.altura, greaterThan(232));
    expect(client.operacoes.single.$1, 'redimensionar');

    await tester.tap(find.byTooltip('Ações do To-do'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir To-do?'), findsOneWidget);
    expect(client.operacoes, hasLength(1));
    await tester.tap(find.text('Excluir').last);
    await tester.pumpAndSettle();
    expect(model.todos, isEmpty);
    expect(client.operacoes.last.$1, 'excluir');
  });

  testWidgets('compacta os cartões e recalcula após redimensionar e mover', (
    tester,
  ) async {
    final client = _Client([
      _todo(1, 'Baixo', largura: 220, altura: 140),
      _todo(2, 'Alto', largura: 260, altura: 320),
      _todo(3, 'Baixo também', largura: 200, altura: 110),
      _todo(4, 'Preenche o espaço', largura: 220, altura: 100),
    ]);
    final model = TodoViewModel(client);
    addTearDown(model.dispose);
    await _abrir(tester, model);

    Rect cartao(int id) => tester.getRect(find.byKey(ValueKey(id)));

    final primeiro = cartao(1);
    final alto = cartao(2);
    final terceiro = cartao(3);
    final quarto = cartao(4);
    expect(quarto.left, terceiro.left);
    expect(quarto.top, terceiro.bottom + 12);
    expect(quarto.top, lessThan(alto.bottom));
    expect(terceiro.top, primeiro.top);

    final cartoes = [primeiro, alto, terceiro, quarto];
    for (var i = 0; i < cartoes.length; i++) {
      expect(
        cartoes[i].right,
        lessThanOrEqualTo(tester.view.physicalSize.width - 16),
      );
      for (final outro in cartoes.skip(i + 1)) {
        expect(cartoes[i].overlaps(outro), isFalse);
      }
    }

    await tester.drag(
      find.byTooltip('Redimensionar To-do').at(2),
      const Offset(60, 200),
    );
    await tester.pumpAndSettle();
    expect(model.todos[2].altura, greaterThan(110));
    expect(model.todos[2].largura, greaterThan(200));
    final depoisDoRedimensionamento = cartao(4);
    expect(depoisDoRedimensionamento.top, greaterThan(quarto.top));
    final redimensionados = [1, 2, 3, 4].map(cartao).toList();
    for (var i = 0; i < redimensionados.length; i++) {
      expect(
        redimensionados[i].right,
        lessThanOrEqualTo(tester.view.physicalSize.width - 16),
      );
      for (final outro in redimensionados.skip(i + 1)) {
        expect(redimensionados[i].overlaps(outro), isFalse);
      }
    }

    final alcaQuarto = find.byTooltip('Arrastar To-do').at(3);
    final origem = tester.getCenter(alcaQuarto);
    final destino = tester.getCenter(find.byKey(const ValueKey(1)));
    final gesto = await tester.startGesture(origem);
    await gesto.moveTo(destino);
    await tester.pump();
    await gesto.up();
    await tester.pumpAndSettle();
    expect(model.todos.map((todo) => todo.id), [4, 1, 2, 3]);
    expect(cartao(4).top, lessThan(depoisDoRedimensionamento.top));
    expect(
      client.operacoes.any((operacao) => operacao.$1 == 'redimensionar'),
      isTrue,
    );
    expect(client.operacoes.any((operacao) => operacao.$1 == 'mover'), isTrue);
  });
}
