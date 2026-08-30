import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';

void main() {
  test('DateFormat without init throws for en_IN', () {
    Intl.defaultLocale = 'en_IN';
    expect(
      () => DateFormat('dd MMM yyyy').format(DateTime(2025, 1, 15)),
      throwsA(isA<Object>()),
    );
  });

  test('DateFormat en_US works without init', () {
    expect(
      DateFormat('dd MMM yyyy', 'en_US').format(DateTime(2025, 1, 15)),
      '15 Jan 2025',
    );
  });

  test('AppDateUtils.formatDisplay works when default locale is en_IN', () {
    Intl.defaultLocale = 'en_IN';
    expect(AppDateUtils.formatDisplay(DateTime(2025, 1, 15)), '15 Jan 2025');
    expect(AppDateUtils.formatShort(DateTime(2025, 1, 15)), '15/01/2025');
    expect(AppDateUtils.formatMonthYear(DateTime(2025, 1, 15)), 'January 2025');
  });

  test('initializeDateFormatting makes en_IN DateFormat work', () async {
    await initializeDateFormatting('en_IN');
    Intl.defaultLocale = 'en_IN';
    expect(DateFormat('dd MMM yyyy').format(DateTime(2025, 1, 15)), isNotEmpty);
  });
}
