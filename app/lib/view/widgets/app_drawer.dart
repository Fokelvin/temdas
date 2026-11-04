import 'package:flutter/material.dart';
import '../../ui/components/app_shell.dart';
import '../../ui/components/app_side_menu.dart';
import 'theme_toggle_button.dart';

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
  Widget build(BuildContext context) => AppShell(
    route: route,
    body: body,
    header: LayoutBuilder(
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
                MediaQuery.sizeOf(context).height *
                (MediaQuery.textScalerOf(context).scale(14) > 21 ? .3 : .4),
          ),
          child: SingleChildScrollView(child: controls()),
        );
        return Material(
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
                    if (MediaQuery.sizeOf(context).width < 600)
                      const AppMenuButton(),
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
        );
      },
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
