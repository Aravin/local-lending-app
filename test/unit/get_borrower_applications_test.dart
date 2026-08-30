import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/loans/domain/repositories/loan_repository.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_applications.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoanRepository extends Mock implements LoanRepository {}

void main() {
  late _MockLoanRepository repository;
  late GetBorrowerApplications usecase;

  setUp(() {
    repository = _MockLoanRepository();
    usecase = GetBorrowerApplications(repository);
  });

  test('rejects empty borrower id', () async {
    final result = await usecase('  ');
    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected failure'),
    );
  });

  test('returns applications for the borrower', () async {
    final applications = [
      LoanApplication(
        id: 'app-1',
        borrowerId: 'b1',
        borrowerName: 'Priya',
        purpose: LoanPurpose.business,
        requestedAmountRupees: 10000,
        frequency: RepaymentFrequency.weekly,
        tenure: 12,
        requestedAt: DateTime(2026, 1, 1),
        status: LoanStatus.pending,
      ),
    ];
    when(
      () => repository.getBorrowerApplications('b1'),
    ).thenAnswer((_) async => Right(applications));

    final result = await usecase('b1');
    expect(result, Right(applications));
  });
}
