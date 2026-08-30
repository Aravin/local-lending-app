import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/domain/usecases/create_loan_for_user.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_customers.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
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
  final bool success;
  final String? errorMessage;

  CreateLoanState copyWith({
    bool? loading,
    bool? submitting,
    List<CustomerProfile>? customers,
    CustomerProfile? selectedCustomer,
    double? principalRupees,
    double? ratePercent,
    RepaymentFrequency? frequency,
    int? tenure,
    LoanPurpose? purpose,
    DateTime? disbursementDate,
    bool? success,
    String? errorMessage,
  }) {
    return CreateLoanState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      customers: customers ?? this.customers,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      principalRupees: principalRupees ?? this.principalRupees,
      ratePercent: ratePercent ?? this.ratePercent,
      frequency: frequency ?? this.frequency,
      tenure: tenure ?? this.tenure,
      purpose: purpose ?? this.purpose,
      disbursementDate: disbursementDate ?? this.disbursementDate,
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
    success,
    errorMessage,
  ];
}

class CreateLoanCubit extends Cubit<CreateLoanState> {
  CreateLoanCubit({
    required this._getCustomers,
    required this._createLoanForUser,
  }) : super(const CreateLoanState());

  final GetCustomers _getCustomers;
  final CreateLoanForUser _createLoanForUser;

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final result = await _getCustomers();
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (customers) => emit(
        state.copyWith(
          loading: false,
          customers: customers,
          selectedCustomer: customers.isEmpty ? null : customers.first,
          disbursementDate: state.disbursementDate ?? DateTime.now(),
        ),
      ),
    );
  }

  void selectCustomer(CustomerProfile customer) {
    emit(state.copyWith(selectedCustomer: customer));
  }

  void setPrincipal(double value) {
    emit(state.copyWith(principalRupees: value));
  }

  void setRate(double value) {
    final min = FlavorConfig.minAnnualInterestRatePercent;
    final max = FlavorConfig.maxAnnualInterestRatePercent;
    emit(state.copyWith(ratePercent: value.clamp(min, max).toDouble()));
  }

  void setFrequency(RepaymentFrequency frequency) {
    var tenure = state.tenure;
    if (tenure < frequency.minTenure) tenure = frequency.minTenure;
    if (tenure > frequency.maxTenure) tenure = frequency.maxTenure;
    emit(state.copyWith(frequency: frequency, tenure: tenure));
  }

  void setTenure(int tenure) {
    emit(state.copyWith(tenure: tenure));
  }

  void setPurpose(LoanPurpose purpose) {
    emit(state.copyWith(purpose: purpose));
  }

  void setDisbursementDate(DateTime date) {
    emit(state.copyWith(disbursementDate: date));
  }

  Future<void> submit() async {
    final customer = state.selectedCustomer;
    final disbursementDate = state.disbursementDate;
    if (customer == null || disbursementDate == null) return;
    emit(state.copyWith(submitting: true));
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
}
