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
    this.decidingApplicationId,
    this.errorMessage,
    this.infoMessage,
  });

  final bool loading;
  final List<LoanApplication> applications;
  final RepaymentFrequency? frequencyFilter;
  final DateTime? requestedAfter;
  final String? decidingApplicationId;
  final String? errorMessage;
  final String? infoMessage;

  bool get isDeciding => decidingApplicationId != null;

  List<LoanApplication> _filtered(LoanStatus status) {
    final matches = applications.where((app) => app.status == status);
    if (frequencyFilter == null) return matches.toList();
    return matches.where((app) => app.frequency == frequencyFilter).toList();
  }

  List<LoanApplication> get visible => _filtered(LoanStatus.pending);

  List<LoanApplication> get awaitingDisbursement =>
      _filtered(LoanStatus.approved);

  List<LoanApplication> get inConfirmation => _filtered(LoanStatus.disbursed);

  List<LoanApplication> get fundIssues => _filtered(LoanStatus.fundIssue);

  LoanApprovalsState copyWith({
    bool? loading,
    List<LoanApplication>? applications,
    RepaymentFrequency? frequencyFilter,
    DateTime? requestedAfter,
    String? decidingApplicationId,
    bool clearFrequencyFilter = false,
    bool clearRequestedAfter = false,
    bool clearDeciding = false,
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
      decidingApplicationId: clearDeciding
          ? null
          : decidingApplicationId ?? this.decidingApplicationId,
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
    decidingApplicationId,
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

  Future<void> load({DateTime? requestedAfter, String? infoMessage}) async {
    emit(
      state.copyWith(
        loading: true,
        requestedAfter: requestedAfter,
        clearDeciding: true,
        infoMessage: infoMessage,
      ),
    );
    final result = await _getLoanApplications(requestedAfter: requestedAfter);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          loading: false,
          clearDeciding: true,
          errorMessage: failure.message,
        ),
      ),
      (apps) => emit(
        state.copyWith(
          loading: false,
          applications: apps,
          clearDeciding: true,
          infoMessage: infoMessage,
        ),
      ),
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
    if (state.isDeciding) return;
    emit(state.copyWith(decidingApplicationId: params.applicationId));
    final result = await _updateLoanStatus(params);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(clearDeciding: true, errorMessage: failure.message),
      ),
      (_) => load(
        requestedAfter: state.requestedAfter,
        infoMessage: _infoFor(params),
      ),
    );
  }

  String _infoFor(UpdateLoanStatusParams params) {
    return switch (params.status) {
      LoanStatus.rejected => 'Application rejected.',
      LoanStatus.disbursed =>
        'Funds marked as released. Borrower can confirm receipt now or report a problem within 2 days.',
      LoanStatus.fundIssue => 'Fund issue recorded.',
      LoanStatus.approved when params.counterOfferPrincipalRupees != null =>
        'Counter-offer approved. Release funds after you send the amount.',
      LoanStatus.approved =>
        'Loan approved. Release funds after you send the amount.',
      _ => 'Loan status updated.',
    };
  }
}
