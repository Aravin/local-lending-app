import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';

class GetDailyCollectionSheet {
  const GetDailyCollectionSheet(this._repository);

  final AdminRepository _repository;

  Future<Either<Failure, List<CollectionEntry>>> call(DateTime date) {
    return _repository.getDailyCollectionSheet(date);
  }
}
