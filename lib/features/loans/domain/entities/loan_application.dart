import 'package:equatable/equatable.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/core/utils/disbursement_policy.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

/// A borrower- or admin-initiated request that has not yet been disbursed.
class LoanApplication extends Equatable {
  const LoanApplication({
    required this.id,
    required this.borrowerId,
    required this.borrowerName,
    required this.purpose,
    required this.requestedAmountRupees,
    required this.frequency,
    required this.tenure,
    required this.requestedAt,
    required this.status,
    this.borrowerPhone,
    this.notes,
    this.reviewedAt,
    this.rejectionReason,
    this.counterOfferPrincipalRupees,
    this.annualInterestRatePercent = 24,
    this.loanId,
    this.disbursementDate,
    this.disbursementIssueReportedAt,
    this.disbursementIssueReason,
  });

  final String id;
  final String borrowerId;
  final String borrowerName;
  final String? borrowerPhone;
  final LoanPurpose purpose;
  final double requestedAmountRupees;
  final RepaymentFrequency frequency;
  final int tenure;
  final DateTime requestedAt;
  final LoanStatus status;
  final String? notes;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final double? counterOfferPrincipalRupees;
  final double annualInterestRatePercent;
  final String? loanId;
  final DateTime? disbursementDate;
  final DateTime? disbursementIssueReportedAt;
  final String? disbursementIssueReason;

  bool canReportDisbursementIssue([DateTime? now]) {
    return DisbursementPolicy.canReportIssue(
      status: status,
      disbursementDate: disbursementDate,
      now: now ?? DateTime.now(),
      issueReportedAt: disbursementIssueReportedAt,
    );
  }

  String trackingMessage([DateTime? now]) {
    final clock = now ?? DateTime.now();
    if (status == LoanStatus.disbursed && disbursementDate != null) {
      final deadline = DisbursementPolicy.confirmationDeadline(
        disbursementDate!,
      );
      if (canReportDisbursementIssue(clock)) {
        return 'Funds were released on ${AppDateUtils.formatDisplay(disbursementDate!)}. Report if not received by ${AppDateUtils.formatDisplay(deadline.subtract(const Duration(days: 1)))}. EMI starts from the disbursement date if no issue is reported.';
      }
      return 'Confirmation window closed. EMI started from ${AppDateUtils.formatDisplay(disbursementDate!)}.';
    }
    return status.borrowerMessage;
  }

  @override
  List<Object?> get props => [
    id,
    borrowerId,
    borrowerName,
    borrowerPhone,
    purpose,
    requestedAmountRupees,
    frequency,
    tenure,
    requestedAt,
    status,
    notes,
    reviewedAt,
    rejectionReason,
    counterOfferPrincipalRupees,
    annualInterestRatePercent,
    loanId,
    disbursementDate,
    disbursementIssueReportedAt,
    disbursementIssueReason,
  ];

  LoanApplication copyWith({
    LoanStatus? status,
    String? notes,
    DateTime? reviewedAt,
    String? rejectionReason,
    double? counterOfferPrincipalRupees,
    String? loanId,
    DateTime? disbursementDate,
    DateTime? disbursementIssueReportedAt,
    String? disbursementIssueReason,
    bool clearDisbursementIssue = false,
  }) {
    return LoanApplication(
      id: id,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      purpose: purpose,
      requestedAmountRupees: requestedAmountRupees,
      frequency: frequency,
      tenure: tenure,
      requestedAt: requestedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      counterOfferPrincipalRupees:
          counterOfferPrincipalRupees ?? this.counterOfferPrincipalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
      loanId: loanId ?? this.loanId,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      disbursementIssueReportedAt: clearDisbursementIssue
          ? null
          : disbursementIssueReportedAt ?? this.disbursementIssueReportedAt,
      disbursementIssueReason: clearDisbursementIssue
          ? null
          : disbursementIssueReason ?? this.disbursementIssueReason,
    );
  }
}

/// Input for [ApplyForLoan].
class ApplyForLoanParams extends Equatable {
  const ApplyForLoanParams({
    required this.borrowerId,
    required this.borrowerName,
    required this.purpose,
    required this.amountRupees,
    required this.frequency,
    required this.tenure,
    this.borrowerPhone,
    this.annualInterestRatePercent = 24,
  });

  final String borrowerId;
  final String borrowerName;
  final String? borrowerPhone;
  final LoanPurpose purpose;
  final double amountRupees;
  final RepaymentFrequency frequency;
  final int tenure;
  final double annualInterestRatePercent;

  @override
  List<Object?> get props => [
    borrowerId,
    borrowerName,
    borrowerPhone,
    purpose,
    amountRupees,
    frequency,
    tenure,
    annualInterestRatePercent,
  ];
}
