import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/update_loan_status.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_applications.dart';

class LoanApplicationsState extends Equatable {
  const LoanApplicationsState({
    this.loading = true,
    this.applications = const [],
    this.actingApplicationId,
    this.errorMessage,
    this.infoMessage,
  });

  final bool loading;
  final List<LoanApplication> applications;
  final String? actingApplicationId;
  final String? errorMessage;
  final String? infoMessage;

  LoanApplicationsState copyWith({
    bool? loading,
    List<LoanApplication>? applications,
    String? actingApplicationId,
    bool clearActing = false,
    String? errorMessage,
    String? infoMessage,
  }) {
    return LoanApplicationsState(
      loading: loading ?? this.loading,
      applications: applications ?? this.applications,
      actingApplicationId: clearActing
          ? null
          : actingApplicationId ?? this.actingApplicationId,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    applications,
    actingApplicationId,
    errorMessage,
    infoMessage,
  ];
}

class LoanApplicationsCubit extends Cubit<LoanApplicationsState> {
  LoanApplicationsCubit({
    required this.getBorrowerApplications,
    required this.updateLoanStatus,
  }) : super(const LoanApplicationsState());

  final GetBorrowerApplications getBorrowerApplications;
  final UpdateLoanStatus updateLoanStatus;

  String? _borrowerId;

  Future<void> load(String borrowerId, {String? infoMessage}) async {
    _borrowerId = borrowerId;
    emit(
      state.copyWith(
        loading: true,
        clearActing: true,
        infoMessage: infoMessage,
      ),
    );
    final result = await getBorrowerApplications(borrowerId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          loading: false,
          clearActing: true,
          errorMessage: failure.message,
        ),
      ),
      (applications) => emit(
        state.copyWith(
          loading: false,
          applications: applications,
          clearActing: true,
          infoMessage: infoMessage,
        ),
      ),
    );
  }

  Future<void> confirmReceipt(String applicationId) async {
    emit(state.copyWith(actingApplicationId: applicationId));
    final result = await updateLoanStatus(
      UpdateLoanStatusParams(
        applicationId: applicationId,
        status: LoanStatus.active,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(clearActing: true, errorMessage: failure.message),
      ),
      (_) {
        final borrowerId = _borrowerId;
        if (borrowerId == null) return;
        load(
          borrowerId,
          infoMessage: 'Funds confirmed. Your loan is now active.',
        );
      },
    );
  }

  Future<void> reportFundIssue({
    required String applicationId,
    required String reason,
  }) async {
    emit(state.copyWith(actingApplicationId: applicationId));
    final result = await updateLoanStatus(
      UpdateLoanStatusParams(
        applicationId: applicationId,
        status: LoanStatus.fundIssue,
        issueReason: reason,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(clearActing: true, errorMessage: failure.message),
      ),
      (_) {
        final borrowerId = _borrowerId;
        if (borrowerId == null) return;
        load(
          borrowerId,
          infoMessage: 'Issue reported. The lender will follow up.',
        );
      },
    );
  }
}
