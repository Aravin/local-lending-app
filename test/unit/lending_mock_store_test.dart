import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/data/lending_mock_store.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';

void main() {
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
}
