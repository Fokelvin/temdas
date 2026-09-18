import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/log_time_page.dart';
import 'package:temdas/view_model/agenda_view_model.dart';

import 'support/fake_agenda_repositories.dart';

void main() {
  testWidgets('exibe dados persistidos e faz lançamento global em horas', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final registroRepository = FakeRegistroTempoRepository(
      registros: [
        registroTempoFixture(
          inicioLocal: DateTime(2026, 9, 9, 9),
          duracaoMinutos: 30,
        ),
      ],
    );
    final viewModel = AgendaViewModel(
      demandaRepository: FakeAgendaDemandaRepository(
        demandas: [demandaAgendaFixture(titulo: 'Implementar agenda real')],
      ),
      registroTempoRepository: registroRepository,
      hoje: DateTime(2026, 9, 9),
    );
    addTearDown(viewModel.dispose);

    await tester.pumpWidget(
      MaterialApp(home: LogTimePage(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 - Implementar agenda real'), findsOneWidget);
    expect(find.text('Tempo executado'), findsOneWidget);
    expect(find.text('30min'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('abrir-lancamento-global')));
    await tester.pumpAndSettle();
    expect(find.text('Selecionar demanda'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('confirmar-demanda-log-time')));
    await tester.pumpAndSettle();

    await _preencherIntervalo(tester);
    await tester.tap(find.byKey(const ValueKey('salvar-log-time')));
    await tester.pumpAndSettle();

    expect(registroRepository.registrosCriados.single.duracaoMinutos, 75);
    expect(find.text('Tempo lançado com sucesso.'), findsOneWidget);
    expect(find.text('1h45'), findsOneWidget);
  });
}

Future<void> _preencherIntervalo(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('log-time-inicio-hora')),
    '09',
  );
  await tester.enterText(
    find.byKey(const ValueKey('log-time-inicio-minuto')),
    '00',
  );
  await tester.enterText(find.byKey(const ValueKey('log-time-fim-hora')), '10');
  await tester.enterText(
    find.byKey(const ValueKey('log-time-fim-minuto')),
    '15',
  );
}
