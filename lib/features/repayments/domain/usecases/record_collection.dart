import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';
import 'package:local_lending_app/features/repayments/domain/repositories/repayment_repository.dart';

class RecordCollection {
  const RecordCollection(this._repository);

  final RepaymentRepository _repository;

  Future<Either<Failure, RepaymentRecord>> call(RecordCollectionParams params) {
    if (params.loanId.trim().isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Loan id is required.')),
      );
    }
    if (params.amountRupees <= 0) {
      return Future.value(
        const Left(
          ValidationFailure('Collection amount must be greater than zero.'),
        ),
      );
    }
    return _repository.recordCollection(params);
  }
}
