import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';

/// Contract for loan persistence and queries.
abstract class LoanRepository {
  Future<Either<Failure, List<Loan>>> getBorrowerLoans(String borrowerId);

  Future<Either<Failure, Loan>> getLoanDetails(String loanId);

  Future<Either<Failure, LoanApplication>> applyForLoan(
    ApplyForLoanParams params,
  );

  Future<Either<Failure, List<LoanApplication>>> getLoanApplications({
    DateTime? requestedAfter,
  });

  Future<Either<Failure, List<LoanApplication>>> getBorrowerApplications(
    String borrowerId,
  );

  Future<Either<Failure, List<Loan>>> getAllLoans();
}
