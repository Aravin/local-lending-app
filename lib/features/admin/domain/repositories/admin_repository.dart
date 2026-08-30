import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/delinquency_bucket.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/portfolio_stats.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';

class UpdateLoanStatusParams extends Equatable {
  const UpdateLoanStatusParams({
    required this.applicationId,
    required this.status,
    this.rejectionReason,
    this.counterOfferPrincipalRupees,
    this.disbursementDate,
    this.issueReason,
  });

  final String applicationId;
  final LoanStatus status;
  final String? rejectionReason;
  final double? counterOfferPrincipalRupees;
  final DateTime? disbursementDate;
  final String? issueReason;

  @override
  List<Object?> get props => [
    applicationId,
    status,
    rejectionReason,
    counterOfferPrincipalRupees,
    disbursementDate,
    issueReason,
  ];
}

class CreateLoanParams extends Equatable {
  const CreateLoanParams({
    required this.borrowerId,
    required this.borrowerName,
    required this.principalRupees,
    required this.annualInterestRatePercent,
    required this.tenure,
    required this.frequency,
    required this.disbursementDate,
    required this.purpose,
    this.borrowerPhone,
  });

  final String borrowerId;
  final String borrowerName;
  final String? borrowerPhone;
  final double principalRupees;
  final double annualInterestRatePercent;
  final int tenure;
  final RepaymentFrequency frequency;
  final DateTime disbursementDate;
  final LoanPurpose purpose;

  @override
  List<Object?> get props => [
    borrowerId,
    borrowerName,
    borrowerPhone,
    principalRupees,
    annualInterestRatePercent,
    tenure,
    frequency,
    disbursementDate,
    purpose,
  ];
}

abstract class AdminRepository {
  Future<Either<Failure, PortfolioStats>> getPortfolioMetrics();

  Future<Either<Failure, List<CollectionEntry>>> getDailyCollectionSheet(
    DateTime date,
  );

  Future<Either<Failure, LoanApplication>> updateLoanStatus(
    UpdateLoanStatusParams params,
  );

  Future<Either<Failure, List<CustomerProfile>>> getCustomers({String? query});

  Future<Either<Failure, Loan>> createLoanForUser(CreateLoanParams params);

  Future<Either<Failure, PortfolioReport>> getPortfolioReport();

  Future<Either<Failure, KycProfile>> getKycProfile(String userId);

  Future<Either<Failure, List<KycProfile>>> getKycProfiles();

  Future<Either<Failure, KycProfile>> submitKyc(KycProfile profile);

  Future<Either<Failure, String>> uploadKycDocument({
    required String userId,
    required String documentType,
    required String localPath,
  });

  Future<Either<Failure, Uint8List>> getKycDocument(String path);

  Future<Either<Failure, KycProfile>> reviewKyc(ReviewKycParams params);
}

class ReviewKycParams extends Equatable {
  const ReviewKycParams({
    required this.userId,
    required this.status,
    this.rejectionReason,
  });

  final String userId;
  final KycStatus status;
  final String? rejectionReason;

  @override
  List<Object?> get props => [userId, status, rejectionReason];
}
