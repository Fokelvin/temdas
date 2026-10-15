import 'package:flutter/material.dart';

import '../view/demanda_detalhe_page.dart';
import '../view/demandas_page.dart';
import '../view/log_time_page.dart';
import '../view/meu_perfil_page.dart';
import '../view/relatorios_page.dart';
import '../view/sprint_page.dart';
import '../view/auth_callback_page.dart';

abstract final class AppRoutes {
  static const demandas = '/demandas';
  static const authCallback = '/auth/callback';
  static const demandaDetalhe = '/demandas/detalhe';
  static const sprint = '/sprint';
  static const logTime = '/log-time';
  static const relatorios = '/relatorios';
  static const perfil = '/perfil';

  static String detalheDaDemanda(int demandaId) => Uri(
    path: demandaDetalhe,
    queryParameters: {'id': demandaId.toString()},
  ).toString();

  static String detalheDaSprint(int sprintId) => '$sprint/$sprintId';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    Uri? callbackUri,
  }) {
    final uri = Uri.tryParse(settings.name ?? Navigator.defaultRouteName);
    final demandaId = settings.arguments is int
        ? settings.arguments as int
        : int.tryParse(uri?.queryParameters['id'] ?? '');
    final segmentosSprint = uri?.pathSegments;
    final rotaDetalheSprint =
        segmentosSprint != null &&
        segmentosSprint.length == 2 &&
        segmentosSprint.first == sprint.substring(1);
    final sprintId = segmentosSprint != null && rotaDetalheSprint
        ? int.tryParse(segmentosSprint[1])
        : null;
    final page = switch (uri?.path) {
      authCallback => AuthCallbackPage(uri: callbackUri ?? Uri.base),
      demandaDetalhe => switch (demandaId) {
        final int id when id > 0 => DemandaDetalhePage(demandaId: id),
        _ => const _ArgumentoDetalheInvalidoPage(),
      },
      sprint => const SprintPage(),
      _ when rotaDetalheSprint => switch (sprintId) {
        final int id when id > 0 => SprintDetalhePage(sprintId: id),
        _ => const _ArgumentoSprintInvalidoPage(),
      },
      logTime => const LogTimePage(),
      relatorios => const RelatoriosPage(),
      perfil => const MeuPerfilPage(),
      _ => const DemandasPage(),
    };
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}

class _ArgumentoSprintInvalidoPage extends StatelessWidget {
  const _ArgumentoSprintInvalidoPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhes da Sprint')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_off_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Não foi possível abrir esta Sprint.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'O identificador informado é inválido.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.sprint),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para Sprints'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ArgumentoDetalheInvalidoPage extends StatelessWidget {
  const _ArgumentoDetalheInvalidoPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalhes da demanda')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_off_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Não foi possível abrir esta demanda.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'O identificador informado é inválido.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.demandas),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar para demandas'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
