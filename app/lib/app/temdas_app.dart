import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/theme_preference.dart';
import 'app_routes.dart';

class TemdasApp extends StatefulWidget {
  const TemdasApp({super.key, this.initialUri});

  final Uri? initialUri;

  @override
  State<TemdasApp> createState() => _TemdasAppState();
}

class _TemdasAppState extends State<TemdasApp> with WidgetsBindingObserver {
  final _theme = ThemePreference();
  final _navigator = GlobalKey<NavigatorState>();
  Uri get _startupUri => widget.initialUri ?? Uri.base;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _theme.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _theme.dispose();
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(
    RouteInformation routeInformation,
  ) async {
    final navigator = _navigator.currentState;
    if (navigator == null || !_isHttpLocation(_startupUri)) return false;

    final location = routeInformation.uri.toString();
    final route = _onGenerateRoute(
      RouteSettings(name: location),
      preserveLocationOnNotFound: true,
    );
    navigator.push(route);
    if (route.settings.name == null) {
      // The engine normalizes the URI sent by a named route. Pass the original
      // hash route as a location so the 404 retains the address the user entered.
      await SystemChannels.navigation.invokeMethod<void>(
        'routeInformationUpdated',
        {'location': location},
      );
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final startupUri = _startupUri;
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
          navigatorKey: _navigator,
          title: 'TEMDAS',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _theme.mode,
          initialRoute: initialRoute,
          onGenerateInitialRoutes: (route) => [
            _onGenerateRoute(
              RouteSettings(
                name: _isHttpLocation(startupUri)
                    ? initialRoute
                    : authRoute ?? route,
              ),
              callbackUri: authRoute != null ? startupUri : null,
              preserveLocationOnNotFound: true,
            ),
          ],
          onGenerateRoute: _onGenerateRoute,
        ),
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(
    RouteSettings settings, {
    Uri? callbackUri,
    bool preserveLocationOnNotFound = false,
  }) => AppRoutes.onGenerateRoute(
    settings,
    callbackUri: callbackUri,
    protectPrivateRoutes: true,
    preserveLocationOnNotFound: preserveLocationOnNotFound,
  );
}

bool isAuthCallbackLocation(Uri uri) =>
    _matchesAuthLocation(uri, AppRoutes.authCallback);

bool isAuthConfirmationLocation(Uri uri) =>
    _matchesAuthLocation(uri, AppRoutes.authConfirm);

bool _matchesAuthLocation(Uri uri, String route) {
  if (uri.path == route) return true;
  if (uri.path.isNotEmpty && uri.path != AppRoutes.home) return false;
  final fragment = Uri.tryParse(uri.fragment);
  return fragment != null &&
      !fragment.hasAuthority &&
      !fragment.hasScheme &&
      fragment.path == route;
}

bool _isHttpLocation(Uri uri) => uri.scheme == 'https' || uri.scheme == 'http';

/// The hash route is relative to the app entry point at the root.
String initialAppLocation(Uri uri) {
  if (!_isHttpLocation(uri)) return AppRoutes.home;
  if (uri.path.isNotEmpty && uri.path != AppRoutes.home) {
    return Uri(
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
    ).toString();
  }
  return uri.fragment.isEmpty ? AppRoutes.home : uri.fragment;
}
