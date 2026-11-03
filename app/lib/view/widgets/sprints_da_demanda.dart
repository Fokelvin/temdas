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
  });
  final List<backend.Sprint> sprints;
  final int? demandaId;
  final ValueChanged<backend.Sprint?>? onAbrir;

  @override
  Widget build(BuildContext context) {
    final ordenadas = ordenarSprints(sprints);
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
              return Tooltip(
                message: texto,
                child: TextButton(
                  key: ValueKey(
                    i == 0
                        ? 'sprint-da-demanda-$demandaId'
                        : 'sprint-da-demanda-$demandaId-${sprint!.id}',
                  ),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: ativa
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    backgroundColor: ativa
                        ? Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: .35)
                        : null,
                    textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: ativa ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
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
}
