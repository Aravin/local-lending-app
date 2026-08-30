import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/repositories/loan_repository.dart';

class GetLoanApplications {
  const GetLoanApplications(this._repository);

  final LoanRepository _repository;

  Future<Either<Failure, List<LoanApplication>>> call({
    DateTime? requestedAfter,
  }) {
    return _repository.getLoanApplications(requestedAfter: requestedAfter);
  }
}
