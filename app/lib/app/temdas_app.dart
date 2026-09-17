import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_routes.dart';

class TemdasApp extends StatelessWidget {
  const TemdasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEMDAS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: Navigator.defaultRouteName,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
