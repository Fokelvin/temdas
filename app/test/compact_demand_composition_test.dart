import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/view/widgets/sprints_da_demanda.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as b;

void main() {
  for (final dark in [false, true]) {
    testWidgets('resumo compacto preserva estados e navegação $dark', (
      tester,
    ) async {
      final sprints = [
        for (final (id, status) in [
          (72, b.SprintStatus.concluida),
          (73, b.SprintStatus.ativa),
          (74, b.SprintStatus.planejada),
          (71, b.SprintStatus.cancelada),
        ])
          b.Sprint(
            id: id,
            usuarioId: 1,
            nome: 'Sprint $id',
            status: status,
            dataInicio: DateTime(2026, 11, id - 70),
            dataFim: DateTime(2026, 11, id - 69),
          ),
      ];
      final opened = <int?>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: 150,
              child: SprintsDaDemanda(
                compacta: true,
                demandaId: 1,
                sprints: sprints,
                onAbrir: (s) => opened.add(s?.id),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Sprint 73 +3'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('sprint-da-demanda-1')));
      await tester.pumpAndSettle();
      final entries = tester
          .widgetList<PopupMenuItem<b.Sprint>>(
            find.byType(PopupMenuItem<b.Sprint>),
          )
          .toList();
      expect(entries.map((e) => e.value?.id), [73, 74, 72, 71]);
      for (final label in [
        'Sprint 73 · Ativa',
        'Sprint 74 · Planejada',
        'Sprint 72 · Finalizada',
        'Sprint 71 · Cancelada',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      await tester.tap(find.text('Sprint 72 · Finalizada'));
      await tester.pumpAndSettle();
      expect(opened, [72]);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Sprint compacta preserva alvo móvel e nome legado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SprintsDaDemanda(
            compacta: true,
            demandaId: 1,
            sprints: [
              b.Sprint(
                id: 72,
                usuarioId: 1,
                nome: 'Sprint 72',
                status: b.SprintStatus.concluida,
                dataInicio: DateTime(2026),
                dataFim: DateTime(2026, 1, 7),
              ),
            ],
            onAbrir: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('Sprint 72 · Finalizada'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('sprint-da-demanda-1'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(find.textContaining('Sprint Sprint'), findsNothing);
  });
}
