import 'package:intl/intl.dart';

class DateKey {
  static final DateFormat _formatter = DateFormat('yyyy-MM-dd');

  static String fromDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _formatter.format(normalized);
  }

  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
