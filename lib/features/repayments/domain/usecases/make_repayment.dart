import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';
import 'package:local_lending_app/features/repayments/domain/repositories/repayment_repository.dart';

class MakeRepayment {
  const MakeRepayment(this._repository);

  final RepaymentRepository _repository;

  Future<Either<Failure, RepaymentRecord>> call(MakeRepaymentParams params) {
    if (params.loanId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Loan id is required.')),
      );
    }
    if (params.amountRupees <= 0) {
      return Future.value(
        const Left(
          ValidationFailure('Payment amount must be greater than zero.'),
        ),
      );
    }
    return _repository.makeRepayment(params);
  }
}
