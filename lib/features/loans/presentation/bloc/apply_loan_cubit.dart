import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/usecases/apply_for_loan.dart';
import 'package:local_lending_app/features/loans/domain/usecases/calculate_emi.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

enum ApplyLoanStatus { editing, submitting, success, error }

class ApplyLoanState extends Equatable {
  const ApplyLoanState({
    this.step = 0,
    this.purpose = LoanPurpose.business,
    this.amountRupees = 10000,
    this.frequency = RepaymentFrequency.weekly,
    this.tenure = 12,
    this.annualInterestRatePercent = 24,
    this.schedule,
    this.status = ApplyLoanStatus.editing,
    this.checkingKyc = true,
    this.kycVerified = false,
    this.errorMessage,
    this.application,
  });

  final int step;
  final LoanPurpose purpose;
  final double amountRupees;
  final RepaymentFrequency frequency;
  final int tenure;
  final double annualInterestRatePercent;
  final RepaymentSchedule? schedule;
  final ApplyLoanStatus status;
  final bool checkingKyc;
  final bool kycVerified;
  final String? errorMessage;
  final LoanApplication? application;

  ApplyLoanState copyWith({
    int? step,
    LoanPurpose? purpose,
    double? amountRupees,
    RepaymentFrequency? frequency,
    int? tenure,
    double? annualInterestRatePercent,
    RepaymentSchedule? schedule,
    ApplyLoanStatus? status,
    bool? checkingKyc,
    bool? kycVerified,
    String? errorMessage,
    LoanApplication? application,
  }) {
    return ApplyLoanState(
      step: step ?? this.step,
      purpose: purpose ?? this.purpose,
      amountRupees: amountRupees ?? this.amountRupees,
      frequency: frequency ?? this.frequency,
      tenure: tenure ?? this.tenure,
      annualInterestRatePercent:
          annualInterestRatePercent ?? this.annualInterestRatePercent,
      schedule: schedule ?? this.schedule,
      status: status ?? this.status,
      checkingKyc: checkingKyc ?? this.checkingKyc,
      kycVerified: kycVerified ?? this.kycVerified,
      errorMessage: errorMessage,
      application: application ?? this.application,
    );
  }

  @override
  List<Object?> get props => [
    step,
    purpose,
    amountRupees,
    frequency,
    tenure,
    annualInterestRatePercent,
    schedule,
    status,
    checkingKyc,
    kycVerified,
    errorMessage,
    application,
  ];
}

class ApplyLoanCubit extends Cubit<ApplyLoanState> {
  ApplyLoanCubit({
    required this._applyForLoan,
    required this._calculateEmi,
    required this._adminRepository,
  }) : super(const ApplyLoanState()) {
    _recalculate();
  }

  final ApplyForLoan _applyForLoan;
  final CalculateEmi _calculateEmi;
  final AdminRepository _adminRepository;

  Future<void> loadKyc(String userId) async {
    emit(state.copyWith(checkingKyc: true));
    final result = await _adminRepository.getKycProfile(userId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          checkingKyc: false,
          kycVerified: false,
          errorMessage: failure.message,
        ),
      ),
      (profile) {
        final allowed = profile.allowsLending();
        emit(
          state.copyWith(
            checkingKyc: false,
            kycVerified: allowed,
            errorMessage: allowed ? null : KycProfile.lendingRequirementMessage,
          ),
        );
      },
    );
  }

  void nextStep() {
    if (state.step < 3) {
      emit(state.copyWith(step: state.step + 1));
      _recalculate();
    }
  }

  void previousStep() {
    if (state.step > 0) {
      emit(state.copyWith(step: state.step - 1));
    }
  }

  void setPurpose(LoanPurpose purpose) {
    emit(state.copyWith(purpose: purpose));
  }

  void setAmount(double amount) {
    final min = FlavorConfig.minLoanAmountRupees;
    final max = FlavorConfig.maxLoanAmountRupees;
    final clamped = amount.clamp(min, max).toDouble();
    emit(state.copyWith(amountRupees: clamped));
    _recalculate();
  }

  void setFrequency(RepaymentFrequency frequency) {
    var tenure = state.tenure;
    if (tenure < frequency.minTenure) tenure = frequency.minTenure;
    if (tenure > frequency.maxTenure) tenure = frequency.maxTenure;
    emit(state.copyWith(frequency: frequency, tenure: tenure));
    _recalculate();
  }

  void setTenure(int tenure) {
    emit(state.copyWith(tenure: tenure));
    _recalculate();
  }

  void setAnnualInterestRate(double ratePercent) {
    final min = FlavorConfig.minAnnualInterestRatePercent;
    final max = FlavorConfig.maxAnnualInterestRatePercent;
    emit(
      state.copyWith(
        annualInterestRatePercent: ratePercent.clamp(min, max).toDouble(),
      ),
    );
    _recalculate();
  }

  void _recalculate() {
    final result = _calculateEmi(
      CalculateEmiParams(
        principalRupees: state.amountRupees,
        annualInterestRatePercent: state.annualInterestRatePercent,
        frequency: state.frequency,
        tenure: state.tenure,
        disbursementDate: DateTime.now(),
        skipSundays: FlavorConfig.allowHolidaySkip,
      ),
    );
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (schedule) =>
          emit(state.copyWith(schedule: schedule, errorMessage: null)),
    );
  }

  Future<void> submit({
    required String borrowerId,
    required String borrowerName,
    String? borrowerPhone,
  }) async {
    if (!state.kycVerified) {
      emit(
        state.copyWith(
          status: ApplyLoanStatus.error,
          errorMessage: KycProfile.lendingRequirementMessage,
        ),
      );
      return;
    }
    emit(state.copyWith(status: ApplyLoanStatus.submitting));
    final result = await _applyForLoan(
      ApplyForLoanParams(
        borrowerId: borrowerId,
        borrowerName: borrowerName,
        borrowerPhone: borrowerPhone,
        purpose: state.purpose,
        amountRupees: state.amountRupees,
        frequency: state.frequency,
        tenure: state.tenure,
        annualInterestRatePercent: state.annualInterestRatePercent,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ApplyLoanStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (application) => emit(
        state.copyWith(
          status: ApplyLoanStatus.success,
          application: application,
        ),
      ),
    );
  }
}
