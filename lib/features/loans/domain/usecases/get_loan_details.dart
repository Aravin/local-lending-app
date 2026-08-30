import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/repositories/loan_repository.dart';

class GetLoanDetails {
  const GetLoanDetails(this._repository);

  final LoanRepository _repository;

  Future<Either<Failure, Loan>> call(String loanId) {
    if (loanId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Loan id is required.')),
      );
    }
    return _repository.getLoanDetails(loanId);
  }
}
