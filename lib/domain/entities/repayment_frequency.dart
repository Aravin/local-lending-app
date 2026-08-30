/// Supported repayment frequencies for loans.
///
/// This enum drives:
/// - Apply for Loan form options (filtered by AppConfig.supportedFrequencies)
/// - EMI calculation period in EmiCalculator
/// - Due date generation in RepaymentSchedule
/// - Collection Sheet grouping in admin view
/// - Notification scheduling frequency
enum RepaymentFrequency {
  /// Borrower repays every calendar day.
  /// Tenure expressed in days (7–90).
  /// May skip Sundays/holidays if AppConfig.allowHolidaySkip is true.
  daily,

  /// Borrower repays once per week on the same day of week as disbursement.
  /// Tenure expressed in weeks (4–52).
  weekly,

  /// Borrower repays every 14 days (strict interval, not calendar fortnight).
  /// Tenure expressed in fortnights (2–26).
  biweekly,

  /// Borrower repays once per month on the same calendar day as disbursement.
  /// Tenure expressed in months (1–36).
  /// Month-end edge case: Jan 31 disbursement → Feb due date clamped to Feb 28/29.
  monthly;

  /// Human-readable label for UI display.
  String get label {
    return switch (this) {
      RepaymentFrequency.daily => 'Daily',
      RepaymentFrequency.weekly => 'Weekly',
      RepaymentFrequency.biweekly => 'Biweekly',
      RepaymentFrequency.monthly => 'Monthly',
    };
  }

  /// Short suffix shown next to EMI amount (e.g. "₹250/day").
  String get suffix {
    return switch (this) {
      RepaymentFrequency.daily => '/day',
      RepaymentFrequency.weekly => '/week',
      RepaymentFrequency.biweekly => '/fortnight',
      RepaymentFrequency.monthly => '/month',
    };
  }

  /// Unit name for tenure input labels.
  String get tenureUnit {
    return switch (this) {
      RepaymentFrequency.daily => 'days',
      RepaymentFrequency.weekly => 'weeks',
      RepaymentFrequency.biweekly => 'fortnights',
      RepaymentFrequency.monthly => 'months',
    };
  }

  /// Minimum allowed tenure for this frequency.
  int get minTenure {
    return switch (this) {
      RepaymentFrequency.daily => 7,
      RepaymentFrequency.weekly => 4,
      RepaymentFrequency.biweekly => 2,
      RepaymentFrequency.monthly => 1,
    };
  }

  /// Maximum allowed tenure for this frequency.
  int get maxTenure {
    return switch (this) {
      RepaymentFrequency.daily => 90,
      RepaymentFrequency.weekly => 52,
      RepaymentFrequency.biweekly => 26,
      RepaymentFrequency.monthly => 36,
    };
  }

  /// Number of periods per year — used for interest rate conversion.
  double get periodsPerYear {
    return switch (this) {
      RepaymentFrequency.daily => 365,
      RepaymentFrequency.weekly => 52,
      RepaymentFrequency.biweekly => 26,
      RepaymentFrequency.monthly => 12,
    };
  }
}
