import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';

abstract class RepaymentRepository {
  Future<Either<Failure, RepaymentRecord>> makeRepayment(
    MakeRepaymentParams params,
  );

  Future<Either<Failure, List<RepaymentRecord>>> getRepaymentHistory({
    String? loanId,
    String? borrowerId,
  });

  Future<Either<Failure, RepaymentRecord>> recordCollection(
    RecordCollectionParams params,
  );

  Future<Either<Failure, List<CollectionEntry>>> getDailyCollectionSheet(
    DateTime date,
  );
}
