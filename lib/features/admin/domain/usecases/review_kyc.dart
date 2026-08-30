import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';

class ReviewKyc {
  const ReviewKyc(this._repository);

  final AdminRepository _repository;

  Future<Either<Failure, KycProfile>> call(ReviewKycParams params) {
    if (params.userId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('User id is required.')),
      );
    }
    if (params.status != KycStatus.verified &&
        params.status != KycStatus.rejected) {
      return Future.value(
        const Left(
          ValidationFailure(
            'KYC review must approve or reject the submission.',
          ),
        ),
      );
    }
    if (params.status == KycStatus.rejected &&
        (params.rejectionReason == null ||
            params.rejectionReason!.trim().isEmpty)) {
      return Future.value(
        const Left(ValidationFailure('A rejection reason is required.')),
      );
    }
    return _repository.reviewKyc(params);
  }
}
