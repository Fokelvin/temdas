import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'auth_gate.dart';
import 'app_routes.dart';

class TemdasApp extends StatelessWidget {
  const TemdasApp({super.key, this.initialUri});

  final Uri? initialUri;

  @override
  Widget build(BuildContext context) {
    final startupUri = initialUri ?? Uri.base;
    final isCallback = isAuthCallbackLocation(startupUri);
    final initialRoute = isCallback
        ? AppRoutes.authCallback
        : AppRoutes.demandas;
    return MaterialApp(
      title: 'TEMDAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      onGenerateInitialRoutes: (route) => [
        _onGenerateRoute(
          RouteSettings(name: isCallback ? AppRoutes.authCallback : route),
          callbackUri: isCallback ? startupUri : null,
        ),
      ],
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings, {Uri? callbackUri}) {
    final route = AppRoutes.onGenerateRoute(settings, callbackUri: callbackUri);
    if (Uri.tryParse(settings.name ?? '')?.path == AppRoutes.authCallback) {
      return route;
    }
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => AuthGate(
        session: null,
        child: (route as MaterialPageRoute).builder(context),
      ),
    );
  }
}

bool isAuthCallbackLocation(Uri uri) {
  if (uri.path == AppRoutes.authCallback) return true;
  final fragment = Uri.tryParse(uri.fragment);
  return fragment?.path == AppRoutes.authCallback;
}
