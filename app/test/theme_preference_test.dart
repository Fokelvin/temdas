import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temdas/app/temdas_app.dart';
import 'package:temdas/theme/theme_preference.dart';
import 'package:temdas/view/widgets/app_drawer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'sistema por padrão, escolha persiste e sistema remove preferência',
    () async {
      final preference = ThemePreference();
      addTearDown(preference.dispose);
      await preference.load();
      expect(preference.mode, ThemeMode.system);
      final dark = preference.select(ThemeMode.dark);
      final light = preference.select(ThemeMode.light);
      expect(await dark, isTrue);
      expect(await light, isTrue);
      final reloaded = ThemePreference();
      addTearDown(reloaded.dispose);
      await reloaded.load();
      expect(reloaded.mode, ThemeMode.light);
      await reloaded.select(ThemeMode.system);
      expect(
        (await SharedPreferences.getInstance()).containsKey(
          ThemePreference.storageKey,
        ),
        isFalse,
      );
    },
  );

  test('carga inicial não sobrescreve escolha manual', () async {
    SharedPreferences.setMockInitialValues({
      ThemePreference.storageKey: 'dark',
    });
    final preference = ThemePreference();
    addTearDown(preference.dispose);
    final loading = preference.load();
    await preference.select(ThemeMode.light);
    await loading;
    expect(preference.mode, ThemeMode.light);
  });

  testWidgets(
    'preferência altera MaterialApp inteiro e sobrevive à recriação',
    (tester) async {
      await tester.pumpWidget(const TemdasApp());
      await tester.pumpAndSettle();
      // Let the bundled font metrics settle before animating theme colors.
      await tester.runAsync(() => GoogleFonts.pendingFonts());
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(Navigator).first);
      final preference = ThemePreferenceScope.maybeOf(context)!;
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.system,
      );
      await preference.select(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.dark);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const TemdasApp());
      await tester.pumpAndSettle();
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
    },
  );

  testWidgets('menu compartilhado oferece Sistema, Claro e Escuro', (
    tester,
  ) async {
    final preference = ThemePreference();
    addTearDown(preference.dispose);
    await tester.pumpWidget(
      ThemePreferenceScope(
        notifier: preference,
        child: const MaterialApp(
          home: Scaffold(body: AppDrawer(currentRoute: '/demandas')),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<ThemeMode>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Escuro').last);
    await tester.pumpAndSettle();
    expect(preference.mode, ThemeMode.dark);
    expect(
      (await SharedPreferences.getInstance()).getString(
        ThemePreference.storageKey,
      ),
      'dark',
    );
  });
}
