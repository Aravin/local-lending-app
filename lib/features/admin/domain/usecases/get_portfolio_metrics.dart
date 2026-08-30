import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/entities/portfolio_stats.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';

class GetPortfolioMetrics {
  const GetPortfolioMetrics(this._repository);

  final AdminRepository _repository;

  Future<Either<Failure, PortfolioStats>> call() {
    return _repository.getPortfolioMetrics();
  }
}
