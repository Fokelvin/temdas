import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/app/auth_gate.dart';

void main() {
  group('resolveAuthGateState', () {
    test('sem sessão mostra login mesmo que AAL esteja ausente', () {
      expect(
        resolveAuthGateState(
          hasSession: false,
          aal: null,
          hasVerifiedTotp: false,
        ),
        AuthGateState.signedOut,
      );
    });

    test('sessão aal1 sem TOTP solicita enrollment', () {
      expect(
        resolveAuthGateState(
          hasSession: true,
          aal: AuthenticatorAssuranceLevels.aal1,
          hasVerifiedTotp: false,
        ),
        AuthGateState.enroll,
      );
    });

    test('sessão aal1 com TOTP verificado solicita challenge', () {
      expect(
        resolveAuthGateState(
          hasSession: true,
          aal: AuthenticatorAssuranceLevels.aal1,
          hasVerifiedTotp: true,
        ),
        AuthGateState.challenge,
      );
    });

    test('sessão aal2 libera TEMDAS independentemente da lista de fatores', () {
      expect(
        resolveAuthGateState(
          hasSession: true,
          aal: AuthenticatorAssuranceLevels.aal2,
          hasVerifiedTotp: false,
        ),
        AuthGateState.authenticated,
      );
    });
  });
}
