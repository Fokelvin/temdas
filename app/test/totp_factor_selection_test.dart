import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:temdas/view/totp_factor_selection.dart';

void main() {
  final verified = _factor('verified-factor', FactorStatus.verified);
  final pending = _factor('pending-factor', FactorStatus.unverified);

  test('detects and automatically prioritizes an unverified TOTP factor', () {
    expect(hasUnverifiedTotpFactor([verified, pending]), isTrue);
    expect(
      preferredTotpFactor([
        verified,
        pending,
      ], selectedFactorId: verified.id)?.id,
      pending.id,
    );
  });

  test('keeps a selected verified factor when no pending factor exists', () {
    expect(hasUnverifiedTotpFactor([verified]), isFalse);
    expect(
      preferredTotpFactor([verified], selectedFactorId: verified.id)?.id,
      verified.id,
    );
  });
}

Factor _factor(String id, FactorStatus status) => Factor(
  id: id,
  friendlyName: 'TEMDAS',
  factorType: FactorType.totp,
  status: status,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
