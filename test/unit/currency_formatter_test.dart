import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter.format', () {
    test('formats rupees with proper Indian number grouping', () {
      expect(CurrencyFormatter.format(0), equals('₹0.00'));
      expect(CurrencyFormatter.format(1000), equals('₹1,000.00'));
      expect(CurrencyFormatter.format(100000), equals('₹1,00,000.00'));
      expect(CurrencyFormatter.format(1234567.50), equals('₹12,34,567.50'));
    });

    test('formats without decimals', () {
      expect(CurrencyFormatter.formatNoDecimal(100000), equals('₹1,00,000'));
      expect(CurrencyFormatter.formatNoDecimal(500), equals('₹500'));
    });

    test('formats compact notation', () {
      final compactLakh = CurrencyFormatter.formatCompact(100000);
      expect(
        compactLakh.contains('L') ||
            compactLakh.contains('100K') ||
            compactLakh.contains('1L'),
        isTrue,
      );
    });

    test('parses formatted currency string back to double', () {
      expect(CurrencyFormatter.parse('₹1,00,000.00'), equals(100000.0));
      expect(CurrencyFormatter.parse('₹12,34,567.50'), equals(1234567.50));
      expect(CurrencyFormatter.parse('invalid'), isNull);
    });

    test('formats with frequency suffix', () {
      expect(
        CurrencyFormatter.withFrequencySuffix(250, '/day'),
        equals('₹250.00/day'),
      );
      expect(
        CurrencyFormatter.withFrequencySuffix(5000, '/month'),
        equals('₹5,000.00/month'),
      );
    });
  });
}
