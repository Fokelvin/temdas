import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/app_routes.dart';
import '../theme/tokens.dart';

abstract final class AppNavigation {
  static const routes = [
    AppRoutes.demandas,
    AppRoutes.sprint,
    AppRoutes.logTime,
    AppRoutes.relatorios,
    AppRoutes.perfil,
  ];
  static const labels = [
    'Demandas',
    'Sprints',
    'Log Time',
    'Relatórios',
    'Perfil',
  ];
  static const icons = [
    Symbols.task_alt_rounded,
    Symbols.sprint_rounded,
    Symbols.calendar_month_rounded,
    Symbols.assessment_rounded,
    Symbols.person_rounded,
  ];

  static String parentRoute(String route) {
    if (route == AppRoutes.demandaDetalhe) return AppRoutes.demandas;
    if (route.startsWith('${AppRoutes.sprint}/')) return AppRoutes.sprint;
    return route;
  }
}

/// The same mobile navigation on every destination, including its safe area.
class MobileBottomNavigation extends StatelessWidget {
  const MobileBottomNavigation({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final selectedRoute = AppNavigation.parentRoute(currentRoute);
    return Material(
      key: const ValueKey('mobile-bottom-navigation'),
      color: tokens.surface,
      child: SafeArea(
        top: false,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: tokens.border)),
          ),
          child: Row(
            children: [
              for (var index = 0; index < AppNavigation.routes.length; index++)
                Expanded(
                  child: Tooltip(
                    message: AppNavigation.labels[index],
                    child: InkWell(
                      key: ValueKey('mobile-nav-$index'),
                      onTap: () {
                        final destination = AppNavigation.routes[index];
                        if (destination != selectedRoute) {
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(destination);
                        }
                      },
                      child: Semantics(
                        button: true,
                        selected: selectedRoute == AppNavigation.routes[index],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              AppNavigation.icons[index],
                              size: 20,
                              color:
                                  selectedRoute == AppNavigation.routes[index]
                                  ? AppTokens.accent
                                  : tokens.text2,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppNavigation.labels[index],
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10.5,
                                color:
                                    selectedRoute == AppNavigation.routes[index]
                                    ? AppTokens.accent
                                    : tokens.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
