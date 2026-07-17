import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/app/temdas_app.dart';

void main() {
  testWidgets('navega de demandas para log time pelo menu', (tester) async {
    await tester.pumpWidget(const TemdasApp());

    expect(find.text('Todas as demandas'), findsOneWidget);
    expect(find.text('Adicionar log time'), findsWidgets);

    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log time'));
    await tester.pumpAndSettle();

    expect(
      find.text('Agenda dos tempos lançados nas demandas'),
      findsOneWidget,
    );
    expect(find.text('Dia'), findsOneWidget);
    expect(find.text('Semana'), findsOneWidget);
  });
}
