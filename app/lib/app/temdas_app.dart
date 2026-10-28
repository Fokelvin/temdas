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
    final authRoute = startupUri.path == AppRoutes.authCallback
        ? AppRoutes.authCallback
        : isAuthConfirmationLocation(startupUri)
        ? AppRoutes.authConfirm
        : isCallback
        ? AppRoutes.authCallback
        : null;
    final initialRoute = authRoute ?? AppRoutes.demandas;
    return MaterialApp(
      title: 'TEMDAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      onGenerateInitialRoutes: (route) => [
        _onGenerateRoute(
          RouteSettings(name: authRoute ?? route),
          callbackUri: authRoute != null ? startupUri : null,
        ),
      ],
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings, {Uri? callbackUri}) {
    final route = AppRoutes.onGenerateRoute(settings, callbackUri: callbackUri);
    if (const {
      AppRoutes.authCallback,
      AppRoutes.authConfirm,
    }.contains(Uri.tryParse(settings.name ?? '')?.path)) {
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

bool isAuthConfirmationLocation(Uri uri) {
  if (uri.path == AppRoutes.authConfirm) return true;
  return Uri.tryParse(uri.fragment)?.path == AppRoutes.authConfirm;
}
