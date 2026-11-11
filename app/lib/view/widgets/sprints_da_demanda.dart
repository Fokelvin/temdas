import '../../ui/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;
import '../../app/app_routes.dart';
import '../formatters/sprint_apresentacao.dart';

class SprintsDaDemanda extends StatelessWidget {
  const SprintsDaDemanda({
    super.key,
    required this.sprints,
    this.demandaId,
    this.onAbrir,
    this.compacta = false,
  });
  final bool compacta;
  final List<backend.Sprint> sprints;
  final int? demandaId;
  final ValueChanged<backend.Sprint?>? onAbrir;

  @override
  Widget build(BuildContext context) {
    final t = AppTokens.of(context);
    final ordenadas = ordenarSprints(sprints);
    if (compacta) return _resumoCompacto(context, ordenadas);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < (ordenadas.isEmpty ? 1 : ordenadas.length); i++)
          Builder(
            builder: (context) {
              final sprint = ordenadas.isEmpty ? null : ordenadas[i];
              final ativa = sprint?.status == backend.SprintStatus.ativa;
              final texto = sprint == null
                  ? 'Sem Sprint'
                  : '${nomeSprint(sprint.nome)} · ${estadoSprint(sprint)}';
              final style = TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: t.darkContrast
                    ? (ativa ? AppTokens.sprintChipText : t.secondaryLabel)
                    : ativa
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                backgroundColor: t.darkContrast
                    ? (ativa ? AppTokens.sprintChipSurface : null)
                    : ativa
                    ? Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: .35)
                    : null,
                textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: ativa ? FontWeight.w600 : FontWeight.normal,
                ),
              );
              return Tooltip(
                message: texto,
                child: TextButton(
                  key: ValueKey(
                    i == 0
                        ? 'sprint-da-demanda-$demandaId'
                        : 'sprint-da-demanda-$demandaId-${sprint!.id}',
                  ),
                  style: t.darkContrast
                      ? style.copyWith(
                          side: WidgetStateProperty.resolveWith(
                            (states) => states.contains(WidgetState.focused)
                                ? const BorderSide(color: AppTokens.accent)
                                : ativa
                                ? const BorderSide(
                                    color: AppTokens.sprintChipBorder,
                                  )
                                : null,
                          ),
                        )
                      : style,
                  onPressed: () {
                    if (onAbrir != null) {
                      onAbrir!(sprint);
                      return;
                    }
                    Navigator.pushNamed(
                      context,
                      sprint?.id == null
                          ? AppRoutes.sprint
                          : AppRoutes.detalheDaSprint(sprint!.id!),
                    );
                  },
                  child: Text(
                    texto,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _abrir(BuildContext context, backend.Sprint? sprint) {
    if (onAbrir != null) {
      onAbrir!(sprint);
    } else {
      Navigator.pushNamed(
        context,
        sprint?.id == null
            ? AppRoutes.sprint
            : AppRoutes.detalheDaSprint(sprint!.id!),
      );
    }
  }

  Widget _resumoCompacto(BuildContext context, List<backend.Sprint> ordenadas) {
    final t = AppTokens.of(context);
    final primeira = ordenadas.isEmpty ? null : ordenadas.first;
    final label = primeira == null
        ? 'Sem Sprint'
        : '${nomeSprint(primeira.nome)}${ordenadas.length > 1 ? ' +${ordenadas.length - 1}' : ' · ${estadoSprint(primeira)}'}';
    final tooltip = ordenadas.isEmpty
        ? 'Sem Sprint'
        : ordenadas
              .map((s) => '${nomeSprint(s.nome)} · ${estadoSprint(s)}')
              .join('\n');
    final ativa = primeira?.status == backend.SprintStatus.ativa;
    final color = t.darkContrast
        ? (ativa ? AppTokens.sprintChipText : t.secondaryLabel)
        : Theme.of(context).colorScheme.primary;
    final child = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 11, color: color),
    );
    final mobile = MediaQuery.sizeOf(context).width < 1024;
    final style = TextButton.styleFrom(
      visualDensity: VisualDensity.standard,
      foregroundColor: color,
      minimumSize: Size(0, mobile ? 44 : 32),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: ativa
          ? (t.darkContrast
                ? AppTokens.sprintChipSurface
                : Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: .35))
          : null,
    );
    if (ordenadas.length <= 1) {
      return Tooltip(
        message: tooltip,
        child: TextButton(
          key: ValueKey('sprint-da-demanda-$demandaId'),
          style: style,
          onPressed: () => _abrir(context, primeira),
          child: child,
        ),
      );
    }
    return Tooltip(
      message: tooltip,
      child: PopupMenuButton<backend.Sprint>(
        key: ValueKey('sprint-da-demanda-$demandaId'),
        tooltip: 'Ver todas as Sprints da Demanda',
        onSelected: (sprint) => _abrir(context, sprint),
        itemBuilder: (_) => [
          for (final sprint in ordenadas)
            PopupMenuItem(
              value: sprint,
              child: Text(
                '${nomeSprint(sprint.nome)} · ${estadoSprint(sprint)}',
              ),
            ),
        ],
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: mobile ? 44 : 32,
            minWidth: mobile ? 44 : 32,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 1,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
