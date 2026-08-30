import 'package:flutter/material.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';

/// Abstract contract that every white-label client must implement.
/// All branding, config and feature flags live here — never hardcode these.
abstract class AppConfig {
  /// Display name shown in the app bar and system UI.
  String get appName;

  /// Android/iOS package identifier (e.g. "net.aravin.cape_finance").
  String get packageName;

  /// Brand primary color — used for buttons, app bars, key actions.
  Color get primaryColor;

  /// Brand secondary color — used for success states, approvals.
  Color get secondaryColor;

  /// Brand tertiary color — used for secure areas, info badges.
  Color get tertiaryColor;

  /// Asset path to the client logo (e.g. "assets/images/local_lending_hub/logo.png").
  String get logoAssetPath;

  /// Asset path to full horizontal logo with brand wordmark (e.g. for splash & auth headers).
  String get logoFullAssetPath;

  /// Backend API base URL. Empty string = use Firestore directly.
  String get apiBaseUrl;

  /// Currency symbol displayed in the UI (e.g. "₹").
  String get currencySymbol;

  /// Phone country dial code (e.g. "+91").
  String get phoneCountryCode;

  /// Whether to show the admin/lender section of the app.
  bool get enableAdminFeatures;

  /// Which repayment frequencies this client offers to borrowers.
  /// Controls the options shown in the Apply for Loan form.
  List<RepaymentFrequency> get supportedFrequencies;

  /// Whether to shift due dates that fall on Sundays or public holidays
  /// to the next working day (common in daily-repayment micro-lending).
  bool get allowHolidaySkip;

  /// Maximum loan amount in the smallest currency unit (paise for ₹).
  int get maxLoanAmountPaise;

  /// Minimum loan amount in the smallest currency unit.
  int get minLoanAmountPaise;

  /// Minimum flat annual interest rate shown to borrowers (percent).
  double get minAnnualInterestRatePercent => 12;

  /// Maximum flat annual interest rate shown to borrowers (percent).
  double get maxAnnualInterestRatePercent => 48;

  /// Default flat annual interest rate (percent).
  double get defaultAnnualInterestRatePercent => 24;
}
