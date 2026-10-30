import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_preference.dart';
import 'auth_gate.dart';
import 'app_routes.dart';

class TemdasApp extends StatefulWidget {
  const TemdasApp({super.key, this.initialUri});

  final Uri? initialUri;

  @override
  State<TemdasApp> createState() => _TemdasAppState();
}

class _TemdasAppState extends State<TemdasApp> {
  final _theme = ThemePreference();

  @override
  void initState() {
    super.initState();
    _theme.load();
  }

  @override
  void dispose() {
    _theme.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startupUri = widget.initialUri ?? Uri.base;
    final isCallback = isAuthCallbackLocation(startupUri);
    final authRoute = startupUri.path == AppRoutes.authCallback
        ? AppRoutes.authCallback
        : isAuthConfirmationLocation(startupUri)
        ? AppRoutes.authConfirm
        : isCallback
        ? AppRoutes.authCallback
        : null;
    final initialRoute = authRoute ?? initialAppLocation(startupUri);
    return ThemePreferenceScope(
      notifier: _theme,
      child: ListenableBuilder(
        listenable: _theme,
        builder: (context, _) => MaterialApp(
          title: 'TEMDAS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _theme.mode,
          initialRoute: initialRoute,
          onGenerateInitialRoutes: (route) => [
            _onGenerateRoute(
              RouteSettings(name: authRoute ?? route),
              callbackUri: authRoute != null ? startupUri : null,
            ),
          ],
          onGenerateRoute: _onGenerateRoute,
        ),
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings, {Uri? callbackUri}) {
    final route = AppRoutes.onGenerateRoute(settings, callbackUri: callbackUri);
    if (const {
      AppRoutes.home,
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

/// Keeps clean and hash deep links while making only the root public.
String initialAppLocation(Uri uri) {
  if (uri.scheme != 'https' && uri.scheme != 'http') return AppRoutes.home;
  final fragment = Uri.tryParse(uri.fragment);
  if (fragment != null &&
      fragment.path.startsWith('/') &&
      fragment.path != '/') {
    return fragment.toString();
  }
  if (uri.path.isNotEmpty && uri.path != '/') {
    return Uri(
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
    ).toString();
  }
  return AppRoutes.home;
}
