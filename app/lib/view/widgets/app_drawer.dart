import 'package:flutter/material.dart';

import '../../app/app_routes.dart';

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
    ],
  );

  int _indexFor(String route) => switch (route) {
    AppRoutes.sprint => 1,
    AppRoutes.logTime => 2,
    _ => 0,
  };
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
  });
  final String title;
  final String route;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    drawer: AppDrawer(currentRoute: route),
    appBar: AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Abrir menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      actions: actions,
    ),
    body: SafeArea(child: body),
  );
}
