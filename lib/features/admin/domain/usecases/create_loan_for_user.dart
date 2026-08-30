import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';

class CreateLoanForUser {
  const CreateLoanForUser(this._repository);

  final AdminRepository _repository;

  Future<Either<Failure, Loan>> call(CreateLoanParams params) {
    if (params.borrowerId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Select a borrower to create a loan.')),
      );
    }
    if (params.principalRupees <= 0) {
      return Future.value(
        const Left(ValidationFailure('Principal must be greater than zero.')),
      );
    }
    if (params.tenure < params.frequency.minTenure ||
        params.tenure > params.frequency.maxTenure) {
      return Future.value(
        Left(
          ValidationFailure(
            'Tenure must be ${params.frequency.minTenure}–${params.frequency.maxTenure} '
            '${params.frequency.tenureUnit}.',
          ),
        ),
      );
    }
    return _repository.createLoanForUser(params);
  }
}
