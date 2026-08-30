import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';

void main() {
  KycProfile profile({
    KycStatus status = KycStatus.verified,
    DateTime? verifiedAt,
  }) {
    return KycProfile(
      userId: 'u1',
      fullName: 'Priya',
      status: status,
      verifiedAt: verifiedAt,
    );
  }

  test('expires one year after verification date', () {
    final kyc = profile(verifiedAt: DateTime(2025, 8, 15));
    expect(kyc.expiresAt, DateTime(2026, 8, 15));
  });

  test('marks verified KYC expired on the anniversary', () {
    final kyc = profile(verifiedAt: DateTime(2025, 8, 15));
    expect(kyc.isExpired(DateTime(2026, 8, 15)), isTrue);
    expect(kyc.effectiveStatus(DateTime(2026, 8, 15)), KycStatus.expired);
    expect(kyc.isExpired(DateTime(2026, 8, 14)), isFalse);
  });

  test('flags renewal in the last 30 days of validity', () {
    final kyc = profile(verifiedAt: DateTime(2025, 8, 15));
    expect(kyc.isExpiringSoon(DateTime(2026, 7, 20)), isTrue);
    expect(kyc.canSubmit(DateTime(2026, 7, 20)), isTrue);
    expect(kyc.canSubmit(DateTime(2025, 9, 1)), isFalse);
  });

  test('allows lending after KYC is submitted or verified', () {
    expect(profile(status: KycStatus.pending).allowsLending(), isFalse);
    expect(profile(status: KycStatus.submitted).allowsLending(), isTrue);
    expect(
      profile(
        status: KycStatus.verified,
        verifiedAt: DateTime(2026, 1, 1),
      ).allowsLending(DateTime(2026, 6, 1)),
      isTrue,
    );
    expect(
      profile(
        status: KycStatus.verified,
        verifiedAt: DateTime(2025, 1, 1),
      ).allowsLending(DateTime(2026, 6, 1)),
      isFalse,
    );
  });

  test('can explicitly clear a previous rejection reason', () {
    const rejected = KycProfile(
      userId: 'u1',
      fullName: 'Priya',
      status: KycStatus.rejected,
      rejectionReason: 'Unreadable proof',
    );

    final approved = rejected.copyWith(
      status: KycStatus.verified,
      clearRejectionReason: true,
    );

    expect(approved.rejectionReason, isNull);
  });
}
