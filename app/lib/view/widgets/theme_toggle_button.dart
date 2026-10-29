import 'package:flutter/material.dart';

import '../../theme/theme_preference.dart';

/// Shares the existing persisted preference; Sistema stays in the drawer.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final preference = ThemePreferenceScope.maybeOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      key: const ValueKey('alternar-tema'),
      tooltip: dark ? 'Usar tema claro' : 'Usar tema escuro',
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: preference == null
          ? null
          : () async {
              final saved = await preference.select(
                dark ? ThemeMode.light : ThemeMode.dark,
              );
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
    );
  }
}

/// The same fixed theme position on authentication and session status screens.
class ThemeToolbar extends StatelessWidget implements PreferredSizeWidget {
  const ThemeToolbar({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    toolbarHeight: 56,
    actions: const [
      Padding(padding: EdgeInsets.only(right: 8), child: ThemeToggleButton()),
    ],
  );
}
