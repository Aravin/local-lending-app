import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';
import 'package:local_lending_app/features/repayments/domain/repositories/repayment_repository.dart';

class GetRepaymentHistory {
  const GetRepaymentHistory(this._repository);

  final RepaymentRepository _repository;

  Future<Either<Failure, List<RepaymentRecord>>> call({
    String? loanId,
    String? borrowerId,
  }) {
    if ((loanId == null || loanId.trim().isEmpty) &&
        (borrowerId == null || borrowerId.trim().isEmpty)) {
      return Future.value(
        const Left(
          ValidationFailure(
            'Provide a loan id or borrower id to load history.',
          ),
        ),
      );
    }
    return _repository.getRepaymentHistory(
      loanId: loanId,
      borrowerId: borrowerId,
    );
  }
}
