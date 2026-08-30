import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/update_loan_status.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:mocktail/mocktail.dart';

class _MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late _MockAdminRepository repository;
  late UpdateLoanStatus useCase;

  setUp(() {
    repository = _MockAdminRepository();
    useCase = UpdateLoanStatus(repository);
  });

  test('requires a rejection reason', () async {
    final result = await useCase(
      const UpdateLoanStatusParams(
        applicationId: 'app-1',
        status: LoanStatus.rejected,
      ),
    );
    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, isA<ValidationFailure>()),
      (_) => fail('expected failure'),
    );
  });

  test('approves via repository', () async {
    const params = UpdateLoanStatusParams(
      applicationId: 'app-1',
      status: LoanStatus.approved,
    );
    final application = LoanApplication(
      id: 'app-1',
      borrowerId: 'b1',
      borrowerName: 'Priya',
      purpose: LoanPurpose.business,
      requestedAmountRupees: 10000,
      frequency: RepaymentFrequency.weekly,
      tenure: 12,
      requestedAt: DateTime(2026, 1, 1),
      status: LoanStatus.approved,
    );
    when(
      () => repository.updateLoanStatus(params),
    ).thenAnswer((_) async => Right(application));

    final result = await useCase(params);
    expect(result, Right(application));
  });

  test('requires a fund issue reason', () async {
    final result = await useCase(
      const UpdateLoanStatusParams(
        applicationId: 'app-1',
        status: LoanStatus.fundIssue,
      ),
    );
    expect(result.isLeft(), isTrue);
  });

  test('rejects unsupported status changes', () async {
    final result = await useCase(
      const UpdateLoanStatusParams(
        applicationId: 'app-1',
        status: LoanStatus.active,
      ),
    );
    expect(result.isLeft(), isTrue);
  });
}
