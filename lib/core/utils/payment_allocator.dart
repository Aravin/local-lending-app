import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

class PaymentAllocation {
  const PaymentAllocation({
    required this.loan,
    required this.firstInstallmentNumber,
    required this.isPartial,
  });

  final Loan loan;
  final int firstInstallmentNumber;
  final bool isPartial;
}

PaymentAllocation allocatePayment({
  required Loan loan,
  required double amountRupees,
  required DateTime paidAt,
  int? installmentNumber,
  String? notes,
}) {
  if (amountRupees <= 0) {
    throw ArgumentError.value(amountRupees, 'amountRupees', 'Must be positive');
  }

  final installments = loan.schedule.installments;
  final startIndex = installmentNumber == null
      ? installments.indexWhere((item) => !item.isSettled)
      : installments.indexWhere(
          (item) => item.installmentNumber == installmentNumber,
        );
  if (startIndex < 0) {
    throw StateError('No payable installment found for loan ${loan.id}');
  }
  if (installments[startIndex].isSettled) {
    throw StateError(
      'Installment ${installments[startIndex].installmentNumber} is settled',
    );
  }

  final available = installments
      .skip(startIndex)
      .where((item) => !item.isSettled)
      .fold<double>(0, (sum, item) => sum + item.outstandingRupees);
  if (amountRupees > available + 0.009) {
    throw StateError(
      'Payment exceeds the outstanding balance of '
      '${available.toStringAsFixed(2)}',
    );
  }

  var remaining = amountRupees;
  final firstOutstanding = installments[startIndex].outstandingRupees;
  final updated = <RepaymentInstallment>[];
  for (var index = 0; index < installments.length; index++) {
    final installment = installments[index];
    if (index < startIndex || remaining <= 0 || installment.isSettled) {
      updated.add(installment);
      continue;
    }

    final applied = remaining < installment.outstandingRupees
        ? remaining
        : installment.outstandingRupees;
    remaining -= applied;
    final paidTotal = installment.paidAmountRupees + applied;
    final settled = paidTotal >= installment.amountRupees - 0.009;
    updated.add(
      installment.copyWith(
        paidAmountRupees: paidTotal,
        status: settled ? InstallmentStatus.paid : InstallmentStatus.partial,
        paidDate: paidAt,
        notes: notes,
      ),
    );
  }

  final schedule = RepaymentSchedule(
    principalRupees: loan.schedule.principalRupees,
    annualInterestRatePercent: loan.schedule.annualInterestRatePercent,
    frequency: loan.schedule.frequency,
    tenure: loan.schedule.tenure,
    disbursementDate: loan.schedule.disbursementDate,
    installmentAmountRupees: loan.schedule.installmentAmountRupees,
    totalRepayableRupees: loan.schedule.totalRepayableRupees,
    totalInterestRupees: loan.schedule.totalInterestRupees,
    installments: updated,
  );
  final hasOverdue = schedule.installments.any(
    (item) => item.status == InstallmentStatus.overdue,
  );
  final updatedLoan = loan.copyWith(
    schedule: schedule,
    status: schedule.isCompleted
        ? LoanStatus.closed
        : (hasOverdue ? LoanStatus.overdue : LoanStatus.active),
    closedDate: schedule.isCompleted ? paidAt : loan.closedDate,
  );

  return PaymentAllocation(
    loan: updatedLoan,
    firstInstallmentNumber: installments[startIndex].installmentNumber,
    isPartial: amountRupees < firstOutstanding - 0.009,
  );
}
