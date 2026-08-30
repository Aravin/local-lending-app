import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/update_loan_status.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_applications.dart';
import 'package:local_lending_app/features/loans/domain/usecases/get_borrower_loans.dart';
import 'package:local_lending_app/features/repayments/domain/entities/repayment_record.dart';
import 'package:local_lending_app/features/repayments/domain/usecases/get_repayment_history.dart';

enum DashboardStatus { initial, loading, loaded, error }

class BorrowerDashboardState extends Equatable {
  const BorrowerDashboardState({
    this.status = DashboardStatus.initial,
    this.loans = const [],
    this.applications = const [],
    this.recentRepayments = const [],
    this.kyc,
    this.errorMessage,
    this.infoMessage,
    this.acting = false,
  });

  final DashboardStatus status;
  final List<Loan> loans;
  final List<LoanApplication> applications;
  final List<RepaymentRecord> recentRepayments;
  final KycProfile? kyc;
  final String? errorMessage;
  final String? infoMessage;
  final bool acting;

  Loan? get activeLoan {
    for (final loan in loans) {
      if (loan.status.isOpen) return loan;
    }
    return loans.isEmpty ? null : loans.first;
  }

  BorrowerDashboardState copyWith({
    DashboardStatus? status,
    List<Loan>? loans,
    List<LoanApplication>? applications,
    List<RepaymentRecord>? recentRepayments,
    KycProfile? kyc,
    String? errorMessage,
    String? infoMessage,
    bool? acting,
  }) {
    return BorrowerDashboardState(
      status: status ?? this.status,
      loans: loans ?? this.loans,
      applications: applications ?? this.applications,
      recentRepayments: recentRepayments ?? this.recentRepayments,
      kyc: kyc ?? this.kyc,
      errorMessage: errorMessage,
      infoMessage: infoMessage,
      acting: acting ?? this.acting,
    );
  }

  @override
  List<Object?> get props => [
    status,
    loans,
    applications,
    recentRepayments,
    kyc,
    errorMessage,
    infoMessage,
    acting,
  ];
}

class BorrowerDashboardCubit extends Cubit<BorrowerDashboardState> {
  BorrowerDashboardCubit({
    required GetBorrowerLoans getBorrowerLoans,
    required GetBorrowerApplications getBorrowerApplications,
    required GetRepaymentHistory getRepaymentHistory,
    required AdminRepository adminRepository,
    required UpdateLoanStatus updateLoanStatus,
  }) : this._(
         getBorrowerLoans,
         getBorrowerApplications,
         getRepaymentHistory,
         adminRepository,
         updateLoanStatus,
       );

  BorrowerDashboardCubit._(
    this._getBorrowerLoans,
    this._getBorrowerApplications,
    this._getRepaymentHistory,
    this._adminRepository,
    this._updateLoanStatus,
  ) : super(const BorrowerDashboardState());

  final GetBorrowerLoans _getBorrowerLoans;
  final GetBorrowerApplications _getBorrowerApplications;
  final GetRepaymentHistory _getRepaymentHistory;
  final AdminRepository _adminRepository;
  final UpdateLoanStatus _updateLoanStatus;

  String? _borrowerId;

  Future<void> load(String borrowerId, {String? infoMessage}) async {
    _borrowerId = borrowerId;
    emit(
      state.copyWith(
        status: DashboardStatus.loading,
        acting: false,
        infoMessage: infoMessage,
      ),
    );
    final loansResult = await _getBorrowerLoans(borrowerId);
    await loansResult.fold(
      (failure) async {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: DashboardStatus.error,
              errorMessage: failure.message,
            ),
          );
        }
      },
      (loans) async {
        final applicationsResult = await _getBorrowerApplications(borrowerId);
        final historyResult = await _getRepaymentHistory(
          borrowerId: borrowerId,
        );
        final kycResult = await _adminRepository.getKycProfile(borrowerId);
        if (isClosed) return;
        final applications = applicationsResult.getOrElse(() => const []);
        final history = historyResult.getOrElse(() => const []);
        final kyc = kycResult.fold((_) => null, (profile) => profile);
        emit(
          state.copyWith(
            status: DashboardStatus.loaded,
            loans: loans,
            applications: applications,
            recentRepayments: history.take(6).toList(),
            kyc: kyc,
            acting: false,
            infoMessage: infoMessage,
          ),
        );
      },
    );
  }

  Future<void> confirmReceipt(Loan loan) async {
    final applicationId = _applicationIdFor(loan);
    if (applicationId == null) {
      emit(
        state.copyWith(errorMessage: 'Unable to confirm this disbursement.'),
      );
      return;
    }
    emit(state.copyWith(acting: true));
    final result = await _updateLoanStatus(
      UpdateLoanStatusParams(
        applicationId: applicationId,
        status: LoanStatus.active,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(acting: false, errorMessage: failure.message)),
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

  String? _applicationIdFor(Loan loan) {
    if (loan.applicationId != null) return loan.applicationId;
    for (final application in state.applications) {
      if (application.loanId == loan.id) return application.id;
    }
    return null;
  }
}
