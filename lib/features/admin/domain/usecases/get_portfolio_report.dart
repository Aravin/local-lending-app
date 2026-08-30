import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/entities/delinquency_bucket.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';

class GetPortfolioReport {
  const GetPortfolioReport(this._repository);

  final AdminRepository _repository;

  Future<Either<Failure, PortfolioReport>> call() {
    return _repository.getPortfolioReport();
  }
}
