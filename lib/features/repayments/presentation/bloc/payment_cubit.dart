import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_loans.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';
import 'package:local_lending_app/features/repayments/domain/usecases/make_repayment.dart';

enum PaymentUiStatus { loading, ready, processing, success, error }

class PaymentState extends Equatable {
  const PaymentState({
    this.status = PaymentUiStatus.loading,
    this.loans = const [],
    this.selectedLoan,
    this.amountRupees = 0,
    this.method = PaymentMethod.upi,
    this.errorMessage,
    this.receipt,
  });

  final PaymentUiStatus status;
  final List<Loan> loans;
  final Loan? selectedLoan;
  final double amountRupees;
  final PaymentMethod method;
  final String? errorMessage;
  final RepaymentRecord? receipt;

  PaymentState copyWith({
    PaymentUiStatus? status,
    List<Loan>? loans,
    Loan? selectedLoan,
    double? amountRupees,
    PaymentMethod? method,
    String? errorMessage,
    RepaymentRecord? receipt,
  }) {
    return PaymentState(
      status: status ?? this.status,
      loans: loans ?? this.loans,
      selectedLoan: selectedLoan ?? this.selectedLoan,
      amountRupees: amountRupees ?? this.amountRupees,
      method: method ?? this.method,
      errorMessage: errorMessage,
      receipt: receipt ?? this.receipt,
    );
  }

  @override
  List<Object?> get props => [
    status,
    loans,
    selectedLoan,
    amountRupees,
    method,
    errorMessage,
    receipt,
  ];
}

class PaymentCubit extends Cubit<PaymentState> {
  PaymentCubit({required this._getBorrowerLoans, required this._makeRepayment})
    : super(const PaymentState());

  final GetBorrowerLoans _getBorrowerLoans;
  final MakeRepayment _makeRepayment;

  Future<void> load(String borrowerId) async {
    emit(state.copyWith(status: PaymentUiStatus.loading));
    final result = await _getBorrowerLoans(borrowerId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PaymentUiStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (loans) {
        final open = loans.where((loan) => loan.status.isOpen).toList();
        final selected = open.isEmpty ? null : open.first;
        emit(
          state.copyWith(
            status: PaymentUiStatus.ready,
            loans: open,
            selectedLoan: selected,
            amountRupees: selected?.nextDue?.outstandingRupees ?? 0,
          ),
        );
      },
    );
  }

  void selectLoan(Loan loan) {
    emit(
      state.copyWith(
        selectedLoan: loan,
        amountRupees: loan.nextDue?.outstandingRupees ?? 0,
      ),
    );
  }

  void setAmount(double amount) {
    emit(state.copyWith(amountRupees: amount));
  }

  void setMethod(PaymentMethod method) {
    emit(state.copyWith(method: method));
  }

  Future<void> pay(String borrowerId) async {
    final loan = state.selectedLoan;
    if (loan == null || state.amountRupees <= 0) return;
    emit(state.copyWith(status: PaymentUiStatus.processing));
    final result = await _makeRepayment(
      MakeRepaymentParams(
        loanId: loan.id,
        borrowerId: borrowerId,
        amountRupees: state.amountRupees,
        method: state.method,
        installmentNumber: loan.nextDue?.installmentNumber,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PaymentUiStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (record) => emit(
        state.copyWith(status: PaymentUiStatus.success, receipt: record),
      ),
    );
  }
}
