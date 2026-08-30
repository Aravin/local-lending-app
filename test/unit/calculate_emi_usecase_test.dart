import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/loans/domain/usecases/calculate_emi.dart';

void main() {
  const useCase = CalculateEmi();

  test('returns a schedule for a valid weekly loan', () {
    final result = useCase(
      CalculateEmiParams(
        principalRupees: 12000,
        annualInterestRatePercent: 18,
        frequency: RepaymentFrequency.weekly,
        tenure: 12,
        disbursementDate: DateTime(2026, 1, 5),
      ),
    );
    expect(result.isRight(), isTrue);
    result.fold((_) => fail('expected schedule'), (schedule) {
      expect(schedule.installments, hasLength(12));
      expect(schedule.totalRepayableRupees, greaterThan(12000));
    });
  });

  test('returns ValidationFailure for out-of-range tenure', () {
    final result = useCase(
      CalculateEmiParams(
        principalRupees: 1000,
        annualInterestRatePercent: 12,
        frequency: RepaymentFrequency.monthly,
        tenure: 40,
        disbursementDate: DateTime(2026, 1, 1),
      ),
    );
    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected failure'),
    );
  });
}
