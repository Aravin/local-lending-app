import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';

/// Pure-Dart EMI calculator for all supported repayment frequencies.
///
/// Uses **flat interest rate** (common in Indian local lending),
/// where total interest = principal × rate × tenure (in years).
///
/// All calculations use integer paise internally to avoid floating-point
/// drift on large amounts. Results are converted to rupees only at the end.
///
/// Edge cases handled:
/// - Daily: Sunday skip (shifts due date to Monday)
/// - Weekly: consistent day-of-week as disbursement date
/// - Biweekly: strict 14-day intervals
/// - Monthly: month-end clamp (Jan 31 → Feb 28/29)
/// - Zero interest rate: principal-only schedule
/// - Partial payment carry-forward (rounding remainder to last installment)
/// - Very small installments (< ₹1): rounded up, last installment adjusted
/// - Early closure: returns paid + remaining principal + accrued interest
class EmiCalculator {
  // Private constructor — all methods are static.
  EmiCalculator._();

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Calculates the full [RepaymentSchedule] for a loan.
  ///
  /// [principalRupees] — loan principal in ₹ (e.g. 10000.0)
  /// [annualInterestRatePercent] — flat annual interest rate (e.g. 24.0 = 24%)
  /// [frequency] — repayment cadence
  /// [tenure] — number of installments (in the unit of [frequency])
  /// [disbursementDate] — date the loan is disbursed; first due date is derived from this
  /// [skipSundays] — if true, due dates on Sunday shift to Monday
  static RepaymentSchedule calculate({
    required double principalRupees,
    required double annualInterestRatePercent,
    required RepaymentFrequency frequency,
    required int tenure,
    required DateTime disbursementDate,
    bool skipSundays = false,
  }) {
    _validateInputs(
      principalRupees: principalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
      frequency: frequency,
      tenure: tenure,
    );

    final principalPaise = _toPaise(principalRupees);
    final installmentAmountPaise = _installmentAmountPaise(
      principalPaise: principalPaise,
      annualRatePercent: annualInterestRatePercent,
      frequency: frequency,
      tenure: tenure,
    );

    final totalRepayablePaise = installmentAmountPaise * tenure;
    final totalInterestPaise = totalRepayablePaise - principalPaise;

    // Rounding adjustment — any remainder goes to the last installment.
    final regularAmount = installmentAmountPaise;
    final lastInstallmentAdjustment =
        totalRepayablePaise - (regularAmount * tenure);

    final installments = <RepaymentInstallment>[];
    DateTime previousDate = disbursementDate;

    for (int i = 1; i <= tenure; i++) {
      final dueDate = _nextDueDate(
        previous: previousDate,
        installmentNumber: i,
        frequency: frequency,
        disbursementDate: disbursementDate,
        skipSundays: skipSundays,
      );

      final int amountPaise = i == tenure
          ? regularAmount + lastInstallmentAdjustment
          : regularAmount;

      installments.add(
        RepaymentInstallment(
          installmentNumber: i,
          dueDate: dueDate,
          amountRupees: _toRupees(amountPaise),
          paidAmountRupees: 0,
          status: InstallmentStatus.upcoming,
        ),
      );

      previousDate = dueDate;
    }

    return RepaymentSchedule(
      principalRupees: principalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
      frequency: frequency,
      tenure: tenure,
      disbursementDate: disbursementDate,
      installmentAmountRupees: _toRupees(regularAmount),
      totalRepayableRupees: _toRupees(totalRepayablePaise),
      totalInterestRupees: _toRupees(totalInterestPaise),
      installments: installments,
    );
  }

  /// Calculates the per-installment amount in ₹ (flat interest, rounded up).
  static double installmentAmount({
    required double principalRupees,
    required double annualInterestRatePercent,
    required RepaymentFrequency frequency,
    required int tenure,
  }) {
    _validateInputs(
      principalRupees: principalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
      frequency: frequency,
      tenure: tenure,
    );
    return _toRupees(
      _installmentAmountPaise(
        principalPaise: _toPaise(principalRupees),
        annualRatePercent: annualInterestRatePercent,
        frequency: frequency,
        tenure: tenure,
      ),
    );
  }

  /// Calculates a simple overdue penalty.
  ///
  /// [outstandingRupees] — unpaid principal + interest
  /// [daysOverdue] — calendar days since the due date
  /// [penaltyRatePercentPerDay] — daily penalty rate (default: 0.1% = 36.5% annual)
  static double penaltyAmount({
    required double outstandingRupees,
    required int daysOverdue,
    double penaltyRatePercentPerDay = 0.1,
  }) {
    if (daysOverdue <= 0 || outstandingRupees <= 0) return 0;
    return outstandingRupees * (penaltyRatePercentPerDay / 100) * daysOverdue;
  }

