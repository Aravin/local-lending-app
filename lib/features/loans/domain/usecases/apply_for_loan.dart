import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/repositories/loan_repository.dart';

class ApplyForLoan {
  const ApplyForLoan(this._repository);

  final LoanRepository _repository;

  Future<Either<Failure, LoanApplication>> call(ApplyForLoanParams params) {
    if (params.borrowerId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Borrower id is required.')),
      );
    }
    if (params.amountRupees <= 0) {
      return Future.value(
        const Left(ValidationFailure('Loan amount must be greater than zero.')),
      );
    }
    final frequency = params.frequency;
    if (params.tenure < frequency.minTenure ||
        params.tenure > frequency.maxTenure) {
      return Future.value(
        Left(
          ValidationFailure(
            'Tenure must be ${frequency.minTenure}–${frequency.maxTenure} '
            '${frequency.tenureUnit}.',
          ),
        ),
      );
    }
    if (params.annualInterestRatePercent < 12 ||
        params.annualInterestRatePercent > 48) {
      return Future.value(
        const Left(ValidationFailure('Interest rate must be 12–48% p.a.')),
      );
    }
    return _repository.applyForLoan(params);
  }
}
