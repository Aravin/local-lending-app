import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/utils/emi_calculator.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';

void main() {
  // Reference disbursement date: Wednesday, 1 January 2025
  final kDisbursementDate = DateTime(2025, 1, 1);

  group('EmiCalculator.installmentAmount', () {
    group('Daily frequency', () {
      test('30-day ₹10,000 loan at 24% annual flat interest', () {
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 10000,
          annualInterestRatePercent: 24,
          frequency: RepaymentFrequency.daily,
          tenure: 30,
        );
        // Period rate = 24% / 365 = 0.06575% per day
        // Total interest = 10000 × 0.0006575 × 30 = ₹197.26
        // Total repayable = ₹10,197.26
        // EMI = 10197.26 / 30 = ₹339.91 (rounded up to paise)
        expect(emi, closeTo(339.91, 0.01));
      });

      test('zero interest: principal split evenly', () {
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 3000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.daily,
          tenure: 30,
        );
        expect(emi, equals(100.0)); // 3000 / 30 = ₹100/day exactly
      });

      test('minimum tenure (7 days)', () {
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 700,
          annualInterestRatePercent: 12,
          frequency: RepaymentFrequency.daily,
          tenure: 7,
        );
        expect(emi, isPositive);
        expect(emi, greaterThan(100)); // must be > ₹700/7
      });

      test('throws for tenure below minimum (< 7 days)', () {
        expect(
          () => EmiCalculator.installmentAmount(
            principalRupees: 1000,
            annualInterestRatePercent: 12,
            frequency: RepaymentFrequency.daily,
            tenure: 6,
          ),
          throwsArgumentError,
        );
      });

      test('throws for tenure above maximum (> 90 days)', () {
        expect(
          () => EmiCalculator.installmentAmount(
            principalRupees: 1000,
            annualInterestRatePercent: 12,
            frequency: RepaymentFrequency.daily,
            tenure: 91,
          ),
          throwsArgumentError,
        );
      });
    });

    group('Weekly frequency', () {
      test('12-week ₹12,000 loan at 18% annual', () {
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 12000,
          annualInterestRatePercent: 18,
          frequency: RepaymentFrequency.weekly,
          tenure: 12,
        );
        // Period rate = 18% / 52 = 0.3462% per week
        // Total interest = 12000 × 0.003462 × 12 = ₹498.46
        // EMI ≈ (12000 + 498.46) / 12 = ₹1,041.54
        expect(emi, closeTo(1041.54, 0.5));
      });

      test('zero interest weekly', () {
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 5200,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.weekly,
          tenure: 52,
        );
        expect(emi, equals(100.0)); // ₹5200 / 52 weeks = ₹100/week
      });
    });

    group('Biweekly frequency', () {
      test('6-fortnight ₹6,000 loan at 24% annual', () {
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 6000,
          annualInterestRatePercent: 24,
          frequency: RepaymentFrequency.biweekly,
          tenure: 6,
        );
        // Period rate = 24% / 26 = 0.923% per fortnight
        // Total interest = 6000 × 0.00923 × 6 = ₹332.31
        // EMI ≈ 6332.31 / 6 = ₹1,055.39
        expect(emi, closeTo(1055.39, 1.0));
      });
    });

    group('Monthly frequency', () {
      test('12-month ₹1,00,000 loan at 12% annual', () {
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 100000,
          annualInterestRatePercent: 12,
          frequency: RepaymentFrequency.monthly,
          tenure: 12,
        );
        // Period rate = 12% / 12 = 1% per month
        // Total interest = 1,00,000 × 0.01 × 12 = ₹12,000
        // EMI = 1,12,000 / 12 = ₹9,333.34
        expect(emi, closeTo(9333.34, 0.5));
      });

      test('zero interest monthly', () {
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 12000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.monthly,
          tenure: 12,
        );
        expect(emi, equals(1000.0)); // ₹12000 / 12 = ₹1000/month
      });
    });

    group('Edge cases — amounts', () {
      test('throws for zero principal', () {
        expect(
          () => EmiCalculator.installmentAmount(
            principalRupees: 0,
            annualInterestRatePercent: 12,
            frequency: RepaymentFrequency.monthly,
            tenure: 12,
          ),
          throwsArgumentError,
        );
      });

      test('throws for negative principal', () {
        expect(
          () => EmiCalculator.installmentAmount(
            principalRupees: -5000,
            annualInterestRatePercent: 12,
            frequency: RepaymentFrequency.monthly,
            tenure: 12,
          ),
          throwsArgumentError,
        );
      });

      test('throws for negative interest rate', () {
        expect(
          () => EmiCalculator.installmentAmount(
            principalRupees: 10000,
            annualInterestRatePercent: -5,
            frequency: RepaymentFrequency.monthly,
            tenure: 12,
          ),
          throwsArgumentError,
        );
      });

      test('large loan ₹10,00,000 — no floating point drift', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 1000000,
          annualInterestRatePercent: 18,
          frequency: RepaymentFrequency.monthly,
          tenure: 36,
          disbursementDate: kDisbursementDate,
        );
        // Total repayable should exactly equal sum of all installments
        final sumOfInstallments = schedule.installments.fold<double>(
          0,
          (sum, i) => sum + i.amountRupees,
        );
        expect(sumOfInstallments, closeTo(schedule.totalRepayableRupees, 0.01));
      });

      test('very small daily EMI — rounding handles sub-₹1 correctly', () {
        // ₹700 over 90 days = ~₹7.78/day — should round up
        final emi = EmiCalculator.installmentAmount(
          principalRupees: 700,
          annualInterestRatePercent: 12,
          frequency: RepaymentFrequency.daily,
          tenure: 90,
        );
        expect(emi, greaterThanOrEqualTo(7.0));
        expect(emi, lessThan(10.0));
      });
    });
  });

  // ---------------------------------------------------------------------------
  group('EmiCalculator.calculate — schedule generation', () {
    group('Daily schedule', () {
      test('30 installments, each 1 day apart', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 3000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.daily,
          tenure: 30,
          disbursementDate: kDisbursementDate,
        );
        expect(schedule.installments.length, equals(30));
        // First due: Jan 2
        expect(
          schedule.installments.first.dueDate,
          equals(DateTime(2025, 1, 2)),
        );
        // Last due: Jan 31
        expect(
          schedule.installments.last.dueDate,
          equals(DateTime(2025, 1, 31)),
        );
      });

      test('Sunday skip — due date on Sunday shifts to Monday', () {
        // Jan 5, 2025 is a Sunday
        final disbursement = DateTime(2025, 1, 4); // Saturday
        final schedule = EmiCalculator.calculate(
          principalRupees: 700,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.daily,
          tenure: 7,
          disbursementDate: disbursement,
          skipSundays: true,
        );
        // Day 1 = Jan 5 (Sunday) → should shift to Jan 6 (Monday)
        final firstDue = schedule.installments.first.dueDate;
        expect(firstDue.weekday, isNot(equals(DateTime.sunday)));
        expect(firstDue, equals(DateTime(2025, 1, 6)));
      });

      test('no Sunday skip when disabled', () {
        final disbursement = DateTime(2025, 1, 4); // Saturday
        final schedule = EmiCalculator.calculate(
          principalRupees: 700,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.daily,
          tenure: 7,
          disbursementDate: disbursement,
          skipSundays: false,
        );
        final firstDue = schedule.installments.first.dueDate;
        expect(firstDue, equals(DateTime(2025, 1, 5))); // Sunday, no shift
      });

      test('all installments start as upcoming', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 1000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.daily,
          tenure: 10,
          disbursementDate: kDisbursementDate,
        );
        for (final installment in schedule.installments) {
          expect(installment.status, equals(InstallmentStatus.upcoming));
        }
      });
    });

    group('Weekly schedule', () {
      test('12 installments, each 7 days apart', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 12000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.weekly,
          tenure: 12,
          disbursementDate: kDisbursementDate,
        );
        expect(schedule.installments.length, equals(12));
        // Check consistent 7-day intervals
        for (int i = 1; i < schedule.installments.length; i++) {
          final diff = schedule.installments[i].dueDate
              .difference(schedule.installments[i - 1].dueDate)
              .inDays;
          expect(diff, equals(7));
        }
      });

      test('disbursement on Wednesday → all dues on Wednesday', () {
        final wednesday = DateTime(2025, 1, 1); // Wednesday
        final schedule = EmiCalculator.calculate(
          principalRupees: 5200,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.weekly,
          tenure: 4,
          disbursementDate: wednesday,
        );
        for (final installment in schedule.installments) {
          expect(installment.dueDate.weekday, equals(DateTime.wednesday));
        }
      });
    });

    group('Biweekly schedule', () {
      test('6 installments, each exactly 14 days apart', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 6000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.biweekly,
          tenure: 6,
          disbursementDate: kDisbursementDate,
        );
        expect(schedule.installments.length, equals(6));
        for (int i = 1; i < schedule.installments.length; i++) {
          final diff = schedule.installments[i].dueDate
              .difference(schedule.installments[i - 1].dueDate)
              .inDays;
          expect(diff, equals(14));
        }
      });
    });

    group('Monthly schedule', () {
      test('12 installments, same calendar day each month', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 12000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.monthly,
          tenure: 12,
          disbursementDate: DateTime(2025, 1, 15),
        );
        for (final installment in schedule.installments) {
          expect(installment.dueDate.day, equals(15));
        }
      });

      test('month-end clamp: Jan 31 disbursement → Feb 28 due', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 5000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.monthly,
          tenure: 3,
          disbursementDate: DateTime(2025, 1, 31),
        );
        // Feb 2025 has 28 days
        expect(schedule.installments[0].dueDate, equals(DateTime(2025, 2, 28)));
        // March has 31 days — should go back to 31
        expect(schedule.installments[1].dueDate, equals(DateTime(2025, 3, 31)));
        // April has 30 days — clamp
        expect(schedule.installments[2].dueDate, equals(DateTime(2025, 4, 30)));
      });

      test('leap year: Jan 31 → Feb 29 in 2024', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 5000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.monthly,
          tenure: 1,
          disbursementDate: DateTime(2024, 1, 31),
        );
        // 2024 is a leap year
        expect(
          schedule.installments.first.dueDate,
          equals(DateTime(2024, 2, 29)),
        );
      });
    });

    group('Schedule totals', () {
      test('sum of installments equals totalRepayableRupees', () {
        for (final frequency in RepaymentFrequency.values) {
          final schedule = EmiCalculator.calculate(
            principalRupees: 10000,
            annualInterestRatePercent: 12,
            frequency: frequency,
            tenure: frequency.minTenure,
            disbursementDate: kDisbursementDate,
          );
          final sum = schedule.installments.fold<double>(
            0,
            (s, i) => s + i.amountRupees,
          );
          expect(
            sum,
            closeTo(schedule.totalRepayableRupees, 0.01),
            reason: 'Failed for ${frequency.name}',
          );
        }
      });

      test('zero interest: totalInterestRupees is 0', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 10000,
          annualInterestRatePercent: 0,
          frequency: RepaymentFrequency.monthly,
          tenure: 10,
          disbursementDate: kDisbursementDate,
        );
        expect(schedule.totalInterestRupees, equals(0.0));
        expect(schedule.totalRepayableRupees, closeTo(10000, 0.01));
      });

      test('installment numbers are sequential from 1', () {
        final schedule = EmiCalculator.calculate(
          principalRupees: 5000,
          annualInterestRatePercent: 12,
          frequency: RepaymentFrequency.monthly,
          tenure: 5,
          disbursementDate: kDisbursementDate,
        );
        for (int i = 0; i < schedule.installments.length; i++) {
          expect(schedule.installments[i].installmentNumber, equals(i + 1));
        }
      });
    });
  });

  // ---------------------------------------------------------------------------
  group('EmiCalculator.penaltyAmount', () {
    test('1 day overdue at default 0.1%/day on ₹5,000', () {
      final penalty = EmiCalculator.penaltyAmount(
        outstandingRupees: 5000,
        daysOverdue: 1,
      );
      expect(penalty, closeTo(5.0, 0.01)); // 5000 × 0.001 × 1 = ₹5
    });

    test('30 days overdue', () {
      final penalty = EmiCalculator.penaltyAmount(
        outstandingRupees: 10000,
        daysOverdue: 30,
      );
      expect(penalty, closeTo(300.0, 0.01)); // 10000 × 0.001 × 30 = ₹300
    });

    test('zero days overdue returns 0', () {
      final penalty = EmiCalculator.penaltyAmount(
        outstandingRupees: 5000,
        daysOverdue: 0,
      );
      expect(penalty, equals(0.0));
    });

    test('negative days overdue returns 0', () {
      final penalty = EmiCalculator.penaltyAmount(
        outstandingRupees: 5000,
        daysOverdue: -1,
      );
      expect(penalty, equals(0.0));
    });

    test('zero outstanding returns 0', () {
      final penalty = EmiCalculator.penaltyAmount(
        outstandingRupees: 0,
        daysOverdue: 10,
      );
      expect(penalty, equals(0.0));
    });
  });

  // ---------------------------------------------------------------------------
  group('EmiCalculator.earlyClosureAmount', () {
    test('no payments made — closure amount equals total repayable', () {
      final schedule = EmiCalculator.calculate(
        principalRupees: 10000,
        annualInterestRatePercent: 12,
        frequency: RepaymentFrequency.monthly,
        tenure: 6,
        disbursementDate: kDisbursementDate,
      );
      final closure = EmiCalculator.earlyClosureAmount(
        schedule: schedule,
        closureDate: DateTime(2025, 2, 1),
      );
      expect(closure, closeTo(schedule.totalRepayableRupees, 0.01));
    });
  });

  // ---------------------------------------------------------------------------
  group('RepaymentSchedule computed properties', () {
    test('progress is 0 when no payments made', () {
      final schedule = EmiCalculator.calculate(
        principalRupees: 5000,
        annualInterestRatePercent: 0,
        frequency: RepaymentFrequency.monthly,
        tenure: 5,
        disbursementDate: kDisbursementDate,
      );
      expect(schedule.progress, equals(0.0));
      expect(schedule.isCompleted, isFalse);
    });

    test('nextDue returns first installment when none paid', () {
      final schedule = EmiCalculator.calculate(
        principalRupees: 5000,
        annualInterestRatePercent: 0,
        frequency: RepaymentFrequency.monthly,
        tenure: 5,
        disbursementDate: kDisbursementDate,
      );
      expect(schedule.nextDue?.installmentNumber, equals(1));
    });

    test('nextDue returns null when all paid', () {
      final schedule = EmiCalculator.calculate(
        principalRupees: 1000,
        annualInterestRatePercent: 0,
        frequency: RepaymentFrequency.monthly,
        tenure: 2,
        disbursementDate: kDisbursementDate,
      );
      // Manually mark all as paid
      final paid = schedule.installments
          .map((i) => i.copyWith(status: InstallmentStatus.paid))
          .toList();
      final paidSchedule = RepaymentSchedule(
        principalRupees: schedule.principalRupees,
        annualInterestRatePercent: schedule.annualInterestRatePercent,
        frequency: schedule.frequency,
        tenure: schedule.tenure,
        disbursementDate: schedule.disbursementDate,
        installmentAmountRupees: schedule.installmentAmountRupees,
        totalRepayableRupees: schedule.totalRepayableRupees,
        totalInterestRupees: schedule.totalInterestRupees,
        installments: paid,
      );
      expect(paidSchedule.nextDue, isNull);
      expect(paidSchedule.isCompleted, isTrue);
    });
  });
}
