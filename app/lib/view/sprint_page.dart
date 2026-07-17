import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../view_model/workspace_view_model.dart';
import 'widgets/app_drawer.dart';

class SprintPage extends StatelessWidget {
  const SprintPage({super.key, required this.viewModel});
  final WorkspaceViewModel viewModel;

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Sprint',
    route: AppRoutes.sprint,
    body: Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_run,
                size: 58,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Sprints serão desenvolvidas em uma próxima etapa',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Uma demanda poderá ou não ser vinculada a uma sprint.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
