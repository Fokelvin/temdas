import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Shows the Supabase-provided authenticator URI as a QR code.
class TotpEnrollmentQr extends StatelessWidget {
  final String uri;
  final String secret;

  const TotpEnrollmentQr({super.key, required this.uri, required this.secret});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Escaneie este QR Code no aplicativo autenticador:'),
      Center(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.all(12),
          child: QrImageView(
            data: uri,
            version: QrVersions.auto,
            size: 220,
            semanticsLabel: 'QR Code para configurar o aplicativo autenticador',
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'Ou informe esta chave manualmente no aplicativo autenticador:',
      ),
      SelectableText(
        secret,
        semanticsLabel: 'Chave manual do autenticador: $secret',
      ),
      const SizedBox(height: 8),
      const Text(
        'Guarde essa chave com segurança. Ela só aparece durante a configuração.',
      ),
    ],
  );
}
