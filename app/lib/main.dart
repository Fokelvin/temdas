import 'package:flutter/material.dart';

import 'app/temdas_app.dart';
import 'data/serverpod_client.dart';
import 'data/supabase_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeSupabaseSession();
  serverpodClient.authKeyProvider = supabaseSession;

  runApp(const TemdasApp());
}