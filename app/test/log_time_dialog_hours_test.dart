import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/widgets/log_time_dialog.dart';

void main() {
  testWidgets('aceita intervalo e retorna duração em horas', (tester) async {
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
    await _preencherIntervalo(tester, horaInicial: '09', horaFinal: '10:15');
    await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
    await tester.pumpAndSettle();

    expect(resultado, isNotNull);
    expect(resultado!.data, DateTime(2026, 9, 9));
    expect(resultado!.duracaoHoras, 1.25);
  });

  testWidgets('recusa intervalo que não termina depois do início', (
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
    await _preencherIntervalo(tester, horaInicial: '10', horaFinal: '10:00');
    await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
    await tester.pump();

    expect(
      find.text(
        'A hora final deve ser posterior à hora inicial na mesma data.',
      ),
      findsOneWidget,
    );
    expect(find.byType(LogTimeDialog), findsOneWidget);
  });
}

Future<void> _preencherIntervalo(
  WidgetTester tester, {
  required String horaInicial,
  required String horaFinal,
}) async {
  final inicio = horaInicial.split(':');
  final fim = horaFinal.split(':');
  await tester.enterText(
    find.byKey(const ValueKey('log-time-inicio-hora')),
    inicio.first,
  );
  await tester.enterText(
    find.byKey(const ValueKey('log-time-inicio-minuto')),
    inicio.length > 1 ? inicio[1] : '00',
  );
  await tester.enterText(
    find.byKey(const ValueKey('log-time-fim-hora')),
    fim.first,
  );
  await tester.enterText(
    find.byKey(const ValueKey('log-time-fim-minuto')),
    fim.length > 1 ? fim[1] : '00',
  );
}
