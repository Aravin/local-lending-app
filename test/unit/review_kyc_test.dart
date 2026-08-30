import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/review_kyc.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late _MockAdminRepository repository;
  late ReviewKyc reviewKyc;

  setUp(() {
    repository = _MockAdminRepository();
    reviewKyc = ReviewKyc(repository);
  });

  test('requires a rejection reason', () async {
    final result = await reviewKyc(
      const ReviewKycParams(userId: 'u1', status: KycStatus.rejected),
    );
    expect(
      result,
      const Left(ValidationFailure('A rejection reason is required.')),
    );
  });

  test('approves a submitted KYC', () async {
    const params = ReviewKycParams(userId: 'u1', status: KycStatus.verified);
    final saved = KycProfile(
      userId: 'u1',
      fullName: 'Priya',
      status: KycStatus.verified,
      verifiedAt: DateTime(2026, 8, 15),
    );
    when(
      () => repository.reviewKyc(params),
    ).thenAnswer((_) async => Right(saved));

    final result = await reviewKyc(params);
    expect(result, Right(saved));
  });
}
