import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/widgets/log_time_dialog.dart';

void main() {
  testWidgets('aceita vírgula e retorna duração em horas', (tester) async {
    LogTimeFormData? resultado;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                resultado = await showDialog<LogTimeFormData>(
                  context: context,
                  builder: (_) => LogTimeDialog(
                    demandaTitulo: 'Demanda testada',
                    dataInicial: DateTime(2026, 9, 9),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('log-time-duracao')),
      '1,25',
    );
    await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
    await tester.pumpAndSettle();

    expect(resultado, isNotNull);
    expect(resultado!.data, DateTime(2026, 9, 9));
    expect(resultado!.duracaoHoras, 1.25);
  });

  testWidgets('recusa duração que não resulta em minutos inteiros', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showDialog<LogTimeFormData>(
                context: context,
                builder: (_) => LogTimeDialog(
                  demandaTitulo: 'Demanda testada',
                  dataInicial: DateTime(2026, 9, 9),
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('log-time-duracao')),
      '0.01',
    );
    await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
    await tester.pump();

    expect(
      find.text('Use uma duração positiva que resulte em minutos inteiros.'),
      findsOneWidget,
    );
    expect(find.byType(LogTimeDialog), findsOneWidget);
  });
}
