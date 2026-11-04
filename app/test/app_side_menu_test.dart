import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/ui/components/app_side_menu.dart';
import 'package:temdas/view/widgets/app_drawer.dart';

void main() {
  for (final width in [360.0, 800.0, 1440.0]) {
    testWidgets('menu compartilhado navega em ${width.toInt()} px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 420);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          routes: {
            '/perfil': (_) => const PageScaffold(
              route: '/perfil',
              title: 'Perfil aberto',
              body: SizedBox(),
            ),
          },
          home: const PageScaffold(
            route: '/sprint/72',
            title: 'Detalhes',
            body: SizedBox(),
          ),
        ),
      );
      if (width < 600) {
        await tester.tap(find.byTooltip('Abrir menu'));
        await tester.pumpAndSettle();
      }
      final menu = find.byType(AppSideMenu);
      Finder inside(Finder matching) =>
          find.descendant(of: menu, matching: matching);
      expect(inside(find.byType(Image)), findsOneWidget);
      expect(inside(find.byKey(const ValueKey('alternar-tema'))), findsNothing);
      expect(inside(find.byTooltip('Sair')), findsOneWidget);
      final sprint = tester.widget<Semantics>(
        find
            .ancestor(
              of: inside(find.byTooltip('Sprints')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(sprint.properties.selected, isTrue);
      final perfil = inside(find.byTooltip('Meu Perfil'));
      await tester.ensureVisible(perfil);
      await tester.tap(perfil);
      await tester.pumpAndSettle();
      expect(find.text('Perfil aberto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
