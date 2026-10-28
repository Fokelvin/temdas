import 'package:flutter/material.dart';

import 'app/temdas_app.dart';
import 'data/serverpod_client.dart';
import 'data/supabase_session.dart';
import 'data/auth_callback_storage.dart';

Future<void> main() async {
  final startupUri = Uri.base;
  WidgetsFlutterBinding.ensureInitialized();

  if (isAuthCallbackLocation(startupUri) ||
      isAuthConfirmationLocation(startupUri)) {
    // Keep the original link only in memory, before any asynchronous SDK init.
    browserCallbackStorage.clearUrl();
  }

  await initializeSupabaseSession();
  serverpodClient.authKeyProvider = supabaseSession;

  runApp(TemdasApp(initialUri: startupUri));
}
