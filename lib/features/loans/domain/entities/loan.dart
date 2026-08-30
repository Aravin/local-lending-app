import 'package:equatable/equatable.dart';
import 'package:local_lending_app/core/utils/disbursement_policy.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

/// A disbursed (or approved) loan with its repayment schedule.
class Loan extends Equatable {
  const Loan({
    required this.id,
    required this.borrowerId,
    required this.borrowerName,
    required this.purpose,
    required this.status,
    required this.principalRupees,
    required this.annualInterestRatePercent,
    required this.frequency,
    required this.tenure,
    required this.appliedAt,
    required this.schedule,
    this.borrowerPhone,
    this.disbursementDate,
    this.closedDate,
    this.rejectionReason,
    this.counterOfferPrincipalRupees,
    this.applicationId,
    this.disbursementIssueReportedAt,
    this.disbursementIssueReason,
  });

  final String id;
  final String borrowerId;
  final String borrowerName;
  final String? borrowerPhone;
  final LoanPurpose purpose;
  final LoanStatus status;
  final double principalRupees;
  final double annualInterestRatePercent;
  final RepaymentFrequency frequency;
  final int tenure;
  final DateTime appliedAt;
  final DateTime? disbursementDate;
  final DateTime? closedDate;
  final RepaymentSchedule schedule;
  final String? rejectionReason;
  final double? counterOfferPrincipalRupees;
  final String? applicationId;
  final DateTime? disbursementIssueReportedAt;
  final String? disbursementIssueReason;

  double get outstandingRupees => schedule.outstandingRupees;

  double get totalPaidRupees => schedule.totalPaidRupees;

  RepaymentInstallment? get nextDue => schedule.nextDue;

  bool get isFullyPaid => schedule.isCompleted;

  bool canConfirmReceipt() {
    return DisbursementPolicy.canConfirmReceipt(
      status: status,
      disbursementDate: disbursementDate,
      issueReportedAt: disbursementIssueReportedAt,
    );
  }

  bool canReportDisbursementIssue([DateTime? now]) {
    return DisbursementPolicy.canReportIssue(
      status: status,
      disbursementDate: disbursementDate,
      now: now ?? DateTime.now(),
      issueReportedAt: disbursementIssueReportedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    borrowerId,
    borrowerName,
    borrowerPhone,
    purpose,
    status,
    principalRupees,
    annualInterestRatePercent,
    frequency,
    tenure,
    appliedAt,
    disbursementDate,
    closedDate,
    schedule,
    rejectionReason,
    counterOfferPrincipalRupees,
    applicationId,
    disbursementIssueReportedAt,
    disbursementIssueReason,
  ];

  Loan copyWith({
    LoanStatus? status,
    RepaymentSchedule? schedule,
    DateTime? disbursementDate,
    DateTime? closedDate,
    String? rejectionReason,
    double? counterOfferPrincipalRupees,
    String? applicationId,
    DateTime? disbursementIssueReportedAt,
    String? disbursementIssueReason,
    bool clearDisbursementIssue = false,
  }) {
    return Loan(
      id: id,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      purpose: purpose,
      status: status ?? this.status,
      principalRupees: principalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
      frequency: frequency,
      tenure: tenure,
      appliedAt: appliedAt,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      closedDate: closedDate ?? this.closedDate,
      schedule: schedule ?? this.schedule,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      counterOfferPrincipalRupees:
          counterOfferPrincipalRupees ?? this.counterOfferPrincipalRupees,
      applicationId: applicationId ?? this.applicationId,
      disbursementIssueReportedAt: clearDisbursementIssue
          ? null
          : disbursementIssueReportedAt ?? this.disbursementIssueReportedAt,
      disbursementIssueReason: clearDisbursementIssue
          ? null
          : disbursementIssueReason ?? this.disbursementIssueReason,
    );
  }
}
