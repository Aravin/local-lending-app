import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_lending_app/core/data/json_dates.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';

part 'installment_model.freezed.dart';
part 'installment_model.g.dart';

@freezed
abstract class InstallmentModel with _$InstallmentModel {
  const InstallmentModel._();

  const factory InstallmentModel({
    required int installmentNumber,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime dueDate,
    required double amountRupees,
    required double paidAmountRupees,
    required String status,
    @JsonKey(fromJson: optionalDateTimeFromJson, toJson: optionalDateTimeToJson)
    DateTime? paidDate,
    @Default(0) double penaltyRupees,
    String? notes,
  }) = _InstallmentModel;

  factory InstallmentModel.fromJson(Map<String, dynamic> json) =>
      _$InstallmentModelFromJson(json);

  factory InstallmentModel.fromEntity(RepaymentInstallment entity) {
    return InstallmentModel(
      installmentNumber: entity.installmentNumber,
      dueDate: entity.dueDate,
      amountRupees: entity.amountRupees,
      paidAmountRupees: entity.paidAmountRupees,
      status: entity.status.name,
      paidDate: entity.paidDate,
      penaltyRupees: entity.penaltyRupees,
      notes: entity.notes,
    );
  }

  RepaymentInstallment toEntity() {
    return RepaymentInstallment(
      installmentNumber: installmentNumber,
      dueDate: dueDate,
      amountRupees: amountRupees,
      paidAmountRupees: paidAmountRupees,
      status: InstallmentStatus.values.byName(status),
      paidDate: paidDate,
      penaltyRupees: penaltyRupees,
      notes: notes,
    );
  }
}
