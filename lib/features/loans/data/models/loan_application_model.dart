import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_lending_app/core/data/json_dates.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

part 'loan_application_model.freezed.dart';
part 'loan_application_model.g.dart';

@freezed
abstract class LoanApplicationModel with _$LoanApplicationModel {
  const LoanApplicationModel._();

  const factory LoanApplicationModel({
    required String id,
    required String borrowerId,
    required String borrowerName,
    required String purpose,
    required double requestedAmountRupees,
    required String frequency,
    required int tenure,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime requestedAt,
    required String status,
    String? borrowerPhone,
    String? notes,
    @JsonKey(fromJson: optionalDateTimeFromJson, toJson: optionalDateTimeToJson)
    DateTime? reviewedAt,
    String? rejectionReason,
    double? counterOfferPrincipalRupees,
    @Default(24) double annualInterestRatePercent,
  }) = _LoanApplicationModel;

  factory LoanApplicationModel.fromJson(Map<String, dynamic> json) =>
      _$LoanApplicationModelFromJson(json);

  factory LoanApplicationModel.fromEntity(LoanApplication entity) {
    return LoanApplicationModel(
      id: entity.id,
      borrowerId: entity.borrowerId,
      borrowerName: entity.borrowerName,
      borrowerPhone: entity.borrowerPhone,
      purpose: entity.purpose.name,
      requestedAmountRupees: entity.requestedAmountRupees,
      frequency: entity.frequency.name,
      tenure: entity.tenure,
      requestedAt: entity.requestedAt,
      status: entity.status.name,
      notes: entity.notes,
      reviewedAt: entity.reviewedAt,
      rejectionReason: entity.rejectionReason,
      counterOfferPrincipalRupees: entity.counterOfferPrincipalRupees,
      annualInterestRatePercent: entity.annualInterestRatePercent,
    );
  }

  LoanApplication toEntity() {
    return LoanApplication(
      id: id,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      purpose: LoanPurpose.values.byName(purpose),
      requestedAmountRupees: requestedAmountRupees,
      frequency: RepaymentFrequency.values.byName(frequency),
      tenure: tenure,
      requestedAt: requestedAt,
      status: LoanStatus.values.byName(status),
      notes: notes,
      reviewedAt: reviewedAt,
      rejectionReason: rejectionReason,
      counterOfferPrincipalRupees: counterOfferPrincipalRupees,
      annualInterestRatePercent: annualInterestRatePercent,
    );
  }
}
