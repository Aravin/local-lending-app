import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/utils/emi_calculator.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/loans/data/models/loan_model.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

void main() {
  test('toJson serializes installments as maps for Firestore writes', () {
    final disbursementDate = DateTime(2026, 1, 15);
    final schedule = EmiCalculator.calculate(
      principalRupees: 10000,
      annualInterestRatePercent: 24,
      frequency: RepaymentFrequency.weekly,
      tenure: 4,
      disbursementDate: disbursementDate,
    );
    final json = LoanModel.fromEntity(
      Loan(
        id: 'loan-1',
        borrowerId: 'b1',
        borrowerName: 'Priya',
        purpose: LoanPurpose.business,
        status: LoanStatus.active,
        principalRupees: 10000,
        annualInterestRatePercent: 24,
        frequency: RepaymentFrequency.weekly,
        tenure: 4,
        appliedAt: disbursementDate,
        disbursementDate: disbursementDate,
        schedule: schedule,
      ),
    ).toJson();

    final installments = json['installments']! as List<dynamic>;
    expect(installments, isNotEmpty);
    final first = Map<String, dynamic>.from(installments.first as Map);
    expect(first['installmentNumber'], 1);
    expect(first['dueDate'], isA<String>());
  });
}
