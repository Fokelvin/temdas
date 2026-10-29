import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/theme/app_theme.dart';
import 'package:temdas/theme/theme_preference.dart';
import 'package:temdas/view/widgets/app_drawer.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [360.0, 800.0, 1440.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('toolbar acessível em $width px e escala $scale', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(Size(width, 760));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final preference = ThemePreference();
        addTearDown(preference.dispose);
        await tester.pumpWidget(
          ThemePreferenceScope(
            notifier: preference,
            child: MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: Size(width, 760),
                  textScaler: TextScaler.linear(scale),
                ),
                child: child!,
              ),
              home: PageScaffold(
                title: 'Demandas',
                route: '/demandas',
                toolbar: PageToolbar(
                  search: const TextField(
                    decoration: InputDecoration(labelText: 'Busca'),
                  ),
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Filtros'),
                    ),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Criar demanda'),
                    ),
                  ],
                ),
                body: const Center(child: Text('Conteúdo')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final theme = tester.getRect(
          find.byKey(const ValueKey('alternar-tema')),
        );
        expect(theme.right, closeTo(width - 8, .1));
        expect(theme.top, lessThan(16));
        expect(theme.width, greaterThanOrEqualTo(48));
        expect(theme.height, greaterThanOrEqualTo(48));
        expect(
          tester.getRect(find.byType(TextField)).right,
          lessThanOrEqualTo(width),
        );
        expect(find.text('Conteúdo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('ícone persiste tema e Sistema continua disponível no menu', (
    tester,
  ) async {
    final preference = ThemePreference();
    addTearDown(preference.dispose);
    await tester.pumpWidget(
      ThemePreferenceScope(
        notifier: preference,
        child: AnimatedBuilder(
          animation: preference,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: preference.mode,
            home: const PageScaffold(
              title: 'Perfil',
              route: '/perfil',
              body: SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('alternar-tema')));
    await tester.pumpAndSettle();
    expect(preference.mode, ThemeMode.dark);
    expect(
      (await SharedPreferences.getInstance()).getString(
        ThemePreference.storageKey,
      ),
      'dark',
    );
    await tester.tap(find.byTooltip('Abrir menu'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sistema').last);
    await tester.pumpAndSettle();
    expect(preference.mode, ThemeMode.system);
    expect(
      (await SharedPreferences.getInstance()).containsKey(
        ThemePreference.storageKey,
      ),
      isFalse,
    );
  });

  testWidgets('busca usa a largura livre ao ampliar desktop', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Future<double> fieldWidth(double width) async {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(
        MaterialApp(
          home: PageScaffold(
            title: 'Demandas',
            route: '/demandas',
            toolbar: PageToolbar(
              search: const TextField(),
              children: [
                TextButton(onPressed: () {}, child: const Text('Filtros')),
              ],
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(TextField)).width;
    }

    final first = await fieldWidth(1440);
    final second = await fieldWidth(1920);
    expect(second - first, closeTo(480, 1));
    expect(tester.takeException(), isNull);
  });
}
