import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/supabase_session.dart';
import '../theme/tokens.dart';
import 'mobile_bottom_navigation.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.menu),
    tooltip: 'Abrir menu',
    onPressed: () => Scaffold.of(context).openDrawer(),
  );
}

class AppSideMenu extends StatelessWidget {
  const AppSideMenu({
    super.key,
    required this.route,
    this.compact = false,
    this.drawer = false,
  });

  final String route;
  final bool compact, drawer;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final ativo = AppNavigation.parentRoute(route);
    Widget item(
      String label,
      IconData icon,
      VoidCallback onTap, {
      bool selected = false,
      int height = 32,
      bool profile = false,
    }) {
      Widget surface({bool focused = false}) => Material(
        color: selected
            ? (t.darkContrast ? t.activeSurface(t.surface) : t.accentSoft)
            : Colors.transparent,
        borderRadius: t.darkContrast && (selected || focused)
            ? null
            : BorderRadius.circular(6),
        shape: t.darkContrast && (selected || focused)
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                  color: focused ? AppTokens.accent : t.activeBorder(t.surface),
                ),
              )
            : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: compact || drawer ? 44 : height.toDouble(),
            ),
            child: Row(
              mainAxisAlignment: compact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (!compact) const SizedBox(width: 8),
                Icon(
                  icon,
                  size: 16,
                  color: selected ? AppTokens.accent : t.secondaryLabel,
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected || (t.darkContrast && profile)
                            ? t.text
                            : t.secondaryLabel,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Semantics(
          selected: selected,
          child: Tooltip(
            message: label,
            child: t.darkContrast
                ? Focus(
                    canRequestFocus: false,
                    child: Builder(
                      builder: (context) =>
                          surface(focused: Focus.of(context).hasFocus),
                    ),
                  )
                : surface(),
          ),
        ),
      );
    }

    void go(String destino) {
      final navigator = Navigator.of(context);
      if (drawer) navigator.pop();
      if (destino != ativo) navigator.pushReplacementNamed(destino);
    }

    return Container(
      width: compact ? 60 : 212,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(right: BorderSide(color: t.border)),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 12,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 32).clamp(
                  0,
                  double.infinity,
                ),
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    SizedBox(
                      height: 32,
                      child: Row(
                        mainAxisAlignment: compact
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/temdas_logo.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                            excludeFromSemantics: true,
                          ),
                          if (!compact) ...[
                            const SizedBox(width: 8),
                            const Flexible(
                              child: Text(
                                'TEMDAS',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (var i = 0; i < AppNavigation.routes.length - 1; i++)
                      item(
                        AppNavigation.labels[i],
                        AppNavigation.icons[i],
                        () => go(AppNavigation.routes[i]),
                        selected: ativo == AppNavigation.routes[i],
                      ),
                    const Spacer(),
                    Divider(color: t.border),
                    item(
                      'Meu Perfil',
                      Symbols.person_rounded,
                      () => go(AppNavigation.routes.last),
                      selected: ativo == AppNavigation.routes.last,
                      profile: true,
                      height: 44,
                    ),
                    item('Sair', Symbols.logout_rounded, () async {
                      if (drawer) Navigator.of(context).pop();
                      await supabaseSession?.signOut();
                    }, height: 44),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
