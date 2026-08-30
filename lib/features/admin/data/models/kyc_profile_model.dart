import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:local_lending_app/core/data/json_dates.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';

part 'kyc_profile_model.freezed.dart';
part 'kyc_profile_model.g.dart';

@freezed
abstract class KycProfileModel with _$KycProfileModel {
  const KycProfileModel._();

  const factory KycProfileModel({
    required String userId,
    required String fullName,
    required String status,
    String? aadhaarNumber,
    String? panNumber,
    String? address,
    @Default(false) bool idProofUploaded,
    @Default(false) bool addressProofUploaded,
    String? idProofPath,
    String? addressProofPath,
    @JsonKey(fromJson: optionalDateTimeFromJson, toJson: optionalDateTimeToJson)
    DateTime? submittedAt,
    @JsonKey(fromJson: optionalDateTimeFromJson, toJson: optionalDateTimeToJson)
    DateTime? verifiedAt,
    String? rejectionReason,
  }) = _KycProfileModel;

  factory KycProfileModel.fromJson(Map<String, dynamic> json) =>
      _$KycProfileModelFromJson(json);

  factory KycProfileModel.fromEntity(KycProfile entity) {
    return KycProfileModel(
      userId: entity.userId,
      fullName: entity.fullName,
      status: entity.status.name,
      aadhaarNumber: entity.aadhaarNumber,
      panNumber: entity.panNumber,
      address: entity.address,
      idProofUploaded: entity.idProofUploaded,
      addressProofUploaded: entity.addressProofUploaded,
      idProofPath: entity.idProofPath,
      addressProofPath: entity.addressProofPath,
      submittedAt: entity.submittedAt,
      verifiedAt: entity.verifiedAt,
      rejectionReason: entity.rejectionReason,
    );
  }

  KycProfile toEntity() {
    return KycProfile(
      userId: userId,
      fullName: fullName,
      status: KycStatus.values.byName(status),
      aadhaarNumber: aadhaarNumber,
      panNumber: panNumber,
      address: address,
      idProofUploaded: idProofUploaded,
      addressProofUploaded: addressProofUploaded,
      idProofPath: idProofPath,
      addressProofPath: addressProofPath,
      submittedAt: submittedAt,
      verifiedAt: verifiedAt,
      rejectionReason: rejectionReason,
    );
  }
}
