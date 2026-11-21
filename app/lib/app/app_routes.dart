import 'package:flutter/material.dart';
import 'package:temdas_backend_client/temdas_backend_client.dart' as backend;

import '../ui/components/app_link.dart';
import 'auth_gate.dart';
import 'public_home_entry.dart';

import '../view/demanda_detalhe_page.dart';
import '../view/demandas_page.dart';
import '../view/log_time_page.dart';
import '../view/meu_perfil_page.dart';
import '../view/relatorios_page.dart';
import '../view/sprint_page.dart';
import '../view/auth_callback_page.dart';
import '../view/todo_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const demandas = '/demandas';
  static const backlog = '/backlog';
  static const authCallback = '/auth/callback';
  static const authConfirm = '/auth/confirm';
  static const demandaDetalhe = '/demandas/detalhe';
  static const sprint = '/sprint';
  static const logTime = '/log-time';
  static const relatorios = '/relatorios';
  static const todos = '/to-dos';
  static const perfil = '/perfil';

  static String detalheDaDemanda(int demandaId) => Uri(
    path: demandaDetalhe,
    queryParameters: {'id': demandaId.toString()},
  ).toString();

  static String detalheDaSprint(int sprintId) => '$sprint/$sprintId';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    Uri? callbackUri,
    bool protectPrivateRoutes = false,
    bool preserveLocationOnNotFound = false,
  }) {
    final uri = _parseLocation(settings.name ?? Navigator.defaultRouteName);
    final path = uri?.path;
    final demandaId =
        path == demandaDetalhe || path == demandas || path == backlog
        ? switch (settings.arguments) {
            final int id when id > 0 => id,
            _ => _positiveId(_queryValue(uri!, 'id')),
          }
        : null;
    final sprintId = path != null && path.startsWith('$sprint/')
        ? _positiveId(path.substring(sprint.length + 1))
        : null;
    final page = switch (path) {
      home => PublicHomeEntry(section: _queryValue(uri!, 'secao')),
      demandas => DemandasPage(demandaInicialId: demandaId),
      backlog => DemandasPage(
        localizacao: backend.DemandaLocalizacao.backlog,
        demandaInicialId: demandaId,
      ),
      authCallback => AuthCallbackPage(uri: callbackUri ?? Uri.base),
      authConfirm => AuthCallbackPage.confirm(uri: callbackUri ?? Uri.base),
      demandaDetalhe when demandaId != null => DemandaDetalhePage(
        demandaId: demandaId,
      ),
      sprint => const SprintPage(),
      _ when sprintId != null => SprintDetalhePage(sprintId: sprintId),
      logTime => const LogTimePage(),
      relatorios => const RelatoriosPage(),
      todos => const TodoPage(),
      perfil => const MeuPerfilPage(),
      _ => const _PaginaNaoEncontrada(),
    };
    final publico = switch (page) {
      PublicHomeEntry() || AuthCallbackPage() || _PaginaNaoEncontrada() => true,
      _ => false,
    };
    return MaterialPageRoute(
      builder: (_) => protectPrivateRoutes && !publico
          ? AuthGate(session: null, child: page)
          : page,
      // Keep the 404 unnamed when the browser location is managed separately.
      settings: preserveLocationOnNotFound && page is _PaginaNaoEncontrada
          ? const RouteSettings()
          : settings,
    );
  }

  static Uri? _parseLocation(String location) {
    if (!location.startsWith('/')) return null;
    final uri = Uri.tryParse(location);
    if (uri == null || uri.hasAuthority || uri.hasFragment) return null;
    return uri;
  }

  static String? _queryValue(Uri uri, String name) {
    try {
      return switch (uri.queryParametersAll[name]) {
        [final value] => value,
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }

  static final _decimalId = RegExp(r'^[0-9]+$');

  static int? _positiveId(String? value) {
    if (value == null || !_decimalId.hasMatch(value)) return null;
    final id = int.tryParse(value, radix: 10);
    return id != null && id > 0 ? id : null;
  }
}

class _PaginaNaoEncontrada extends StatelessWidget {
  const _PaginaNaoEncontrada();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('404')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 412),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 52,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Página não encontrada',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'O endereço informado não corresponde a uma página do TEMDAS.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AppLink(
                route: AppRoutes.home,
                onFollow: () =>
                    Navigator.pushReplacementNamed(context, AppRoutes.home),
                builder: (follow) => FilledButton.icon(
                  onPressed: follow,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Voltar para a Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
