import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/view/auth_pages.dart';

void main() {
  testWidgets(
    'alternar senha preserva valor, seleção, autofill e envio por Enter',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: LoginPage(session: null)),
      );
      final password = find.byType(TextField).at(1);
      await tester.enterText(password, 'Senha com espaços 123');
      final controller = tester.widget<TextField>(password).controller!;
      controller.selection = const TextSelection(
        baseOffset: 2,
        extentOffset: 7,
      );
      final value = controller.value;
      expect(tester.widget<TextField>(password).obscureText, isTrue);
      for (final tooltip in ['Mostrar senha', 'Ocultar senha']) {
        expect(find.byTooltip(tooltip), findsOneWidget);
        // Ativa pelo teclado para cobrir também a acessibilidade do controle.
        final button = find.byTooltip(tooltip);
        final focus = Focus.of(
          tester.element(
            find.descendant(of: button, matching: find.byType(Icon)),
          ),
        );
        focus.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(controller.value, value);
        expect(tester.widget<TextField>(password).autofillHints, [
          AutofillHints.password,
        ]);
        expect(
          tester.widget<TextField>(password).obscureText,
          tooltip == 'Ocultar senha',
        );
        expect(tester.widget<TextField>(password).focusNode!.hasFocus, isTrue);
      }
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(
        find.text('A autenticação ainda não está configurada.'),
        findsOneWidget,
      );
      expect(controller.text, value.text);
      semantics.dispose();
    },
  );
}
