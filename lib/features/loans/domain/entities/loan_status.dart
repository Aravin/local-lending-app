/// Lifecycle status of a loan or loan application.
enum LoanStatus {
  pending,
  approved,
  rejected,
  disbursed,
  fundIssue,
  active,
  overdue,
  closed,
  cancelled;

  String get label {
    return switch (this) {
      LoanStatus.pending => 'Pending',
      LoanStatus.approved => 'Approved',
      LoanStatus.rejected => 'Rejected',
      LoanStatus.disbursed => 'Disbursed',
      LoanStatus.fundIssue => 'Fund issue',
      LoanStatus.active => 'Active',
      LoanStatus.overdue => 'Overdue',
      LoanStatus.closed => 'Closed',
      LoanStatus.cancelled => 'Cancelled',
    };
  }

  bool get isOpen =>
      this == LoanStatus.active ||
      this == LoanStatus.disbursed ||
      this == LoanStatus.fundIssue ||
      this == LoanStatus.overdue;

  /// EMI collection is allowed only after the confirmation window.
  bool get isCollectable =>
      this == LoanStatus.active || this == LoanStatus.overdue;

  bool get isTerminal =>
      this == LoanStatus.closed ||
      this == LoanStatus.rejected ||
      this == LoanStatus.cancelled;

  String get borrowerMessage {
    return switch (this) {
      LoanStatus.pending => 'Your request is with the lender for review.',
      LoanStatus.approved => 'Approved. Disbursement will follow shortly.',
      LoanStatus.rejected => 'This request was not approved.',
      LoanStatus.disbursed =>
        'Funds have been released. Confirm receipt within 2 days or report if not received. EMI starts from the disbursement date if no issue is reported.',
      LoanStatus.fundIssue =>
        'You reported that funds were not received. The lender is following up.',
      LoanStatus.active => 'Your loan is active. Track repayments from Home.',
      LoanStatus.overdue => 'This loan has overdue installments.',
      LoanStatus.closed => 'This loan is fully repaid.',
      LoanStatus.cancelled => 'This request was cancelled.',
    };
  }
}
