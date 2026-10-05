import 'package:temdas_backend_client/temdas_backend_client.dart';

import 'supabase_session.dart';

final serverpodClient = Client(
  const String.fromEnvironment(
    'SERVERPOD_URL',
    defaultValue: 'http://localhost:8080/',
  ),
)..authKeyProvider = supabaseSession;
