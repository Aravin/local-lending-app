import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
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
  });

  final DashboardStatus status;
  final List<Loan> loans;
  final List<LoanApplication> applications;
  final List<RepaymentRecord> recentRepayments;
  final KycProfile? kyc;
  final String? errorMessage;

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
  }) {
    return BorrowerDashboardState(
      status: status ?? this.status,
      loans: loans ?? this.loans,
      applications: applications ?? this.applications,
      recentRepayments: recentRepayments ?? this.recentRepayments,
      kyc: kyc ?? this.kyc,
      errorMessage: errorMessage,
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
  ];
}

class BorrowerDashboardCubit extends Cubit<BorrowerDashboardState> {
  BorrowerDashboardCubit({
    required GetBorrowerLoans getBorrowerLoans,
    required GetBorrowerApplications getBorrowerApplications,
    required GetRepaymentHistory getRepaymentHistory,
    required AdminRepository adminRepository,
  }) : this._(
         getBorrowerLoans,
         getBorrowerApplications,
         getRepaymentHistory,
         adminRepository,
       );

  BorrowerDashboardCubit._(
    this._getBorrowerLoans,
    this._getBorrowerApplications,
    this._getRepaymentHistory,
    this._adminRepository,
  ) : super(const BorrowerDashboardState());

  final GetBorrowerLoans _getBorrowerLoans;
  final GetBorrowerApplications _getBorrowerApplications;
  final GetRepaymentHistory _getRepaymentHistory;
  final AdminRepository _adminRepository;

  Future<void> load(String borrowerId) async {
    emit(state.copyWith(status: DashboardStatus.loading));
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
          ),
        );
      },
    );
  }
}
