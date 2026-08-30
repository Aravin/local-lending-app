import 'package:equatable/equatable.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';

/// A recorded payment against a loan installment (full, partial, or advance).
class RepaymentRecord extends Equatable {
  const RepaymentRecord({
    required this.id,
    required this.loanId,
    required this.borrowerId,
    required this.installmentNumber,
    required this.amountRupees,
    required this.method,
    required this.paidAt,
    this.reference,
    this.isPartial = false,
    this.notes,
  });

  final String id;
  final String loanId;
  final String borrowerId;
  final int installmentNumber;
  final double amountRupees;
  final PaymentMethod method;
  final DateTime paidAt;
  final String? reference;
  final bool isPartial;
  final String? notes;

  @override
  List<Object?> get props => [
    id,
    loanId,
    borrowerId,
    installmentNumber,
    amountRupees,
    method,
    paidAt,
    reference,
    isPartial,
    notes,
  ];
}

class MakeRepaymentParams extends Equatable {
  const MakeRepaymentParams({
    required this.loanId,
    required this.borrowerId,
    required this.amountRupees,
    required this.method,
    this.installmentNumber,
    this.notes,
  });

  final String loanId;
  final String borrowerId;
  final double amountRupees;
  final PaymentMethod method;
  final int? installmentNumber;
  final String? notes;

  @override
  List<Object?> get props => [
    loanId,
    borrowerId,
    amountRupees,
    method,
    installmentNumber,
    notes,
  ];
}
