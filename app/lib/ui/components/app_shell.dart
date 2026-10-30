import 'mobile_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../data/supabase_session.dart';
import '../../theme/theme_preference.dart';
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
  static const routes = AppNavigation.routes;
  static const labels = AppNavigation.labels;
  static const icons = AppNavigation.icons;
  void _go(BuildContext context, int index) {
    if (routes[index] != route) {
      Navigator.of(context).pushReplacementNamed(routes[index]);
    }
  }

  Widget _avatar(BuildContext context) {
    final user = supabaseSession?.currentSession?.user;
    final name = (user?.userMetadata?['nome'] ?? user?.email ?? 'Meu Perfil')
        .toString();
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((s) => s.isEmpty ? '' : s[0])
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 12,
      backgroundColor: AppTokens.of(context).surface2,
      child: Text(
        initials,
        style: TextStyle(fontSize: 10, color: AppTokens.of(context).text2),
      ),
    );
  }

  Widget _profileMenu(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Opções do perfil e tema',
    icon: const Icon(Symbols.more_horiz_rounded),
    onSelected: (value) async {
      if (value == 'perfil') _go(context, 4);
      if (value == 'sair') await supabaseSession?.signOut();
      if (value == 'sistema' && context.mounted) {
        await ThemePreferenceScope.maybeOf(context)?.select(ThemeMode.system);
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'perfil', child: Text('Meu Perfil')),
      PopupMenuItem(value: 'sistema', child: Text('Tema: Sistema')),
      PopupMenuItem(value: 'sair', child: Text('Sair')),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 600;
    final desktop = width >= 1024;
    final t = AppTokens.of(context);
    return Scaffold(
      floatingActionButton: mobile ? fab : null,
      bottomNavigationBar: mobile
          ? MobileBottomNavigation(currentRoute: route)
          : null,
      body: SafeArea(
        bottom: !mobile,
        child: Row(
          children: [
            if (!mobile)
              Container(
                width: desktop ? 212 : 60,
                decoration: BoxDecoration(
                  color: t.surface,
                  border: Border(right: BorderSide(color: t.border)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: desktop ? 12 : 4,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 32,
                      child: Row(
                        mainAxisAlignment: desktop
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppTokens.accent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'T',
                              style: TextStyle(
                                color: Color(0xFF0B1220),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (desktop) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'TEMDAS',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (var i = 0; i < 4; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Tooltip(
                          message: labels[i],
                          child: Material(
                            color: route == routes[i]
                                ? t.accentSoft
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () => _go(context, i),
                              child: SizedBox(
                                height: desktop ? 32 : 44,
                                child: Row(
                                  mainAxisAlignment: desktop
                                      ? MainAxisAlignment.start
                                      : MainAxisAlignment.center,
                                  children: [
                                    if (desktop) const SizedBox(width: 8),
                                    Icon(
                                      icons[i],
                                      size: 16,
                                      color: route == routes[i]
                                          ? AppTokens.accent
                                          : t.text2,
                                    ),
                                    if (desktop) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        labels[i],
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: route == routes[i]
                                              ? t.text
                                              : t.text2,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    Divider(color: t.border),
                    Tooltip(
                      message: 'Meu Perfil',
                      child: InkWell(
                        onTap: () => _go(context, 4),
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: desktop
                                ? MainAxisAlignment.start
                                : MainAxisAlignment.center,
                            children: [
                              _avatar(context),
                              if (desktop) ...[
                                const SizedBox(width: 8),
                                const Text('Meu Perfil'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (desktop)
                      Row(
                        children: [
                          const ThemeToggleButton(),
                          const Spacer(),
                          _profileMenu(context),
                        ],
                      )
                    else ...[
                      const ThemeToggleButton(),
                      _profileMenu(context),
                    ],
                  ],
                ),
              ),
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
  Widget build(BuildContext context) => TextField(
    key: const ValueKey('buscar-demandas'),
    controller: controller,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 13),
    decoration: InputDecoration(
      isDense: true,
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
              icon: const Icon(Symbols.close_rounded),
            ),
    ),
  );
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
  Widget build(BuildContext context) => SegmentedButton<T>(
    key: const ValueKey('visualizacao-demandas'),
    showSelectedIcon: false,
    segments: segments,
    selected: {value},
    onSelectionChanged: onChanged,
    style: SegmentedButton.styleFrom(
      visualDensity: VisualDensity.compact,
      minimumSize: Size(0, MediaQuery.sizeOf(context).width >= 1024 ? 30 : 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      textStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      selectedBackgroundColor: AppTokens.of(context).surface2,
      selectedForegroundColor: AppTokens.of(context).text,
    ),
  );
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
      final inline = MediaQuery.sizeOf(context).width >= 1024 && scale <= 1.2;
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
              color: AppTokens.of(context).text2,
              fontSize: 13,
              fontFeatures: AppTokens.numbers,
            ),
          ),
        ],
      );
      final theme = Theme.of(context);
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
                      SizedBox(width: 108, child: title),
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
