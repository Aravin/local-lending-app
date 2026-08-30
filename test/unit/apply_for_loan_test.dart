import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/loans/domain/repositories/loan_repository.dart';
import 'package:local_lending_app/features/loans/domain/usecases/apply_for_loan.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late _MockLoanRepository repository;
  late ApplyForLoan applyForLoan;

  setUp(() {
    repository = _MockLoanRepository();
    applyForLoan = ApplyForLoan(repository);
  });

  ApplyForLoanParams params({
    double amount = 10000,
    int tenure = 12,
    RepaymentFrequency frequency = RepaymentFrequency.weekly,
  }) {
    return ApplyForLoanParams(
      borrowerId: 'b1',
      borrowerName: 'Priya',
      purpose: LoanPurpose.business,
      amountRupees: amount,
      frequency: frequency,
      tenure: tenure,
    );
  }

  test('rejects empty borrower id', () async {
    const empty = ApplyForLoanParams(
      borrowerId: '  ',
      borrowerName: 'Priya',
      purpose: LoanPurpose.business,
      amountRupees: 10000,
      frequency: RepaymentFrequency.weekly,
      tenure: 12,
    );
    final outcome = await applyForLoan(empty);
    expect(outcome.isLeft(), isTrue);
    outcome.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected failure'),
    );
  });

  test('rejects zero amount', () async {
    final result = await applyForLoan(params(amount: 0));
    expect(
      result,
      const Left(ValidationFailure('Loan amount must be greater than zero.')),
    );
  });

  test('rejects tenure outside frequency range', () async {
    final result = await applyForLoan(
      params(frequency: RepaymentFrequency.daily, tenure: 3),
    );
    expect(result.isLeft(), isTrue);
  });

  test('rejects interest rate outside 12–48% p.a.', () async {
    final result = await applyForLoan(
      const ApplyForLoanParams(
        borrowerId: 'b1',
        borrowerName: 'Priya',
        purpose: LoanPurpose.business,
        amountRupees: 10000,
        frequency: RepaymentFrequency.weekly,
        tenure: 12,
        annualInterestRatePercent: 8,
      ),
    );
    expect(
      result,
      const Left(ValidationFailure('Interest rate must be 12–48% p.a.')),
    );
  });

  test('delegates valid request to repository', () async {
    final request = params();
    final application = LoanApplication(
      id: 'app-1',
      borrowerId: request.borrowerId,
      borrowerName: request.borrowerName,
      purpose: request.purpose,
      requestedAmountRupees: request.amountRupees,
      frequency: request.frequency,
      tenure: request.tenure,
      requestedAt: DateTime(2026, 1, 1),
      status: LoanStatus.pending,
    );
    when(
      () => repository.applyForLoan(request),
    ).thenAnswer((_) async => Right(application));

    final result = await applyForLoan(request);
    expect(result, Right(application));
  });
}

void calculateEmiTests() {}
