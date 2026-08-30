import 'package:flutter/material.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/flavors/app_config.dart';

/// Singleton that holds the active flavor's configuration.
///
/// Must be set before [runApp] in each flavor's main_*.dart entrypoint.
///
/// Usage:
/// ```dart
/// FlavorConfig.instance = LocalLendingHubConfig();
/// ```
///
/// Access anywhere:
/// ```dart
/// FlavorConfig.instance.primaryColor
/// FlavorConfig.instance.appName
/// ```
class FlavorConfig {
  // Private constructor — this class should not be instantiated.
  FlavorConfig._();

  /// The active white-label configuration.
  /// Set this in your flavor's main_*.dart before calling runApp().
  // ignore: library_private_types_in_public_api
  static late AppConfig instance;

  /// Convenience getters — delegates to the active AppConfig.
  static String get appName => instance.appName;
  static Color get primaryColor => instance.primaryColor;
  static Color get secondaryColor => instance.secondaryColor;
  static Color get tertiaryColor => instance.tertiaryColor;
  static String get logoAssetPath => instance.logoAssetPath;
  static String get logoFullAssetPath => instance.logoFullAssetPath;
  static String get currencySymbol => instance.currencySymbol;

  static String get phoneCountryCode => instance.phoneCountryCode;
  static bool get enableAdminFeatures => instance.enableAdminFeatures;
  static List<RepaymentFrequency> get supportedFrequencies =>
      instance.supportedFrequencies;
  static bool get allowHolidaySkip => instance.allowHolidaySkip;
  static int get minLoanAmountPaise => instance.minLoanAmountPaise;
  static int get maxLoanAmountPaise => instance.maxLoanAmountPaise;
  static double get minLoanAmountRupees => instance.minLoanAmountPaise / 100.0;
  static double get maxLoanAmountRupees => instance.maxLoanAmountPaise / 100.0;
  static double get minAnnualInterestRatePercent =>
      instance.minAnnualInterestRatePercent;
  static double get maxAnnualInterestRatePercent =>
      instance.maxAnnualInterestRatePercent;
  static double get defaultAnnualInterestRatePercent =>
      instance.defaultAnnualInterestRatePercent;
}
