import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/update_loan_status.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_loan_applications.dart';

class LoanApprovalsState extends Equatable {
  const LoanApprovalsState({
    this.loading = true,
    this.applications = const [],
    this.frequencyFilter,
    this.requestedAfter,
    this.errorMessage,
    this.infoMessage,
  });

  final bool loading;
  final List<LoanApplication> applications;
  final RepaymentFrequency? frequencyFilter;
  final DateTime? requestedAfter;
  final String? errorMessage;
  final String? infoMessage;

  List<LoanApplication> get visible {
    final pending = applications
        .where((app) => app.status == LoanStatus.pending)
        .toList();
    if (frequencyFilter == null) return pending;
    return pending.where((app) => app.frequency == frequencyFilter).toList();
  }

  LoanApprovalsState copyWith({
    bool? loading,
    List<LoanApplication>? applications,
    RepaymentFrequency? frequencyFilter,
    DateTime? requestedAfter,
    bool clearFrequencyFilter = false,
    bool clearRequestedAfter = false,
    String? errorMessage,
    String? infoMessage,
  }) {
    return LoanApprovalsState(
      loading: loading ?? this.loading,
      applications: applications ?? this.applications,
      frequencyFilter: clearFrequencyFilter
          ? null
          : frequencyFilter ?? this.frequencyFilter,
      requestedAfter: clearRequestedAfter
          ? null
          : requestedAfter ?? this.requestedAfter,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    applications,
    frequencyFilter,
    requestedAfter,
    errorMessage,
    infoMessage,
  ];
}

class LoanApprovalsCubit extends Cubit<LoanApprovalsState> {
  LoanApprovalsCubit({
    required this._getLoanApplications,
    required this._updateLoanStatus,
  }) : super(const LoanApprovalsState());

  final GetLoanApplications _getLoanApplications;
  final UpdateLoanStatus _updateLoanStatus;

  Future<void> load({DateTime? requestedAfter}) async {
    emit(state.copyWith(loading: true, requestedAfter: requestedAfter));
    final result = await _getLoanApplications(requestedAfter: requestedAfter);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (apps) => emit(state.copyWith(loading: false, applications: apps)),
    );
  }

  Future<void> setRequestedAfter(DateTime? date) {
    if (date == null) {
      emit(state.copyWith(clearRequestedAfter: true));
      return load();
    }
    return load(requestedAfter: date);
  }

  void setFrequencyFilter(RepaymentFrequency? frequency) {
    emit(
      state.copyWith(
        frequencyFilter: frequency,
        clearFrequencyFilter: frequency == null,
      ),
    );
  }

  Future<void> decide(UpdateLoanStatusParams params) async {
    final result = await _updateLoanStatus(params);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (_) => load(requestedAfter: state.requestedAfter),
    );
  }
}
