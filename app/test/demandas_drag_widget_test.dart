import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/demandas_page.dart';
import 'package:temdas/view_model/demandas_view_model.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import 'support/fake_demanda_repository.dart';

void main() {
  testWidgets('demanda raiz inicia drag com movimento normal do ponteiro', (
    tester,
  ) async {
    final primeira = demandaFixture(id: 1, titulo: 'Primeira');
    final segunda = demandaFixture(id: 2, titulo: 'Segunda');
    final repository = FakeDemandaRepository(demandas: [primeira, segunda]);
    final viewModel = DemandasViewModel(repository: repository);
    addTearDown(viewModel.dispose);
    final resposta = Completer<backend.Demanda>();
    repository.respostaMoverPendente = resposta;

    await tester.pumpWidget(
      MaterialApp(home: DemandasPage(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    final draggables = find.byWidgetPredicate((widget) => widget is Draggable);
    final longPressDraggables = find.byWidgetPredicate(
      (widget) => widget is LongPressDraggable,
    );
    expect(draggables, findsNWidgets(2));
    expect(longPressDraggables, findsNothing);
    expect(
      draggables.evaluate().every(
        (element) => (element.widget as Draggable).maxSimultaneousDrags == 1,
      ),
      isTrue,
    );

    final origem = tester.getCenter(
      find.byKey(const ValueKey('demanda-drag-handle-2')),
    );
    final destino = tester.getCenter(
      find.byKey(const ValueKey('demanda-drop-emAndamento-0')),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('demanda-drop-emAndamento-0')))
          .height,
      greaterThan(100),
    );
    final gesto = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kPrimaryButton,
    );
    await gesto.addPointer(location: origem);
    await gesto.down(origem);
    await gesto.moveTo(destino);
    await tester.pump();
    expect(find.text('Soltar demanda aqui'), findsOneWidget);
    await gesto.up();
    await gesto.removePointer();
    await tester.pump();

    expect(repository.ultimaMovimentacao?.demandaId, 2);
    expect(
      repository.ultimaMovimentacao?.statusDestino,
      backend.DemandaStatus.emAndamento,
    );
    expect(find.text('Movendo demanda...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Draggable && widget.maxSimultaneousDrags == 0,
      ),
      findsNWidgets(2),
    );
    resposta.complete(
      segunda.copyWith(status: backend.DemandaStatus.emAndamento, ordem: 0),
    );
    await tester.pumpAndSettle();
    expect(viewModel.demandas.map((demanda) => demanda.id), [1, 2]);
    expect(find.text('Movendo demanda...'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
