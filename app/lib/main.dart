import 'package:flutter/material.dart';

import 'app/temdas_app.dart';
import 'data/serverpod_client.dart';
import 'data/supabase_session.dart';

Future<void> main() async {
  final startupUri = Uri.base;
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSupabaseSession();
  serverpodClient.authKeyProvider = supabaseSession;

  runApp(TemdasApp(initialUri: startupUri));
}
