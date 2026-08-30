import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/repayments/data/datasources/repayment_remote_datasource.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';
import 'package:local_lending_app/features/repayments/domain/repositories/repayment_repository.dart';

class RepaymentRepositoryImpl implements RepaymentRepository {
  const RepaymentRepositoryImpl({required this.remoteDataSource});

  final RepaymentRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, RepaymentRecord>> makeRepayment(
    MakeRepaymentParams params,
  ) {
    return _guard(() async {
      final model = await remoteDataSource.makeRepayment(params);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<RepaymentRecord>>> getRepaymentHistory({
    String? loanId,
    String? borrowerId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getRepaymentHistory(
        loanId: loanId,
        borrowerId: borrowerId,
      );
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, RepaymentRecord>> recordCollection(
    RecordCollectionParams params,
  ) {
    return _guard(() async {
      final model = await remoteDataSource.recordCollection(params);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<CollectionEntry>>> getDailyCollectionSheet(
    DateTime date,
  ) {
    return _guard(() async {
      final models = await remoteDataSource.getDailyCollectionSheet(date);
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
