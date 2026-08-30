import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';

class GetKycProfiles {
  const GetKycProfiles(this._repository);

  final AdminRepository _repository;

  Future<Either<Failure, List<KycProfile>>> call() {
    return _repository.getKycProfiles();
  }
}
