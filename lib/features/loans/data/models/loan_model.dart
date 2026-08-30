import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_lending_app/core/data/json_dates.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';
import 'package:local_lending_app/features/loans/data/models/installment_model.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

part 'loan_model.freezed.dart';
part 'loan_model.g.dart';

@freezed
abstract class LoanModel with _$LoanModel {
  const LoanModel._();

  const factory LoanModel({
    required String id,
    required String borrowerId,
    required String borrowerName,
    required String purpose,
    required String status,
    required double principalRupees,
    required double annualInterestRatePercent,
    required String frequency,
    required int tenure,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime appliedAt,
    required double installmentAmountRupees,
    required double totalRepayableRupees,
    required double totalInterestRupees,
    required List<InstallmentModel> installments,
    String? borrowerPhone,
    @JsonKey(fromJson: optionalDateTimeFromJson, toJson: optionalDateTimeToJson)
    DateTime? disbursementDate,
    @JsonKey(fromJson: optionalDateTimeFromJson, toJson: optionalDateTimeToJson)
    DateTime? closedDate,
    String? rejectionReason,
    double? counterOfferPrincipalRupees,
  }) = _LoanModel;

  factory LoanModel.fromJson(Map<String, dynamic> json) =>
      _$LoanModelFromJson(json);

  factory LoanModel.fromEntity(Loan loan) {
    return LoanModel(
      id: loan.id,
      borrowerId: loan.borrowerId,
      borrowerName: loan.borrowerName,
      borrowerPhone: loan.borrowerPhone,
      purpose: loan.purpose.name,
      status: loan.status.name,
      principalRupees: loan.principalRupees,
      annualInterestRatePercent: loan.annualInterestRatePercent,
      frequency: loan.frequency.name,
      tenure: loan.tenure,
      appliedAt: loan.appliedAt,
      disbursementDate: loan.disbursementDate,
      closedDate: loan.closedDate,
      rejectionReason: loan.rejectionReason,
      counterOfferPrincipalRupees: loan.counterOfferPrincipalRupees,
      installmentAmountRupees: loan.schedule.installmentAmountRupees,
      totalRepayableRupees: loan.schedule.totalRepayableRupees,
      totalInterestRupees: loan.schedule.totalInterestRupees,
      installments: loan.schedule.installments
          .map(InstallmentModel.fromEntity)
          .toList(),
    );
  }

  Loan toEntity() {
    final freq = RepaymentFrequency.values.byName(frequency);
    final start = disbursementDate ?? appliedAt;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final resolvedInstallments = installments.map((item) {
      final installment = item.toEntity();
      final dueDate = DateTime(
        installment.dueDate.year,
        installment.dueDate.month,
        installment.dueDate.day,
      );
      if (!installment.isSettled &&
          installment.status != InstallmentStatus.skipped &&
          dueDate.isBefore(todayDate)) {
        return installment.copyWith(status: InstallmentStatus.overdue);
      }
      return installment;
    }).toList();
    final storedStatus = LoanStatus.values.byName(status);
    final resolvedStatus =
        storedStatus.isOpen &&
            resolvedInstallments.any(
              (item) => item.status == InstallmentStatus.overdue,
            )
        ? LoanStatus.overdue
        : storedStatus;
    return Loan(
      id: id,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      purpose: LoanPurpose.values.byName(purpose),
      status: resolvedStatus,
      principalRupees: principalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
      frequency: freq,
      tenure: tenure,
      appliedAt: appliedAt,
      disbursementDate: disbursementDate,
      closedDate: closedDate,
      rejectionReason: rejectionReason,
      counterOfferPrincipalRupees: counterOfferPrincipalRupees,
      schedule: RepaymentSchedule(
        principalRupees: principalRupees,
        annualInterestRatePercent: annualInterestRatePercent,
        frequency: freq,
        tenure: tenure,
        disbursementDate: start,
        installmentAmountRupees: installmentAmountRupees,
        totalRepayableRupees: totalRepayableRupees,
        totalInterestRupees: totalInterestRupees,
        installments: resolvedInstallments,
      ),
    );
  }
}
