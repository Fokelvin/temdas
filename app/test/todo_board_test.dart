import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/todo_page.dart';
import 'package:temdas/view_model/todo_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

class _Client extends backend.Client {
  _Client(this.todos) : super('http://localhost:8080/');

  final List<backend.Todo> todos;
  final operacoes = <(String, Map<String, dynamic>)>[];
  final textos = <Completer<void>>[];

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
    return null as T;
  }
}

backend.Todo _todo(int id, String texto, {bool concluido = false}) =>
    backend.Todo(
      id: id,
      usuarioId: 1,
      conteudo: texto,
      concluido: concluido,
      criadoEm: DateTime.utc(2026),
    );

Future<void> _abrir(WidgetTester tester, TodoViewModel model) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: TodoBoard(viewModel: model)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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
}
