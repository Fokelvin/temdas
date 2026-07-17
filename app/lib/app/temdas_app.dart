import 'package:flutter/material.dart';

import '../view_model/workspace_view_model.dart';
import 'app_routes.dart';

class TemdasApp extends StatefulWidget {
  const TemdasApp({super.key});

  @override
  State<TemdasApp> createState() => _TemdasAppState();
}

class _TemdasAppState extends State<TemdasApp> {
  final _viewModel = WorkspaceViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

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
      initialRoute: AppRoutes.demandas,
      onGenerateRoute: (settings) =>
          AppRoutes.onGenerateRoute(settings, _viewModel),
    );
  }
}
