import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app/app_routes.dart';
import '../ui/components/home_preview.dart';
import '../ui/theme/tokens.dart';
import 'widgets/theme_toggle_button.dart';

/// Copy explicitly approved for the public homepage.
const homeSections = [
  (
    label: 'Apresentação',
    description:
        'Organize suas demandas e acompanhe o tempo dedicado a cada atividade.',
    icon: Symbols.home_rounded,
  ),
  (
    label: 'Demandas',
    description: 'Organize atividades, prioridades e status.',
    icon: Symbols.task_alt_rounded,
  ),
  (
    label: 'Sprints',
    description:
        'Planeje períodos de trabalho e acompanhe as demandas vinculadas.',
    icon: Symbols.sprint_rounded,
  ),
  (
    label: 'Log Time',
    description: 'Registre o tempo dedicado a cada demanda.',
    icon: Symbols.calendar_month_rounded,
  ),
  (
    label: 'Relatórios',
    description: 'Consulte as horas registradas por demanda e período.',
    icon: Symbols.assessment_rounded,
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scroll = ScrollController();
  final _sections = List.generate(homeSections.length, (_) => GlobalKey());
  final _navigationKeys = List.generate(
    homeSections.length,
    (_) => GlobalKey(),
  );
  final _viewportKey = GlobalKey();
  int _active = 0;
  bool _scrollingToSection = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_trackSection);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _trackSection() {
    if (_scrollingToSection || !mounted || !_scroll.hasClients) return;
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox) return;
    final top = viewport.localToGlobal(Offset.zero).dy;
    var active = 0;
    for (var i = 0; i < _sections.length; i++) {
      final box = _sections[i].currentContext?.findRenderObject();
      if (box is RenderBox && box.localToGlobal(Offset.zero).dy <= top + 56) {
        active = i;
      }
    }
    if (_scroll.position.extentAfter < 4) active = _sections.length - 1;
    if (_active != active) setState(() => _active = active);
  }

  Future<void> _goTo(int index) async {
    final target = _sections[index].currentContext;
    if (target == null) return;
    final navigationMotion = AppTokens.motion(context);
    _scrollingToSection = true;
    setState(() => _active = index);
    try {
      await Scrollable.ensureVisible(
        target,
        alignment: 0,
        duration: AppTokens.motion(context, 400),
        curve: AppTokens.curve,
      );
      if (!mounted) return;
      final navigation = _navigationKeys[index].currentContext;
      if (navigation != null && navigation.mounted) {
        await Scrollable.ensureVisible(
          navigation,
          alignment: .5,
          duration: navigationMotion,
          curve: AppTokens.curve,
        );
      }
    } finally {
      _scrollingToSection = false;
    }
  }

  void _enter() =>
      Navigator.of(context).pushReplacementNamed(AppRoutes.demandas);

  Widget _links() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < homeSections.length; i++)
        Padding(
          key: _navigationKeys[i],
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Semantics(
            selected: _active == i,
            child: TextButton(
              key: ValueKey('home-nav-$i'),
              onPressed: () => _goTo(i),
              style: TextButton.styleFrom(
                foregroundColor: AppTokens.of(context).text,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: _active == i
                    ? AppTokens.of(context).accentSoft
                    : null,
              ),
              child: Text(homeSections[i].label),
            ),
          ),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    return Scaffold(
      key: const ValueKey('public-homepage'),
      body: SafeArea(
        child: Column(
          children: [
            Material(
              color: t.bg,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1240),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final inline =
                          box.maxWidth >= 1080 &&
                          MediaQuery.textScalerOf(context).scale(1) <= 1.2;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Semantics(
                                      button: true,
                                      label: 'TEMDAS',
                                      child: InkWell(
                                        onTap: () => _goTo(0),
                                        borderRadius: BorderRadius.circular(6),
                                        child: const _BrandSignature(),
                                      ),
                                    ),
                                  ),
                                ),
                                if (inline) _links(),
                                const SizedBox(width: 8),
                                const ThemeToggleButton(),
                                const SizedBox(width: 8),
                                FilledButton(
                                  key: const ValueKey('home-enter'),
                                  onPressed: _enter,
                                  child: const Text('Entrar'),
                                ),
                              ],
                            ),
                            if (!inline) ...[
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _links(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: t.border),
            Expanded(
              key: _viewportKey,
              child: Scrollbar(
                controller: _scroll,
                child: SingleChildScrollView(
                  key: const ValueKey('home-scroll'),
                  controller: _scroll,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1240),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SelectionArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _hero(),
                              for (
                                var index = 1;
                                index < homeSections.length;
                                index++
                              )
                                _feature(index),
                              _footer(),
                            ],
                          ),
                        ),
                      ),
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

  Widget _hero() => Container(
    key: _sections[0],
    padding: const EdgeInsets.symmetric(vertical: 64),
    child: LayoutBuilder(
      builder: (context, box) {
        final wide =
            box.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        final text = Theme.of(context).textTheme;
        final introduction = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Tempo e Demandas',
                key: const ValueKey('home-title'),
                style: text.displayLarge?.copyWith(
                  fontSize: wide
                      ? 76
                      : box.maxWidth >= 600
                      ? 64
                      : 40,
                  height: 1.04,
                  letterSpacing: -1.5,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.of(context).text,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                homeSections[0].description,
                style: text.bodyLarge?.copyWith(
                  height: 1.6,
                  color: AppTokens.of(context).text2,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: _enter,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(112, 48),
                  ),
                  child: const Text('Entrar'),
                ),
                OutlinedButton(
                  onPressed: () => _goTo(1),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(112, 48),
                  ),
                  child: const Text('Recursos'),
                ),
              ],
            ),
          ],
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 4, child: introduction),
              const SizedBox(width: 40),
              const Expanded(flex: 6, child: HomePreview(section: 0)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            introduction,
            const SizedBox(height: 40),
            const HomePreview(section: 0),
          ],
        );
      },
    ),
  );

  Widget _feature(int index) => Container(
    key: _sections[index],
    padding: const EdgeInsets.symmetric(vertical: 56),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: AppTokens.of(context).border)),
    ),
    child: LayoutBuilder(
      builder: (context, box) {
        final wide =
            box.maxWidth >= 900 &&
            MediaQuery.textScalerOf(context).scale(1) <= 1.3;
        final feature = homeSections[index];
        final heading = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTokens.of(context).accentSoft,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(feature.icon, color: AppTokens.accent, size: 20),
            ),
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                feature.label,
                key: ValueKey('home-section-$index'),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: wide ? 36 : 28,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              feature.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTokens.of(context).text2,
                height: 1.6,
              ),
            ),
          ],
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 300, child: heading),
              const SizedBox(width: 64),
              Expanded(child: HomePreview(section: index)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 24),
            HomePreview(section: index),
          ],
        );
      },
    ),
  );

  Widget _footer() => Container(
    padding: const EdgeInsets.symmetric(vertical: 32),
    decoration: BoxDecoration(
      border: Border(top: BorderSide(color: AppTokens.of(context).border)),
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 16,
      children: [
        Text('TEMDAS', style: Theme.of(context).textTheme.titleSmall),
        Text('Tempo e Demandas', style: Theme.of(context).textTheme.bodySmall),
        TextButton(onPressed: _enter, child: const Text('Entrar')),
      ],
    ),
  );
}

class _BrandSignature extends StatelessWidget {
  const _BrandSignature();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTokens.light.surface
          : null,
      borderRadius: BorderRadius.circular(6),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 130,
        height: 24,
        child: ClipRect(
          child: OverflowBox(
            maxWidth: 162,
            maxHeight: 54,
            child: Image.asset(
              'assets/images/temdas_wordmark_transparent.png',
              width: 162,
              height: 54,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    ),
  );
}
