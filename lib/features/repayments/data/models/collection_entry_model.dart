import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_lending_app/core/data/json_dates.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/repayments/domain/entities/collection_entry.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';

part 'collection_entry_model.freezed.dart';
part 'collection_entry_model.g.dart';

@freezed
abstract class CollectionEntryModel with _$CollectionEntryModel {
  const CollectionEntryModel._();

  const factory CollectionEntryModel({
    required String id,
    required String loanId,
    required String borrowerId,
    required String borrowerName,
    required double dueAmountRupees,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime dueDate,
    required String status,
    required String frequency,
    required int installmentNumber,
    String? borrowerPhone,
    @Default(0) double collectedAmountRupees,
    @JsonKey(fromJson: optionalDateTimeFromJson, toJson: optionalDateTimeToJson)
    DateTime? collectedAt,
    String? method,
  }) = _CollectionEntryModel;

  factory CollectionEntryModel.fromJson(Map<String, dynamic> json) =>
      _$CollectionEntryModelFromJson(json);

  factory CollectionEntryModel.fromEntity(CollectionEntry entity) {
    return CollectionEntryModel(
      id: entity.id,
      loanId: entity.loanId,
      borrowerId: entity.borrowerId,
      borrowerName: entity.borrowerName,
      borrowerPhone: entity.borrowerPhone,
      dueAmountRupees: entity.dueAmountRupees,
      dueDate: entity.dueDate,
      status: entity.status.name,
      frequency: entity.frequency.name,
      installmentNumber: entity.installmentNumber,
      collectedAmountRupees: entity.collectedAmountRupees,
      collectedAt: entity.collectedAt,
      method: entity.method?.name,
    );
  }

  CollectionEntry toEntity() {
    return CollectionEntry(
      id: id,
      loanId: loanId,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      dueAmountRupees: dueAmountRupees,
      dueDate: dueDate,
      status: CollectionStatus.values.byName(status),
      frequency: RepaymentFrequency.values.byName(frequency),
      installmentNumber: installmentNumber,
      collectedAmountRupees: collectedAmountRupees,
      collectedAt: collectedAt,
      method: method == null ? null : PaymentMethod.values.byName(method!),
    );
  }
}
