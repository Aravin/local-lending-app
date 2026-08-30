import 'package:intl/intl.dart';

/// Date formatting and calculation utilities for Indian local lending schedules.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _shortFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  /// Formats date as "15 Jan 2025".
  static String formatDisplay(DateTime date) => _displayFormat.format(date);

  /// Formats date as "15/01/2025".
  static String formatShort(DateTime date) => _shortFormat.format(date);

  /// Formats date as "January 2025".
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Checks if two dates fall on the exact same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Calculates number of days between two dates (ignoring time components).
  static int daysDifference(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }
}
