import '../../view/widgets/app_selection.dart';
import 'mobile_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'app_side_menu.dart';
import '../../view/widgets/theme_toggle_button.dart';
import '../theme/tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.route,
    required this.header,
    required this.body,
    this.fab,
  });
  final String route;
  final Widget header, body;
  final Widget? fab;
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 600;
    final desktop = width >= 1024;
    final t = AppTokens.of(context);
    return Scaffold(
      drawer: mobile
          ? Drawer(width: 212, child: AppSideMenu(route: route, drawer: true))
          : null,
      floatingActionButton: mobile ? fab : null,
      bottomNavigationBar: mobile
          ? MobileBottomNavigation(currentRoute: route)
          : null,
      body: AppSelection(
        child: SafeArea(
          bottom: !mobile,
          child: Row(
            children: [
              if (!mobile) AppSideMenu(route: route, compact: !desktop),
              Expanded(
                child: Column(
                  children: [
                    header,
                    Divider(height: 1, color: t.border),
                    Expanded(child: body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  @override
  Widget build(BuildContext context) => primary
      ? FilledButton.icon(
          onPressed: onPressed,
          icon: icon == null ? null : Icon(icon, size: 16),
          label: Text(label),
        )
      : OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon == null ? null : Icon(icon, size: 16),
          label: Text(label),
        );
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final input = Theme.of(context).inputDecorationTheme;
    final border = input.enabledBorder;
    return TextField(
      key: const ValueKey('buscar-demandas'),
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        enabledBorder: t.darkContrast
            ? border?.copyWith(borderSide: BorderSide(color: t.controlBorder))
            : null,
        hintStyle: t.darkContrast
            ? input.hintStyle?.copyWith(color: t.metadata)
            : null,
        prefixIconColor: t.darkContrast ? t.secondaryLabel : null,
        suffixIconColor: t.darkContrast ? t.secondaryLabel : null,
        hintText: 'Buscar por ID ou título...',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: const Icon(Symbols.search_rounded, size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 32),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                key: const ValueKey('limpar-busca-demandas'),
                tooltip: 'Limpar busca',
                onPressed: onClear,
                style: t.darkContrast
                    ? IconButton.styleFrom(foregroundColor: t.secondaryLabel)
                    : null,
                icon: const Icon(Symbols.close_rounded),
              ),
      ),
    );
  }
}

class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  });
  final List<ButtonSegment<T>> segments;
  final T value;
  final ValueChanged<Set<T>> onChanged;
  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final style = SegmentedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: Size(0, MediaQuery.sizeOf(context).width >= 1024 ? 30 : 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      selectedBackgroundColor: t.darkContrast
          ? t.activeSurface(t.bg)
          : t.surface2,
      foregroundColor: t.darkContrast ? t.secondaryLabel : null,
      selectedForegroundColor: t.text,
    );
    final toggle = SegmentedButton<T>(
      key: const ValueKey('visualizacao-demandas'),
      showSelectedIcon: false,
      segments: segments,
      selected: {value},
      onSelectionChanged: onChanged,
      style: t.darkContrast
          ? style.copyWith(
              side: WidgetStatePropertyAll(BorderSide(color: t.controlBorder)),
              iconColor: WidgetStatePropertyAll(t.secondaryLabel),
            )
          : style,
    );
    if (!t.darkContrast) return toggle;

    // Flutter lays out equal-width segments and paints the outer border itself.
    // Paint the selection over that layout so the inset stroke adds no padding.
    final index = segments.indexWhere((segment) => segment.value == value);
    final last = segments.length - 1;
    const corner = Radius.circular(AppTokens.controlRadius);
    return Focus(
      canRequestFocus: false,
      child: Builder(
        builder: (context) => Stack(
          fit: StackFit.passthrough,
          children: [
            toggle,
            if (index >= 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: FractionallySizedBox(
                    alignment: AlignmentDirectional(
                      last == 0 ? 0 : 2 * index / last - 1,
                      0,
                    ),
                    widthFactor: 1 / segments.length,
                    heightFactor: 1,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadiusDirectional.only(
                          topStart: index == 0 ? corner : Radius.zero,
                          bottomStart: index == 0 ? corner : Radius.zero,
                          topEnd: index == last ? corner : Radius.zero,
                          bottomEnd: index == last ? corner : Radius.zero,
                        ),
                        border: Border.all(color: t.activeBorder(t.bg)),
                      ),
                    ),
                  ),
                ),
              ),
            if (Focus.of(context).hasFocus)
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(corner),
                      border: Border.fromBorderSide(
                        BorderSide(color: AppTokens.accent),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.count,
    required this.search,
    required this.filters,
    required this.toggle,
    required this.refresh,
    required this.create,
    required this.density,
  });
  final int count;
  final Widget search, filters, toggle, refresh, create, density;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final mobile = MediaQuery.sizeOf(context).width < 600;
      final scale = MediaQuery.textScalerOf(context).scale(13) / 13;
      final inline = box.maxWidth >= 960 && scale <= 1.2;
      final title = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              'Demandas',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: mobile ? 18 : 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count',
            style: TextStyle(
              color: AppTokens.of(context).metadata,
              fontSize: 13,
              fontFeatures: AppTokens.numbers,
            ),
          ),
        ],
      );
      final inherited = Theme.of(context);
      final t = AppTokens.of(context);
      final theme = t.darkContrast
          ? inherited.copyWith(
              iconButtonTheme: IconButtonThemeData(
                style: (inherited.iconButtonTheme.style ?? const ButtonStyle())
                    .copyWith(
                      foregroundColor: WidgetStatePropertyAll(t.secondaryLabel),
                    ),
              ),
            )
          : inherited;
      final small = ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(0, 30)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: WidgetStatePropertyAll(
          theme.textTheme.labelMedium?.copyWith(fontSize: 12),
        ),
      );
      return Theme(
        data: inline
            ? theme.copyWith(
                filledButtonTheme: FilledButtonThemeData(
                  style: theme.filledButtonTheme.style?.merge(small),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: theme.outlinedButtonTheme.style?.merge(small),
                ),
                iconButtonTheme: IconButtonThemeData(
                  style: theme.iconButtonTheme.style?.merge(
                    small.copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size(30, 30)),
                      padding: const WidgetStatePropertyAll(EdgeInsets.all(4)),
                    ),
                  ),
                ),
              )
            : theme,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 16 : 24,
            vertical: 12,
          ),
          child: Column(
            children: [
              if (mobile) ...[
                Row(
                  children: [
                    const AppMenuButton(),
                    Expanded(child: title),
                    refresh,
                    const ThemeToggleButton(),
                  ],
                ),
                const SizedBox(height: 8),
                search,
                const SizedBox(height: 8),
                Row(children: [filters, const Spacer(), density, toggle]),
              ] else ...[
                if (inline)
                  Row(
                    children: [
                      title,
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: search,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      filters,
                      const SizedBox(width: 8),
                      toggle,
                      density,
                      refresh,
                      const SizedBox(width: 8),
                      create,
                      const ThemeToggleButton(),
                    ],
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(child: title),
                      if (box.maxWidth >= 900 * scale) ...[
                        filters,
                        const SizedBox(width: 8),
                        toggle,
                        density,
                        refresh,
                        create,
                      ] else ...[
                        refresh,
                        create,
                      ],
                      const ThemeToggleButton(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  search,
                  if (box.maxWidth < 900 * scale) ...[
                    const SizedBox(height: 8),
                    Row(children: [filters, const Spacer(), density, toggle]),
                  ],
                ],
              ],
            ],
          ),
        ),
      );
    },
  );
}

class RefreshAction extends StatefulWidget {
  const RefreshAction({
    super.key,
    required this.loading,
    required this.onPressed,
  });
  final bool loading;
  final VoidCallback? onPressed;
  @override
  State<RefreshAction> createState() => _RefreshActionState();
}

class _RefreshActionState extends State<RefreshAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(RefreshAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    if (widget.loading && !MediaQuery.disableAnimationsOf(context)) {
      _rotation.repeat();
    } else {
      _rotation.stop();
      _rotation.value = 0;
    }
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Recarregar demandas',
    onPressed: widget.onPressed,
    icon: RotationTransition(
      turns: _rotation,
      child: const Icon(Symbols.refresh_rounded),
    ),
  );
}
