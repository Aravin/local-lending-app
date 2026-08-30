import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

/// Confirmation window after funds are released.
///
/// Admin marks a loan as disbursed when money is sent. The borrower then has
/// [confirmationWindowDays] calendar days (disbursement day + the next day) to
/// report that funds were not received. If no issue is reported, EMI starts
/// from the disbursement date.
class DisbursementPolicy {
  DisbursementPolicy._();

  static const int confirmationWindowDays = 2;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// First calendar day when the confirmation window is closed.
  ///
  /// Example: disbursed 30 Aug → deadline 1 Sep → borrower can report on
  /// 30 Aug and 31 Aug.
  static DateTime confirmationDeadline(DateTime disbursementDate) {
    return _dateOnly(
      disbursementDate,
    ).add(const Duration(days: confirmationWindowDays));
  }

  static bool isWithinConfirmationWindow({
    required DateTime disbursementDate,
    required DateTime now,
  }) {
    return _dateOnly(now).isBefore(confirmationDeadline(disbursementDate));
  }

  static bool canReportIssue({
    required LoanStatus status,
    required DateTime? disbursementDate,
    required DateTime now,
    DateTime? issueReportedAt,
  }) {
    if (status != LoanStatus.disbursed) return false;
    if (issueReportedAt != null) return false;
    if (disbursementDate == null) return false;
    return isWithinConfirmationWindow(
      disbursementDate: disbursementDate,
      now: now,
    );
  }

  static bool hasEmiStarted({
    required LoanStatus status,
    required DateTime? disbursementDate,
    required DateTime now,
    DateTime? issueReportedAt,
  }) {
    if (issueReportedAt != null || status == LoanStatus.fundIssue) {
      return false;
    }
    if (status == LoanStatus.active ||
        status == LoanStatus.overdue ||
        status == LoanStatus.closed) {
      return true;
    }
    if (status != LoanStatus.disbursed || disbursementDate == null) {
      return false;
    }
    return !isWithinConfirmationWindow(
      disbursementDate: disbursementDate,
      now: now,
    );
  }

  static bool isAllowedTransition(LoanStatus from, LoanStatus to) {
    final allowed = switch (from) {
      LoanStatus.pending => {LoanStatus.approved, LoanStatus.rejected},
      LoanStatus.approved => {LoanStatus.disbursed, LoanStatus.rejected},
      LoanStatus.disbursed => {LoanStatus.fundIssue},
      LoanStatus.fundIssue => {LoanStatus.disbursed, LoanStatus.cancelled},
      _ => <LoanStatus>{},
    };
    return allowed.contains(to);
  }

  static LoanStatus resolvedStatus({
    required LoanStatus status,
    required DateTime? disbursementDate,
    required DateTime now,
    DateTime? issueReportedAt,
    bool hasOverdueInstallments = false,
  }) {
    if (!hasEmiStarted(
      status: status,
      disbursementDate: disbursementDate,
      now: now,
      issueReportedAt: issueReportedAt,
    )) {
      return status;
    }
    if (status == LoanStatus.closed) return LoanStatus.closed;
    if (hasOverdueInstallments) return LoanStatus.overdue;
    if (status == LoanStatus.disbursed) return LoanStatus.active;
    return status;
  }
}
