import 'package:flutter/material.dart';

import 'app_routes.dart';

class TemdasApp extends StatelessWidget {
  const TemdasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEMDAS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff4f46e5),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7f7fb),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            side: BorderSide(color: Color(0xffe8e7ef)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: Navigator.defaultRouteName,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
