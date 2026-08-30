import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/loans/data/datasources/loan_remote_datasource.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/repositories/loan_repository.dart';

class LoanRepositoryImpl implements LoanRepository {
  const LoanRepositoryImpl({required this.remoteDataSource});

  final LoanRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, List<Loan>>> getBorrowerLoans(String borrowerId) {
    return _guard(() async {
      final models = await remoteDataSource.getBorrowerLoans(borrowerId);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, Loan>> getLoanDetails(String loanId) {
    return _guard(() async {
      final model = await remoteDataSource.getLoanDetails(loanId);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, LoanApplication>> applyForLoan(
    ApplyForLoanParams params,
  ) {
    return _guard(() async {
      final model = await remoteDataSource.applyForLoan(params);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<LoanApplication>>> getLoanApplications({
    DateTime? requestedAfter,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getLoanApplications(
        requestedAfter: requestedAfter,
      );
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<LoanApplication>>> getBorrowerApplications(
    String borrowerId,
  ) {
    return _guard(() async {
      final models = await remoteDataSource.getBorrowerApplications(borrowerId);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<Loan>>> getAllLoans() {
    return _guard(() async {
      final models = await remoteDataSource.getAllLoans();
      return models.map((model) => model.toEntity()).toList();
    });
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}
