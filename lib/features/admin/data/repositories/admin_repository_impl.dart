import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/admin/data/datasources/admin_remote_datasource.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/delinquency_bucket.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/portfolio_stats.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl({required this.remoteDataSource});

  final AdminRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, PortfolioStats>> getPortfolioMetrics() {
    return _guard(remoteDataSource.getPortfolioMetrics);
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

  @override
  Future<Either<Failure, LoanApplication>> updateLoanStatus(
    UpdateLoanStatusParams params,
  ) {
    return _guard(() async {
      final model = await remoteDataSource.updateLoanStatus(params);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<CustomerProfile>>> getCustomers({String? query}) {
    return _guard(() async {
      final models = await remoteDataSource.getCustomers(query: query);
      return models.map((model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, Loan>> createLoanForUser(CreateLoanParams params) {
    return _guard(() async {
      final model = await remoteDataSource.createLoanForUser(params);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, PortfolioReport>> getPortfolioReport() {
    return _guard(remoteDataSource.getPortfolioReport);
  }

  @override
  Future<Either<Failure, KycProfile>> getKycProfile(String userId) {
    return _guard(() async {
      final model = await remoteDataSource.getKycProfile(userId);
      return model.toEntity().resolved();
    });
  }

  @override
  Future<Either<Failure, List<KycProfile>>> getKycProfiles() {
    return _guard(() async {
      final models = await remoteDataSource.getKycProfiles();
      return models.map((model) => model.toEntity().resolved()).toList();
    });
  }

  @override
  Future<Either<Failure, KycProfile>> submitKyc(KycProfile profile) {
    return _guard(() async {
      final model = await remoteDataSource.submitKyc(profile);
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, String>> uploadKycDocument({
    required String userId,
    required String documentType,
    required String localPath,
  }) {
    return _guard(
      () => remoteDataSource.uploadKycDocument(
        userId: userId,
        documentType: documentType,
        localPath: localPath,
      ),
    );
  }

  @override
  Future<Either<Failure, Uint8List>> getKycDocument(String path) {
    return _guard(() => remoteDataSource.getKycDocument(path));
  }

  @override
  Future<Either<Failure, KycProfile>> reviewKyc(ReviewKycParams params) {
    return _guard(() async {
      final model = await remoteDataSource.reviewKyc(params);
      return model.toEntity();
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
