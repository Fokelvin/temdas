import 'package:flutter/material.dart';

import '../view/demandas_page.dart';
import '../view/log_time_page.dart';
import '../view/sprint_page.dart';
import '../view_model/workspace_view_model.dart';

abstract final class AppRoutes {
  static const demandas = '/demandas';
  static const sprint = '/sprint';
  static const logTime = '/log-time';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    WorkspaceViewModel viewModel,
  ) {
    final page = switch (settings.name) {
      sprint => SprintPage(viewModel: viewModel),
      logTime => LogTimePage(viewModel: viewModel),
      _ => const DemandasPage(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
