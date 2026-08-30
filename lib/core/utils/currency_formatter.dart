import 'package:intl/intl.dart';

/// Formats monetary values in Indian Rupee notation (₹ with Indian grouping).
///
/// Examples:
///   CurrencyFormatter.format(1000)       → "₹1,000.00"
///   CurrencyFormatter.format(100000)     → "₹1,00,000.00"
///   CurrencyFormatter.format(1234567.5)  → "₹12,34,567.50"
///   CurrencyFormatter.format(0)          → "₹0.00"
///
/// Note: Uses the Indian number system (lakh/crore grouping),
/// not the Western thousand-grouping.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrNoDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
  );

  /// Formats [amount] as "₹X,XX,XXX.XX" (Indian grouping, 2 decimal places).
  static String format(double amount) => _inrFormat.format(amount);

  /// Formats [amount] without decimal places — useful for whole-rupee amounts.
  static String formatNoDecimal(double amount) =>
      _inrNoDecimalFormat.format(amount);

  /// Formats [amount] compactly: "₹1.2L", "₹2.5Cr" — useful in dashboards.
  static String formatCompact(double amount) => _compactFormat.format(amount);

  /// Parses an INR-formatted string back to double.
  /// Returns null if parsing fails.
  static double? parse(String formatted) {
    try {
      final cleaned = formatted.replaceAll('₹', '').replaceAll(',', '').trim();
      return double.parse(cleaned);
    } on FormatException {
      return null;
    }
  }

  /// Returns the per-frequency suffix (e.g. "/day", "/month") with the amount.
  /// Example: CurrencyFormatter.withFrequency(250, daily) → "₹250.00/day"
  static String withFrequencySuffix(double amount, String suffix) {
    return '${format(amount)}$suffix';
  }
}
