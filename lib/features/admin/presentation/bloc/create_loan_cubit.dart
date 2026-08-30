import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/create_loan_for_user.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_customers.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_kyc_profiles.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/domain/usecases/calculate_emi.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

class CreateLoanState extends Equatable {
  const CreateLoanState({
    this.loading = true,
    this.submitting = false,
    this.customers = const [],
    this.selectedCustomer,
    this.principalRupees = 10000,
    this.ratePercent = 24,
    this.frequency = RepaymentFrequency.weekly,
    this.tenure = 12,
    this.purpose = LoanPurpose.business,
    this.disbursementDate,
    this.schedule,
    this.success = false,
    this.errorMessage,
  });

  final bool loading;
  final bool submitting;
  final List<CustomerProfile> customers;
  final CustomerProfile? selectedCustomer;
  final double principalRupees;
  final double ratePercent;
  final RepaymentFrequency frequency;
  final int tenure;
  final LoanPurpose purpose;
  final DateTime? disbursementDate;
  final RepaymentSchedule? schedule;
  final bool success;
  final String? errorMessage;

  CreateLoanState copyWith({
    bool? loading,
    bool? submitting,
    List<CustomerProfile>? customers,
    CustomerProfile? selectedCustomer,
    bool clearSelectedCustomer = false,
    double? principalRupees,
    double? ratePercent,
    RepaymentFrequency? frequency,
    int? tenure,
    LoanPurpose? purpose,
    DateTime? disbursementDate,
    RepaymentSchedule? schedule,
    bool? success,
    String? errorMessage,
  }) {
    return CreateLoanState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      customers: customers ?? this.customers,
      selectedCustomer: clearSelectedCustomer
          ? selectedCustomer
          : selectedCustomer ?? this.selectedCustomer,
      principalRupees: principalRupees ?? this.principalRupees,
      ratePercent: ratePercent ?? this.ratePercent,
      frequency: frequency ?? this.frequency,
      tenure: tenure ?? this.tenure,
      purpose: purpose ?? this.purpose,
      disbursementDate: disbursementDate ?? this.disbursementDate,
      schedule: schedule ?? this.schedule,
      success: success ?? this.success,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    submitting,
    customers,
    selectedCustomer,
    principalRupees,
    ratePercent,
    frequency,
    tenure,
    purpose,
    disbursementDate,
    schedule,
    success,
    errorMessage,
  ];
}

class CreateLoanCubit extends Cubit<CreateLoanState> {
  CreateLoanCubit({
    required this._getCustomers,
    required this._getKycProfiles,
    required this._createLoanForUser,
    this._calculateEmi = const CalculateEmi(),
  }) : super(const CreateLoanState());

  final GetCustomers _getCustomers;
  final GetKycProfiles _getKycProfiles;
  final CreateLoanForUser _createLoanForUser;
  final CalculateEmi _calculateEmi;

  Future<void> load() async {
    emit(state.copyWith(loading: true, errorMessage: null));
    final customersResult = await _getCustomers();
    if (isClosed) return;
    await customersResult.fold(
      (failure) async {
        emit(state.copyWith(loading: false, errorMessage: failure.message));
      },
      (customers) async {
        final kycResult = await _getKycProfiles();
        if (isClosed) return;
        final eligibleIds = kycResult.fold(
          (_) => customers
              .where(
                (customer) =>
                    customer.kycStatus == KycStatus.submitted ||
                    customer.kycStatus == KycStatus.verified,
              )
              .map((customer) => customer.id)
              .toSet(),
          (profiles) => profiles
              .where((profile) => profile.allowsLending())
              .map((profile) => profile.userId)
              .toSet(),
        );
        final eligible = customers
            .where((customer) => eligibleIds.contains(customer.id))
            .toList();
        CustomerProfile? selected;
        if (state.selectedCustomer != null) {
          for (final customer in eligible) {
            if (customer.id == state.selectedCustomer!.id) {
              selected = customer;
              break;
            }
          }
        }
        _recalculate(
          state.copyWith(
            loading: false,
            customers: eligible,
            selectedCustomer: selected,
            clearSelectedCustomer: selected == null,
            disbursementDate: state.disbursementDate ?? DateTime.now(),
          ),
        );
      },
    );
  }

  void selectCustomer(CustomerProfile customer) {
    emit(state.copyWith(selectedCustomer: customer, errorMessage: null));
  }

  void setPrincipal(double value) {
    final min = FlavorConfig.minLoanAmountRupees;
    final max = FlavorConfig.maxLoanAmountRupees;
    _recalculate(
      state.copyWith(principalRupees: value.clamp(min, max).toDouble()),
    );
  }

  void setRate(double value) {
    final min = FlavorConfig.minAnnualInterestRatePercent;
    final max = FlavorConfig.maxAnnualInterestRatePercent;
    _recalculate(state.copyWith(ratePercent: value.clamp(min, max).toDouble()));
  }

  void setFrequency(RepaymentFrequency frequency) {
    var tenure = state.tenure;
    if (tenure < frequency.minTenure) tenure = frequency.minTenure;
    if (tenure > frequency.maxTenure) tenure = frequency.maxTenure;
    _recalculate(state.copyWith(frequency: frequency, tenure: tenure));
  }

  void setTenure(int tenure) {
    _recalculate(state.copyWith(tenure: tenure));
  }

  void setPurpose(LoanPurpose purpose) {
    emit(state.copyWith(purpose: purpose));
  }

  void setDisbursementDate(DateTime date) {
    _recalculate(state.copyWith(disbursementDate: date));
  }

  Future<void> submit() async {
    final customer = state.selectedCustomer;
    final disbursementDate = state.disbursementDate;
    if (customer == null) {
      emit(state.copyWith(errorMessage: 'Select a borrower to create a loan.'));
      return;
    }
    if (customer.kycStatus != KycStatus.submitted &&
        customer.kycStatus != KycStatus.verified) {
      emit(state.copyWith(errorMessage: KycProfile.lendingRequirementMessage));
      return;
    }
    if (disbursementDate == null) return;
    emit(state.copyWith(submitting: true, errorMessage: null));
    final result = await _createLoanForUser(
      CreateLoanParams(
        borrowerId: customer.id,
        borrowerName: customer.name,
        borrowerPhone: customer.phone,
        principalRupees: state.principalRupees,
        annualInterestRatePercent: state.ratePercent,
        tenure: state.tenure,
        frequency: state.frequency,
        disbursementDate: disbursementDate,
        purpose: state.purpose,
      ),
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(submitting: false, errorMessage: failure.message),
      ),
      (_) => emit(state.copyWith(submitting: false, success: true)),
    );
  }

  void _recalculate(CreateLoanState next) {
    final result = _calculateEmi(
      CalculateEmiParams(
        principalRupees: next.principalRupees,
        annualInterestRatePercent: next.ratePercent,
        frequency: next.frequency,
        tenure: next.tenure,
        disbursementDate: next.disbursementDate ?? DateTime.now(),
        skipSundays:
            FlavorConfig.allowHolidaySkip &&
            next.frequency == RepaymentFrequency.daily,
      ),
    );
    result.fold(
      (failure) => emit(next.copyWith(errorMessage: failure.message)),
      (schedule) => emit(next.copyWith(schedule: schedule, errorMessage: null)),
    );
  }
}
