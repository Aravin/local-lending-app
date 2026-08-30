import 'package:flutter/material.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/flavors/app_config.dart';

/// White-label configuration for "Cape Finance".
///
/// Brand Identity:
/// - Primary: Ocean Deep Navy (`#0A2540` / `#1E3A8A`) — Trust, Stability, Institutional Strength.
/// - Secondary: Vibrant Emerald Green (`#059669`) — Growth, Prosperity, Successful Returns.
/// - Tertiary: Warm Gold/Amber (`#D97706`) — Wealth, Community Value, Premium Security.
class CapeFinanceConfig extends AppConfig {
  @override
  String get appName => 'Cape Finance';

  @override
  String get packageName => 'com.capefinance.app';

  @override
  Color get primaryColor => const Color(0xFF0F3D3E); // Deep Cape Pine / Navy

  @override
  Color get secondaryColor => const Color(0xFF059669); // Emerald Growth

  @override
  Color get tertiaryColor => const Color(0xFFD97706); // Warm Amber Trust

  @override
  String get logoAssetPath => 'assets/images/cape_finance/logo.png';

  @override
  String get logoFullAssetPath => 'assets/images/cape_finance/logo_full.png';

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

  /// Supports all 4 repayment frequencies (Daily, Weekly, Biweekly, Monthly).
  @override
  List<RepaymentFrequency> get supportedFrequencies =>
      RepaymentFrequency.values;

  /// Skip Sundays for daily collections.
  @override
  bool get allowHolidaySkip => true;

  /// Max loan: ₹10,00,000 (100,000,000 paise)
  @override
  int get maxLoanAmountPaise => 100000000;

  /// Min loan: ₹1,000 (100,000 paise)
  @override
  int get minLoanAmountPaise => 100000;
}
