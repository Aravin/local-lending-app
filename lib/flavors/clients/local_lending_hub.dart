import 'package:flutter/material.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/flavors/app_config.dart';

/// White-label configuration for the "Local Lending Hub" client.
///
/// Design system: Kinship Lending System (from Stitch)
/// Primary brand: Deep Teal (#0D9488)
/// Style: Community-Trust — Corporate Modern with a Human Touch
class LocalLendingHubConfig extends AppConfig {
  @override
  String get appName => 'Local Lending Hub';

  @override
  String get packageName => 'com.locallendinghub.app';

  @override
  Color get primaryColor => const Color(0xFF0D9488);

  @override
  Color get secondaryColor => const Color(0xFF006E2F);

  @override
  Color get tertiaryColor => const Color(0xFF3452C1);

  @override
  String get logoAssetPath => 'assets/images/local_lending_hub/logo.png';

  @override
  String get logoFullAssetPath => 'assets/images/local_lending_hub/logo.png';

  @override
  String get apiBaseUrl => ''; // Uses Firestore directly

  @override
  String get currencySymbol => '₹';

  @override
  String get phoneCountryCode => '+91';

  @override
  bool get enableAdminFeatures => true;

  @override
  bool get enableCommunityFeatures => true;

  /// Supports all 4 repayment frequencies.
  @override
  List<RepaymentFrequency> get supportedFrequencies =>
      RepaymentFrequency.values;

  /// Skip Sundays for daily-repayment loans (common in Indian micro-lending).
  @override
  bool get allowHolidaySkip => true;

  /// Max loan: ₹5,00,000 (50,000,000 paise)
  @override
  int get maxLoanAmountPaise => 50000000;

  /// Min loan: ₹500 (50,000 paise)
  @override
  int get minLoanAmountPaise => 50000;
}
