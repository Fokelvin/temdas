import 'package:temdas_backend_client/temdas_backend_client.dart';

final serverpodClient = Client(
  const String.fromEnvironment(
    'SERVERPOD_URL',
    defaultValue: 'http://localhost:8080/',
  ),
  // Serverpod 3.4.11 has a client-wide request timeout, not a per-RPC option.
  // Keep the shared authentication/MFA provider on this single client.
  connectionTimeout: const Duration(seconds: 60),
);
