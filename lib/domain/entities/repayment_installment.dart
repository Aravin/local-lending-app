import 'package:equatable/equatable.dart';

/// Status of a single repayment installment.
enum InstallmentStatus {
  /// Due date is in the future and no payment has been made.
  upcoming,

  /// Due date has passed with no payment.
  overdue,

  /// Full amount has been paid.
  paid,

  /// Part of the amount has been paid; remainder is outstanding.
  partial,

  /// Installment was skipped (e.g. admin-approved grace period).
  skipped,
}

/// A single installment in a loan's repayment schedule.
class RepaymentInstallment extends Equatable {
  const RepaymentInstallment({
    required this.installmentNumber,
    required this.dueDate,
    required this.amountRupees,
    required this.paidAmountRupees,
    required this.status,
    this.paidDate,
    this.penaltyRupees = 0,
    this.notes,
  });

  /// 1-based index in the schedule (1 = first installment).
  final int installmentNumber;

  /// Date by which this installment must be paid.
  final DateTime dueDate;

  /// Total amount due for this installment (principal share + interest share), in ₹.
  final double amountRupees;

  /// Amount already paid towards this installment, in ₹.
  final double paidAmountRupees;

  /// Current status of this installment.
  final InstallmentStatus status;

  /// Date the payment was recorded (null if unpaid).
  final DateTime? paidDate;

  /// Overdue penalty applied (if any), in ₹.
  final double penaltyRupees;

  /// Optional notes from admin (e.g. "partial payment accepted").
  final String? notes;

  /// Outstanding balance for this installment in ₹.
  double get outstandingRupees => amountRupees - paidAmountRupees;

  /// Whether this installment has been fully settled.
  bool get isSettled => status == InstallmentStatus.paid;

  /// Whether any payment has been made towards this installment.
  bool get hasPartialPayment => paidAmountRupees > 0 && !isSettled;

  @override
  List<Object?> get props => [
    installmentNumber,
    dueDate,
    amountRupees,
    paidAmountRupees,
    status,
    paidDate,
    penaltyRupees,
    notes,
  ];

  /// Returns a copy with updated fields.
  RepaymentInstallment copyWith({
    double? paidAmountRupees,
    InstallmentStatus? status,
    DateTime? paidDate,
    double? penaltyRupees,
    String? notes,
  }) {
    return RepaymentInstallment(
      installmentNumber: installmentNumber,
      dueDate: dueDate,
      amountRupees: amountRupees,
      paidAmountRupees: paidAmountRupees ?? this.paidAmountRupees,
      status: status ?? this.status,
      paidDate: paidDate ?? this.paidDate,
      penaltyRupees: penaltyRupees ?? this.penaltyRupees,
      notes: notes ?? this.notes,
    );
  }
}
