import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

class UpdateLoanStatus {
  const UpdateLoanStatus(this._repository);

  final AdminRepository _repository;

  Future<Either<Failure, LoanApplication>> call(UpdateLoanStatusParams params) {
    if (params.applicationId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Application id is required.')),
      );
    }
    if (params.status == LoanStatus.rejected &&
        (params.rejectionReason == null ||
            params.rejectionReason!.trim().isEmpty)) {
      return Future.value(
        const Left(ValidationFailure('A rejection reason is required.')),
      );
    }
    if (params.status == LoanStatus.approved &&
        params.counterOfferPrincipalRupees != null &&
        params.counterOfferPrincipalRupees! <= 0) {
      return Future.value(
        const Left(ValidationFailure('Counter-offer amount must be positive.')),
      );
    }
    if (params.status == LoanStatus.fundIssue &&
        (params.issueReason == null || params.issueReason!.trim().isEmpty)) {
      return Future.value(
        const Left(ValidationFailure('Describe the fund issue.')),
      );
    }
    const allowed = {
      LoanStatus.approved,
      LoanStatus.rejected,
      LoanStatus.disbursed,
      LoanStatus.fundIssue,
    };
    if (!allowed.contains(params.status)) {
      return Future.value(
        const Left(ValidationFailure('Unsupported loan status change.')),
      );
    }
    return _repository.updateLoanStatus(params);
  }
}
