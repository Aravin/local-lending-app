import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/utils/document_exporter.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_loans.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';
import 'package:local_lending_app/features/repayments/domain/usecases/get_repayment_history.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.loading = true,
    this.loans = const [],
    this.selectedLoan,
    this.records = const [],
    this.remindersEnabled = true,
    this.errorMessage,
  });

  final bool loading;
  final List<Loan> loans;
  final Loan? selectedLoan;
  final List<RepaymentRecord> records;
  final bool remindersEnabled;
  final String? errorMessage;

  HistoryState copyWith({
    bool? loading,
    List<Loan>? loans,
    Loan? selectedLoan,
    List<RepaymentRecord>? records,
    bool? remindersEnabled,
    String? errorMessage,
  }) {
    return HistoryState(
      loading: loading ?? this.loading,
      loans: loans ?? this.loans,
      selectedLoan: selectedLoan ?? this.selectedLoan,
      records: records ?? this.records,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    loans,
    selectedLoan,
    records,
    remindersEnabled,
    errorMessage,
  ];
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required this._getBorrowerLoans,
    required this._getRepaymentHistory,
  }) : super(const HistoryState());

  final GetBorrowerLoans _getBorrowerLoans;
  final GetRepaymentHistory _getRepaymentHistory;

  Future<void> load(String borrowerId) async {
    emit(state.copyWith(loading: true));
    final loansResult = await _getBorrowerLoans(borrowerId);
    await loansResult.fold(
      (failure) async {
        if (!isClosed) {
          emit(state.copyWith(loading: false, errorMessage: failure.message));
        }
      },
      (loans) async {
        final selected = loans.isEmpty ? null : loans.first;
        final history = selected == null
            ? await _getRepaymentHistory(borrowerId: borrowerId)
            : await _getRepaymentHistory(loanId: selected.id);
        if (isClosed) return;
        history.fold(
          (failure) => emit(
            state.copyWith(loading: false, errorMessage: failure.message),
          ),
          (records) => emit(
            state.copyWith(
              loading: false,
              loans: loans,
              selectedLoan: selected,
              records: records,
            ),
          ),
        );
      },
    );
  }

  Future<void> selectLoan(Loan loan) async {
    emit(state.copyWith(selectedLoan: loan, loading: true));
    final history = await _getRepaymentHistory(loanId: loan.id);
    if (isClosed) return;
    history.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (records) => emit(state.copyWith(loading: false, records: records)),
    );
  }

  void toggleReminders(bool enabled) {
    emit(state.copyWith(remindersEnabled: enabled));
  }

  Future<void> downloadStatement() async {
    final loan = state.selectedLoan;
    if (loan == null) return;
    await DocumentExporter.shareLoanStatement(
      loan: loan,
      records: state.records,
    );
  }
}
