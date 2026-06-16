import 'package:intl/intl.dart';

/// Date / number formatting helpers (Arabic locale aware).
class Formatters {
  Formatters._();

  static String date(DateTime d) => DateFormat('d/M/yyyy').format(d);

  static String dateTime(DateTime d) => DateFormat('d/M/yyyy – HH:mm').format(d);

  static String dayName(DateTime d) => DateFormat('EEEE', 'ar').format(d);

  /// Firestore-friendly day key, e.g. 2026-06-12.
  static String dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String percent(double value) => '${value.toStringAsFixed(1)}٪';
}
