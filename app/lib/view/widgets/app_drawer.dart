import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_preference.dart';
import 'theme_toggle_button.dart';
import '../../data/supabase_session.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});
  final String currentRoute;

  @override
  Widget build(BuildContext context) => NavigationDrawer(
    selectedIndex: _indexFor(currentRoute),
    onDestinationSelected: (index) {
      final route = [
        AppRoutes.demandas,
        AppRoutes.sprint,
        AppRoutes.logTime,
        AppRoutes.relatorios,
        AppRoutes.perfil,
      ][index];
      Navigator.pop(context);
      if (route != currentRoute) Navigator.pushReplacementNamed(context, route);
    },
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(28, 16, 16, 12),
        child: Row(children: [_BrandLogo()]),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.task_alt_outlined),
        selectedIcon: Icon(Icons.task_alt),
        label: Text('Demandas'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.directions_run_outlined),
        selectedIcon: Icon(Icons.directions_run),
        label: Text('Sprint'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.calendar_month_outlined),
        selectedIcon: Icon(Icons.calendar_month),
        label: Text('Log time'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.assessment_outlined),
        selectedIcon: Icon(Icons.assessment),
        label: Text('Relatórios'),
      ),
      const NavigationDrawerDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: Text('Meu Perfil'),
      ),
      const Divider(),
      if (ThemePreferenceScope.maybeOf(context) case final preference?)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
          child: DropdownButtonFormField<ThemeMode>(
            key: ValueKey(preference.mode),
            initialValue: preference.mode,
            decoration: const InputDecoration(labelText: 'Tema'),
            items: const [
              DropdownMenuItem(value: ThemeMode.system, child: Text('Sistema')),
              DropdownMenuItem(value: ThemeMode.light, child: Text('Claro')),
              DropdownMenuItem(value: ThemeMode.dark, child: Text('Escuro')),
            ],
            onChanged: (mode) async {
              if (mode == null) return;
              final saved = await preference.select(mode);
              if (!saved && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Não foi possível salvar o tema neste dispositivo.',
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Sair'),
        onTap: () async {
          Navigator.pop(context);
          await supabaseSession?.signOut();
        },
      ),
    ],
  );

  int _indexFor(String route) => switch (route) {
    AppRoutes.sprint => 1,
    AppRoutes.logTime => 2,
    AppRoutes.relatorios => 3,
    AppRoutes.perfil => 4,
    AppRoutes.demandas || AppRoutes.demandaDetalhe => 0,
    _ => 0,
  };
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(TemdasTokens.controlRadius),
        child: Image.asset(
          'assets/images/temdas_logo.png',
          width: 42,
          height: 42,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 10),
      Image.asset(
        'assets/images/temdas_texto.png',
        width: 132,
        height: 44,
        fit: BoxFit.contain,
      ),
    ],
  );
}

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.route,
    required this.body,
    this.actions,
    this.toolbar,
  });
  final String title;
  final String route;
  final Widget body;
  final List<Widget>? actions;

  final Widget? toolbar;

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: AppDrawer(currentRoute: route),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 1100 &&
              MediaQuery.textScalerOf(context).scale(14) <= 20;
          final contextual = toolbar != null || (actions?.isNotEmpty ?? false);
          Widget controls() => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?toolbar,
              if (!wide && (actions?.isNotEmpty ?? false))
                Wrap(spacing: 8, runSpacing: 8, children: actions!),
            ],
          );
          Widget boundedControls() => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  constraints.maxHeight *
                  (MediaQuery.textScalerOf(context).scale(14) > 21 ? .3 : .4),
            ),
            child: SingleChildScrollView(child: controls()),
          );
          return Column(
            children: [
              Material(
                key: const ValueKey('page-toolbar'),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu),
                              tooltip: 'Abrir menu',
                              onPressed: () =>
                                  Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          if (wide) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 10, 20, 8),
                              child: Text(
                                title,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Expanded(
                              child: contextual
                                  ? boundedControls()
                                  : const SizedBox(),
                            ),
                            if (actions != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: actions!,
                                ),
                              ),
                          ] else
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                                child: Text(
                                  title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                            ),
                          const ThemeToggleButton(),
                        ],
                      ),
                      if (!wide && contextual)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 8, 4),
                          child: boundedControls(),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: body),
            ],
          );
        },
      ),
    ),
  );
}

/// Flexible search plus contextual controls, wrapping without horizontal clipping.
class PageToolbar extends StatelessWidget {
  const PageToolbar({super.key, this.search, required this.children});
  final Widget? search;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      if (search != null && constraints.maxWidth >= 820 * scale) {
        return Row(
          children: [
            Expanded(child: search!),
            for (final child in children) ...[const SizedBox(width: 8), child],
          ],
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (search != null) ...[search!, const SizedBox(height: 8)],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          ),
        ],
      );
    },
  );
}
