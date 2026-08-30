import 'package:equatable/equatable.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';

enum CollectionStatus { due, paid, partial, skipped }

class CollectionEntry extends Equatable {
  const CollectionEntry({
    required this.id,
    required this.loanId,
    required this.borrowerId,
    required this.borrowerName,
    required this.dueAmountRupees,
    required this.dueDate,
    required this.status,
    required this.frequency,
    required this.installmentNumber,
    this.borrowerPhone,
    this.collectedAmountRupees = 0,
    this.collectedAt,
    this.method,
  });

  final String id;
  final String loanId;
  final String borrowerId;
  final String borrowerName;
  final String? borrowerPhone;
  final double dueAmountRupees;
  final DateTime dueDate;
  final CollectionStatus status;
  final RepaymentFrequency frequency;
  final int installmentNumber;
  final double collectedAmountRupees;
  final DateTime? collectedAt;
  final PaymentMethod? method;

  double get outstandingRupees => dueAmountRupees - collectedAmountRupees;

  @override
  List<Object?> get props => [
    id,
    loanId,
    borrowerId,
    borrowerName,
    borrowerPhone,
    dueAmountRupees,
    dueDate,
    status,
    frequency,
    installmentNumber,
    collectedAmountRupees,
    collectedAt,
    method,
  ];

  CollectionEntry copyWith({
    CollectionStatus? status,
    double? collectedAmountRupees,
    DateTime? collectedAt,
    PaymentMethod? method,
  }) {
    return CollectionEntry(
      id: id,
      loanId: loanId,
      borrowerId: borrowerId,
      borrowerName: borrowerName,
      borrowerPhone: borrowerPhone,
      dueAmountRupees: dueAmountRupees,
      dueDate: dueDate,
      status: status ?? this.status,
      frequency: frequency,
      installmentNumber: installmentNumber,
      collectedAmountRupees:
          collectedAmountRupees ?? this.collectedAmountRupees,
      collectedAt: collectedAt ?? this.collectedAt,
      method: method ?? this.method,
    );
  }
}

class RecordCollectionParams extends Equatable {
  const RecordCollectionParams({
    required this.loanId,
    required this.installmentNumber,
    required this.amountRupees,
    required this.method,
    required this.idempotencyKey,
    this.notes,
  });

  final String loanId;
  final int installmentNumber;
  final double amountRupees;
  final PaymentMethod method;
  final String idempotencyKey;
  final String? notes;

  @override
  List<Object?> get props => [
    loanId,
    installmentNumber,
    amountRupees,
    method,
    idempotencyKey,
    notes,
  ];
}
