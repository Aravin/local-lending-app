import 'package:equatable/equatable.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';

class KycProfile extends Equatable {
  const KycProfile({
    required this.userId,
    required this.fullName,
    required this.status,
    this.aadhaarNumber,
    this.panNumber,
    this.address,
    this.idProofUploaded = false,
    this.addressProofUploaded = false,
    this.idProofPath,
    this.addressProofPath,
    this.submittedAt,
    this.verifiedAt,
    this.rejectionReason,
  });

  final String userId;
  final String fullName;
  final KycStatus status;
  final String? aadhaarNumber;
  final String? panNumber;
  final String? address;
  final bool idProofUploaded;
  final bool addressProofUploaded;
  final String? idProofPath;
  final String? addressProofPath;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? rejectionReason;

  /// KYC must be completed again on the anniversary of [verifiedAt].
  DateTime? get expiresAt {
    final completed = verifiedAt;
    if (completed == null) return null;
    return DateTime(completed.year + 1, completed.month, completed.day);
  }

  bool isExpired([DateTime? now]) {
    final expiry = expiresAt;
    if (status != KycStatus.verified || expiry == null) return false;
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    return !today.isBefore(expiryDay);
  }

  bool isExpiringSoon([DateTime? now, int withinDays = 30]) {
    final expiry = expiresAt;
    if (status != KycStatus.verified || expiry == null) return false;
    final clock = now ?? DateTime.now();
    final today = DateTime(clock.year, clock.month, clock.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    final daysLeft = expiryDay.difference(today).inDays;
    return daysLeft >= 0 && daysLeft <= withinDays;
  }

  KycStatus effectiveStatus([DateTime? now]) {
    if (isExpired(now)) return KycStatus.expired;
    return status;
  }

  KycProfile resolved([DateTime? now]) {
    final next = effectiveStatus(now);
    if (next == status) return this;
    return copyWith(status: next);
  }

  bool canSubmit([DateTime? now]) {
    final current = effectiveStatus(now);
    return current.needsBorrowerAction || isExpiringSoon(now);
  }

  @override
  List<Object?> get props => [
    userId,
    fullName,
    status,
    aadhaarNumber,
    panNumber,
    address,
    idProofUploaded,
    addressProofUploaded,
    idProofPath,
    addressProofPath,
    submittedAt,
    verifiedAt,
    rejectionReason,
  ];

  KycProfile copyWith({
    String? fullName,
    KycStatus? status,
    String? aadhaarNumber,
    String? panNumber,
    String? address,
    bool? idProofUploaded,
    bool? addressProofUploaded,
    String? idProofPath,
    String? addressProofPath,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? rejectionReason,
    bool clearRejectionReason = false,
  }) {
    return KycProfile(
      userId: userId,
      fullName: fullName ?? this.fullName,
      status: status ?? this.status,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      panNumber: panNumber ?? this.panNumber,
      address: address ?? this.address,
      idProofUploaded: idProofUploaded ?? this.idProofUploaded,
      addressProofUploaded: addressProofUploaded ?? this.addressProofUploaded,
      idProofPath: idProofPath ?? this.idProofPath,
      addressProofPath: addressProofPath ?? this.addressProofPath,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      rejectionReason: clearRejectionReason
          ? null
          : rejectionReason ?? this.rejectionReason,
    );
  }
}
