import 'package:supabase_flutter/supabase_flutter.dart';

bool hasUnverifiedTotpFactor(Iterable<Factor> factors) => factors.any(
  (factor) =>
      factor.factorType == FactorType.totp &&
      factor.status == FactorStatus.unverified,
);

Factor? preferredTotpFactor(
  Iterable<Factor> factors, {
  String? selectedFactorId,
}) {
  final totpFactors = factors
      .where((factor) => factor.factorType == FactorType.totp)
      .toList();
  return totpFactors
          .where((factor) => factor.status == FactorStatus.unverified)
          .firstOrNull ??
      totpFactors
          .where((factor) => factor.id == selectedFactorId)
          .firstOrNull ??
      totpFactors
          .where((factor) => factor.status == FactorStatus.verified)
          .firstOrNull;
}
