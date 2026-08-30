import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/repositories/loan_repository.dart';

class GetBorrowerApplications {
  const GetBorrowerApplications(this._repository);

  final LoanRepository _repository;

  Future<Either<Failure, List<LoanApplication>>> call(String borrowerId) {
    if (borrowerId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Borrower id is required.')),
      );
    }
    return _repository.getBorrowerApplications(borrowerId);
  }
}
