import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:temdas/view/totp_enrollment_qr.dart';

void main() {
  testWidgets('QR encodes the URI supplied by the Supabase enrollment', (
    tester,
  ) async {
    const uri =
        'otpauth://totp/Example:user?secret=server-returned&issuer=Example';

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: Size(400, 800)),
          child: MaterialApp(
            home: Scaffold(
              body: TotpEnrollmentQr(uri: uri, secret: 'server-returned'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(QrImageView), findsOneWidget);
    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();
    expect(find.text('URI: $uri'), findsOneWidget);
  });
}
