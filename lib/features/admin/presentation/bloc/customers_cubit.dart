import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/admin/domain/usecases/get_customers.dart';

class CustomersState extends Equatable {
  const CustomersState({
    this.loading = true,
    this.customers = const [],
    this.query = '',
    this.riskTierFilter,
    this.kycStatusFilter,
    this.errorMessage,
  });

  final bool loading;
  final List<CustomerProfile> customers;
  final String query;
  final RiskTier? riskTierFilter;
  final KycStatus? kycStatusFilter;
  final String? errorMessage;

  List<CustomerProfile> get visibleCustomers => customers
      .where(
        (customer) =>
            (riskTierFilter == null || customer.riskTier == riskTierFilter) &&
            (kycStatusFilter == null || customer.kycStatus == kycStatusFilter),
      )
      .toList();

  CustomersState copyWith({
    bool? loading,
    List<CustomerProfile>? customers,
    String? query,
    RiskTier? riskTierFilter,
    KycStatus? kycStatusFilter,
    bool clearRiskTierFilter = false,
    bool clearKycStatusFilter = false,
    String? errorMessage,
  }) {
    return CustomersState(
      loading: loading ?? this.loading,
      customers: customers ?? this.customers,
      query: query ?? this.query,
      riskTierFilter: clearRiskTierFilter
          ? null
          : riskTierFilter ?? this.riskTierFilter,
      kycStatusFilter: clearKycStatusFilter
          ? null
          : kycStatusFilter ?? this.kycStatusFilter,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    customers,
    query,
    riskTierFilter,
    kycStatusFilter,
    errorMessage,
  ];
}

class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit({required this._getCustomers}) : super(const CustomersState());

  final GetCustomers _getCustomers;

  Future<void> load({String? query}) async {
    final requestedQuery = query ?? state.query;
    emit(
      state.copyWith(loading: state.customers.isEmpty, query: requestedQuery),
    );
    final result = await _getCustomers(query: requestedQuery);
    if (isClosed || state.query != requestedQuery) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(loading: false, errorMessage: failure.message)),
      (customers) => emit(state.copyWith(loading: false, customers: customers)),
    );
  }

  void setRiskTierFilter(RiskTier? riskTier) {
    emit(
      state.copyWith(
        riskTierFilter: riskTier,
        clearRiskTierFilter: riskTier == null,
      ),
    );
  }

  void setKycStatusFilter(KycStatus? status) {
    emit(
      state.copyWith(
        kycStatusFilter: status,
        clearKycStatusFilter: status == null,
      ),
    );
  }
}
