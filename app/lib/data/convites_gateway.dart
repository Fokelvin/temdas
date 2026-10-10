import 'serverpod_client.dart';

/// Narrow client boundary for the administrative invite endpoints.
class ConvitesGateway {
  const ConvitesGateway({
    required this.consultar,
    required this.convidar,
    required this.reenviar,
  });

  factory ConvitesGateway.serverpod() => ConvitesGateway(
    consultar: serverpodClient.convite.consultar,
    convidar: serverpodClient.convite.convidar,
    reenviar: serverpodClient.convite.reenviar,
  );

  final Future<String> Function(String email) consultar;
  final Future<String> Function(String email) convidar;
  final Future<String> Function(String email) reenviar;
}
