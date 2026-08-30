import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_lending_app/core/data/json_dates.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';

part 'repayment_record_model.freezed.dart';
part 'repayment_record_model.g.dart';

@freezed
abstract class RepaymentRecordModel with _$RepaymentRecordModel {
  const RepaymentRecordModel._();

  const factory RepaymentRecordModel({
    required String id,
    required String loanId,
    required String borrowerId,
    required int installmentNumber,
    required double amountRupees,
    required String method,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime paidAt,
    String? reference,
    @Default(false) bool isPartial,
    String? notes,
  }) = _RepaymentRecordModel;

  factory RepaymentRecordModel.fromJson(Map<String, dynamic> json) =>
      _$RepaymentRecordModelFromJson(json);

  factory RepaymentRecordModel.fromEntity(RepaymentRecord entity) {
    return RepaymentRecordModel(
      id: entity.id,
      loanId: entity.loanId,
      borrowerId: entity.borrowerId,
      installmentNumber: entity.installmentNumber,
      amountRupees: entity.amountRupees,
      method: entity.method.name,
      paidAt: entity.paidAt,
      reference: entity.reference,
      isPartial: entity.isPartial,
      notes: entity.notes,
    );
  }

  RepaymentRecord toEntity() {
    return RepaymentRecord(
      id: id,
      loanId: loanId,
      borrowerId: borrowerId,
      installmentNumber: installmentNumber,
      amountRupees: amountRupees,
      method: PaymentMethod.values.byName(method),
      paidAt: paidAt,
      reference: reference,
      isPartial: isPartial,
      notes: notes,
    );
  }
}
