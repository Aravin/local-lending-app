enum RiskTier {
  low,
  medium,
  high;

  String get label {
    return switch (this) {
      RiskTier.low => 'Low risk',
      RiskTier.medium => 'Medium risk',
      RiskTier.high => 'High risk',
    };
  }
}

enum KycStatus {
  pending,
  submitted,
  verified,
  rejected,
  expired;

  String get label {
    return switch (this) {
      KycStatus.pending => 'Pending',
      KycStatus.submitted => 'Submitted',
      KycStatus.verified => 'Verified',
      KycStatus.rejected => 'Rejected',
      KycStatus.expired => 'Renewal due',
    };
  }

  bool get needsBorrowerAction =>
      this == KycStatus.pending ||
      this == KycStatus.rejected ||
      this == KycStatus.expired;
}
