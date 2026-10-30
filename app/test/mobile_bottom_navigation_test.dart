import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temdas/app/app_routes.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/ui/components/app_shell.dart';
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
  for (final width in [360.0, 390.0, 430.0, 820.0]) {
    testWidgets('barra compartilhada navega entre as cinco páginas em $width', (
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
      for (final index in [0, 1, 2, 3, 4, 0]) {
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
        for (var item = 0; item < 5; item++) {
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
}
