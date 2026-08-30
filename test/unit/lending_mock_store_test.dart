import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/data/lending_mock_store.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';

void main() {
  test('registered borrowers without a kyc pack still appear in review', () {
    final store = LendingMockStore();
    store.ensureBorrowerProfile(
      userId: 'google-user-fresh',
      name: 'New Borrower',
      email: 'new@example.com',
    );

    final profiles = store.listKyc();
    expect(
      profiles.any((profile) => profile.userId == 'google-user-fresh'),
      isTrue,
    );
    expect(
      profiles
          .firstWhere((profile) => profile.userId == 'google-user-fresh')
          .status,
      KycStatus.pending,
    );
  });

  test('loan apply requires submitted KYC', () {
    final store = LendingMockStore();
    store.ensureBorrowerProfile(
      userId: 'google-user-fresh',
      name: 'New Borrower',
      email: 'new@example.com',
    );

    expect(
      () => store.applyForLoan(
        const ApplyForLoanParams(
          borrowerId: 'google-user-fresh',
          borrowerName: 'New Borrower',
          purpose: LoanPurpose.personal,
          amountRupees: 5000,
          frequency: RepaymentFrequency.weekly,
          tenure: 8,
        ),
      ),
      throwsStateError,
    );

    expect(
      store
          .applyForLoan(
            const ApplyForLoanParams(
              borrowerId: 'cust-anjali',
              borrowerName: 'Anjali Devi',
              purpose: LoanPurpose.education,
              amountRupees: 5000,
              frequency: RepaymentFrequency.monthly,
              tenure: 4,
            ),
          )
          .borrowerId,
      'cust-anjali',
    );
  });

  test('new borrower ids do not inherit demo loans', () {
    final store = LendingMockStore();

    expect(store.getBorrowerLoans('google-user-fresh'), isEmpty);
    expect(store.getBorrowerLoans('cust-priya'), isNotEmpty);
    expect(store.getBorrowerApplications('google-user-fresh'), isEmpty);
  });

  test('advance payment rolls into following installments', () {
    final store = LendingMockStore();
    final loan = store.getBorrowerLoans('cust-priya').first;
    final firstDue = loan.nextDue!;
    final amount = firstDue.outstandingRupees * 2;

    store.applyPayment(
      loanId: loan.id,
      borrowerId: loan.borrowerId,
      amountRupees: amount,
      method: PaymentMethod.upi,
      installmentNumber: firstDue.installmentNumber,
    );

    final updated = store.getLoan(loan.id);
    final paidIncrease = updated.totalPaidRupees - loan.totalPaidRupees;
    expect(paidIncrease, closeTo(amount, 0.001));
    expect(
      updated.schedule.installments
          .firstWhere(
            (item) => item.installmentNumber == firstDue.installmentNumber + 1,
          )
          .paidAmountRupees,
      greaterThan(0),
    );
  });

  test('payment above outstanding balance is rejected', () {
    final store = LendingMockStore();
    final loan = store.getBorrowerLoans('cust-priya').first;

    expect(
      () => store.applyPayment(
        loanId: loan.id,
        borrowerId: loan.borrowerId,
        amountRupees: loan.outstandingRupees + 1,
        method: PaymentMethod.cash,
      ),
      throwsStateError,
    );
  });

  test('overdue installment is selected before upcoming installments', () {
    final store = LendingMockStore();
    final loan = store.loans.firstWhere(
      (item) => item.status == LoanStatus.overdue,
    );

    expect(loan.nextDue?.status, InstallmentStatus.overdue);
  });

  test('repeated collection against a settled installment is rejected', () {
    final store = LendingMockStore();
    final loan = store.getBorrowerLoans('cust-priya').first;
    final installment = loan.nextDue!;

    store.applyPayment(
      loanId: loan.id,
      borrowerId: loan.borrowerId,
      amountRupees: installment.outstandingRupees,
      method: PaymentMethod.cash,
      installmentNumber: installment.installmentNumber,
    );

    expect(
      () => store.applyPayment(
        loanId: loan.id,
        borrowerId: loan.borrowerId,
        amountRupees: installment.outstandingRupees,
        method: PaymentMethod.cash,
        installmentNumber: installment.installmentNumber,
      ),
      throwsStateError,
    );
  });

  test('partial collection reports the remaining installment balance once', () {
    final store = LendingMockStore();
    final loan = store.getBorrowerLoans('cust-priya').first;
    final installment = loan.nextDue!;
    final partialAmount = installment.amountRupees / 2;

    store.applyPayment(
      loanId: loan.id,
      borrowerId: loan.borrowerId,
      amountRupees: partialAmount,
      method: PaymentMethod.cash,
      installmentNumber: installment.installmentNumber,
    );

    final entry = store
        .collectionSheet(installment.dueDate)
        .firstWhere((item) => item.loanId == loan.id);
    expect(entry.dueAmountRupees, installment.amountRupees);
    expect(entry.collectedAmountRupees, closeTo(partialAmount, 0.001));
    expect(
      entry.outstandingRupees,
      closeTo(installment.amountRupees - partialAmount, 0.001),
    );
  });

  test('approval does not disburse funds or start EMI', () {
    final store = LendingMockStore();
    final before = store.loans.length;

    final application = store.updateApplication(
      const UpdateLoanStatusParams(
        applicationId: 'app-pending-1',
        status: LoanStatus.approved,
      ),
    );

    expect(application.status, LoanStatus.approved);
    expect(store.loans.length, before);
  });

  test('release funds creates a disbursed loan from the disbursement date', () {
    final store = LendingMockStore();
    final disbursementDate = DateTime(2026, 8, 30);

    final application = store.updateApplication(
      UpdateLoanStatusParams(
        applicationId: 'app-approved-1',
        status: LoanStatus.disbursed,
        disbursementDate: disbursementDate,
      ),
    );

    expect(application.status, LoanStatus.disbursed);
    expect(application.disbursementDate, disbursementDate);
    expect(application.canReportDisbursementIssue(disbursementDate), isTrue);

    final loan = store.loans.firstWhere(
      (item) => item.id == application.loanId,
    );
    expect(loan.status, LoanStatus.disbursed);
    expect(loan.schedule.disbursementDate, disbursementDate);
    expect(
      () => store.applyPayment(
        loanId: loan.id,
        borrowerId: loan.borrowerId,
        amountRupees: 100,
        method: PaymentMethod.cash,
      ),
      throwsStateError,
    );
  });

  test('borrower can report a missing fund during the confirmation window', () {
    final store = LendingMockStore();
    store.updateApplication(
      UpdateLoanStatusParams(
        applicationId: 'app-approved-1',
        status: LoanStatus.disbursed,
        disbursementDate: DateTime.now(),
      ),
    );

    final reported = store.updateApplication(
      const UpdateLoanStatusParams(
        applicationId: 'app-approved-1',
        status: LoanStatus.fundIssue,
        issueReason: 'Funds not received',
      ),
    );

    expect(reported.status, LoanStatus.fundIssue);
    expect(reported.disbursementIssueReason, 'Funds not received');
    final loan = store.loans.firstWhere((item) => item.id == reported.loanId);
    expect(loan.status, LoanStatus.fundIssue);
  });

  test('borrower can confirm receipt without waiting for the window', () {
    final store = LendingMockStore();
    store.updateApplication(
      UpdateLoanStatusParams(
        applicationId: 'app-approved-1',
        status: LoanStatus.disbursed,
        disbursementDate: DateTime.now(),
      ),
    );

    final confirmed = store.updateApplication(
      const UpdateLoanStatusParams(
        applicationId: 'app-approved-1',
        status: LoanStatus.active,
      ),
    );

    expect(confirmed.status, LoanStatus.active);
    expect(confirmed.canConfirmReceipt(), isFalse);
    expect(confirmed.canReportDisbursementIssue(), isFalse);
    final loan = store.getLoan(confirmed.loanId!);
    expect(loan.status, LoanStatus.active);
    expect(loan.status.isCollectable, isTrue);
  });

  test('EMI becomes active after the confirmation window', () {
    final store = LendingMockStore();
    final application = store.updateApplication(
      UpdateLoanStatusParams(
        applicationId: 'app-approved-1',
        status: LoanStatus.disbursed,
        disbursementDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
    );

    final loan = store.getLoan(application.loanId!);
    expect(loan.status, LoanStatus.active);
    expect(loan.schedule.disbursementDate.isBefore(DateTime.now()), isTrue);
  });
}
