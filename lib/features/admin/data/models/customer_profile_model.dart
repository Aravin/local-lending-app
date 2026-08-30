import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';

part 'customer_profile_model.freezed.dart';
part 'customer_profile_model.g.dart';

@freezed
abstract class CustomerProfileModel with _$CustomerProfileModel {
  const CustomerProfileModel._();

  const factory CustomerProfileModel({
    required String id,
    required String name,
    required String phone,
    required String email,
    required int activeLoansCount,
    required double lifetimeRepaymentRate,
    required String riskTier,
    required String kycStatus,
    @Default(0) double outstandingRupees,
    String? address,
  }) = _CustomerProfileModel;

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileModelFromJson(json);

  factory CustomerProfileModel.fromEntity(CustomerProfile entity) {
    return CustomerProfileModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      activeLoansCount: entity.activeLoansCount,
      lifetimeRepaymentRate: entity.lifetimeRepaymentRate,
      riskTier: entity.riskTier.name,
      kycStatus: entity.kycStatus.name,
      outstandingRupees: entity.outstandingRupees,
      address: entity.address,
    );
  }

  CustomerProfile toEntity() {
    return CustomerProfile(
      id: id,
      name: name,
      phone: phone,
      email: email,
      activeLoansCount: activeLoansCount,
      lifetimeRepaymentRate: lifetimeRepaymentRate,
      riskTier: RiskTier.values.byName(riskTier),
      kycStatus: KycStatus.values.byName(kycStatus),
      outstandingRupees: outstandingRupees,
      address: address,
    );
  }
}
