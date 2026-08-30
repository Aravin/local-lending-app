import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';

class GetCustomers {
  const GetCustomers(this._repository);

  final AdminRepository _repository;

  Future<Either<Failure, List<CustomerProfile>>> call({String? query}) {
    return _repository.getCustomers(query: query);
  }
}
