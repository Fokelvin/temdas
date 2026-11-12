import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/ui/components/app_shell.dart';
import 'package:temdas/ui/components/app_side_menu.dart';
import 'package:temdas/ui/theme/tokens.dart';
import 'package:temdas/ui/components/mobile_bottom_navigation.dart';
import 'package:temdas/view/widgets/app_drawer.dart';

class _NavigationObserver extends NavigatorObserver {
  int replacements = 0;
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacements++;
  }
}

void main() {
  for (final width in [320.0, 360.0, 390.0, 430.0, 820.0]) {
    testWidgets('barra compartilhada navega entre os destinos em $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      tester.view.padding = const FakeViewPadding(bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewPadding);
      addTearDown(tester.view.resetPadding);
      final observer = _NavigationObserver();
      Widget page(String route) => route == AppRoutes.demandas
          ? AppShell(
              route: route,
              header: const Text('Demandas'),
              body: const Text('Conteúdo'),
            )
          : PageScaffold(
              title: route,
              route: route,
              body: const Text('Conteúdo'),
            );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: width == 390 ? ThemeMode.dark : ThemeMode.light,
          navigatorObservers: [observer],
          home: page(AppRoutes.demandas),
          routes: {
            for (final route in AppNavigation.routes) route: (_) => page(route),
          },
        ),
      );
      await tester.pumpAndSettle();
      if (width >= 600) {
        expect(find.byType(MobileBottomNavigation), findsNothing);
        return;
      }
      expect(AppNavigation.routes.take(2), [
        AppRoutes.demandas,
        AppRoutes.todos,
      ]);
      for (final index in [...AppNavigation.routes.asMap().keys, 0]) {
        await tester.tap(find.byKey(ValueKey('mobile-nav-$index')));
        await tester.pumpAndSettle();
        final bar = find.byType(MobileBottomNavigation);
        expect(bar, findsOneWidget);
        expect(
          tester.widget<MobileBottomNavigation>(bar).currentRoute,
          AppNavigation.routes[index],
        );
        expect(tester.getSize(bar).height, 84);
        final bottom = tester.getRect(bar).top;
        expect(
          tester.getRect(find.text('Conteúdo')).bottom,
          lessThanOrEqualTo(bottom),
        );
        for (var item = 0; item < AppNavigation.routes.length; item++) {
          final target = find.byKey(ValueKey('mobile-nav-$item'));
          final icon = tester.widget<Icon>(
            find.descendant(of: target, matching: find.byType(Icon)),
          );
          expect(
            icon.color,
            item == index
                ? AppTokens.accent
                : (width == 390 ? AppTokens.dark.text2 : AppTokens.light.text2),
          );
          expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
        }
        final before = observer.replacements;
        await tester.tap(find.byKey(ValueKey('mobile-nav-$index')));
        await tester.pumpAndSettle();
        expect(observer.replacements, before);
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final width in [390.0, 820.0, 1280.0]) {
    testWidgets('menu principal abre e seleciona To-dos em $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget page(String route) =>
          PageScaffold(title: route, route: route, body: const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: page(AppRoutes.demandas),
          routes: {AppRoutes.todos: (_) => page(AppRoutes.todos)},
        ),
      );
      Future<void> openMenu() async {
        if (width < 600) {
          await tester.tap(find.byType(AppMenuButton));
          await tester.pumpAndSettle();
        }
      }

      Finder item(String label) => find.descendant(
        of: find.byType(AppSideMenu),
        matching: find.byTooltip(label),
      );

      await openMenu();
      expect(
        tester.getTopLeft(item('To-dos')).dy,
        greaterThan(tester.getTopLeft(item('Demandas')).dy),
      );
      expect(
        tester.getTopLeft(item('To-dos')).dy,
        lessThan(tester.getTopLeft(item('Sprints')).dy),
      );
      await tester.tap(item('To-dos'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<PageScaffold>(find.byType(PageScaffold)).route,
        AppRoutes.todos,
      );

      await openMenu();
      expect(
        find.ancestor(
          of: item('To-dos'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Semantics && widget.properties.selected == true,
          ),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