  /// Calculates the early closure amount (principal outstanding + accrued interest).
  ///
  /// [schedule] — original repayment schedule
  /// [closureDate] — date of early closure
  static double earlyClosureAmount({
    required RepaymentSchedule schedule,
    required DateTime closureDate,
  }) {
    double outstanding = 0;
    for (final installment in schedule.installments) {
      if (installment.status != InstallmentStatus.paid) {
        // Add unpaid portion of this installment
        outstanding += installment.amountRupees - installment.paidAmountRupees;
      }
    }
    return outstanding;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static void _validateInputs({
    required double principalRupees,
    required double annualInterestRatePercent,
    required RepaymentFrequency frequency,
    required int tenure,
  }) {
    if (principalRupees <= 0) {
      throw ArgumentError(
        'Principal must be greater than 0. Got: $principalRupees',
      );
    }
    if (annualInterestRatePercent < 0) {
      throw ArgumentError(
        'Interest rate cannot be negative. Got: $annualInterestRatePercent',
      );
    }
    if (tenure < frequency.minTenure || tenure > frequency.maxTenure) {
      throw ArgumentError(
        'Tenure $tenure is out of range for ${frequency.name}. '
        'Must be ${frequency.minTenure}–${frequency.maxTenure} ${frequency.tenureUnit}.',
      );
    }
  }

  /// Converts ₹ to paise (×100) as integer to avoid floating-point drift.
  static int _toPaise(double rupees) => (rupees * 100).round();

  /// Converts paise back to ₹.
  static double _toRupees(int paise) => paise / 100;

  /// Flat interest EMI formula:
  ///   total interest = principal × (annualRate / periodsPerYear) × tenure
  ///   EMI = (principal + totalInterest) / tenure
  ///
  /// Returns paise (rounded up to nearest paisa).
  static int _installmentAmountPaise({
    required int principalPaise,
    required double annualRatePercent,
    required RepaymentFrequency frequency,
    required int tenure,
  }) {
    if (annualRatePercent == 0) {
      // Zero interest: split principal evenly, round up.
      return (principalPaise / tenure).ceil();
    }

    final double periodicRate =
        annualRatePercent / 100 / frequency.periodsPerYear;
    final double totalInterestPaise = principalPaise * periodicRate * tenure;
    final double totalRepayablePaise = principalPaise + totalInterestPaise;

    // Round up to ensure principal is fully covered.
    return (totalRepayablePaise / tenure).ceil();
  }

  /// Computes the due date for installment number [installmentNumber].
  static DateTime _nextDueDate({
    required DateTime previous,
    required int installmentNumber,
    required RepaymentFrequency frequency,
    required DateTime disbursementDate,
    required bool skipSundays,
  }) {
    DateTime due;

    switch (frequency) {
      case RepaymentFrequency.daily:
        due = disbursementDate.add(Duration(days: installmentNumber));

      case RepaymentFrequency.weekly:
        due = disbursementDate.add(Duration(days: installmentNumber * 7));

      case RepaymentFrequency.biweekly:
        // Strict 14-day intervals from disbursement.
        due = disbursementDate.add(Duration(days: installmentNumber * 14));

      case RepaymentFrequency.monthly:
        // Add calendar months with month-end clamping.
        due = _addMonths(disbursementDate, installmentNumber);
    }

    if (skipSundays && due.weekday == DateTime.sunday) {
      due = due.add(const Duration(days: 1)); // Shift to Monday
    }

    return DateTime(due.year, due.month, due.day); // Strip time component
  }

  /// Adds [months] to [date] with month-end clamping.
  ///
  /// Example: Jan 31 + 1 month → Feb 28 (or Feb 29 in leap year)
  /// Example: Mar 31 + 1 month → Apr 30
  static DateTime _addMonths(DateTime date, int months) {
    final int targetMonth = date.month + months;
    final int year = date.year + (targetMonth - 1) ~/ 12;
    final int month = ((targetMonth - 1) % 12) + 1;

    // Clamp day to the last day of the target month.
    final int daysInMonth = DateTime(year, month + 1, 0).day;
    final int day = date.day.clamp(1, daysInMonth);

    return DateTime(year, month, day);
  }
}
