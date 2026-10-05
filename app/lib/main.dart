import 'package:flutter/material.dart';

import 'app/temdas_app.dart';
import 'data/supabase_session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabaseSession();
  runApp(const TemdasApp());
}
