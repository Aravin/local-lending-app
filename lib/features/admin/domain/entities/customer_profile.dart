import 'package:equatable/equatable.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';

class CustomerProfile extends Equatable {
  const CustomerProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.activeLoansCount,
    required this.lifetimeRepaymentRate,
    required this.riskTier,
    required this.kycStatus,
    this.outstandingRupees = 0,
    this.address,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final int activeLoansCount;
  final double lifetimeRepaymentRate;
  final RiskTier riskTier;
  final KycStatus kycStatus;
  final double outstandingRupees;
  final String? address;

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    activeLoansCount,
    lifetimeRepaymentRate,
    riskTier,
    kycStatus,
    outstandingRupees,
    address,
  ];

  CustomerProfile copyWith({
    int? activeLoansCount,
    double? lifetimeRepaymentRate,
    RiskTier? riskTier,
    KycStatus? kycStatus,
    double? outstandingRupees,
    String? address,
  }) {
    return CustomerProfile(
      id: id,
      name: name,
      phone: phone,
      email: email,
      activeLoansCount: activeLoansCount ?? this.activeLoansCount,
      lifetimeRepaymentRate:
          lifetimeRepaymentRate ?? this.lifetimeRepaymentRate,
      riskTier: riskTier ?? this.riskTier,
      kycStatus: kycStatus ?? this.kycStatus,
      outstandingRupees: outstandingRupees ?? this.outstandingRupees,
      address: address ?? this.address,
    );
  }
}
