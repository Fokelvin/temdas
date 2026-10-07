import 'package:temdas_backend_client/temdas_backend_client.dart';

final serverpodClient = Client(
  const String.fromEnvironment(
    'SERVERPOD_URL',
    defaultValue: 'http://localhost:8080/',
  ),
);