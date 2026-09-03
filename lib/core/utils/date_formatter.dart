import 'package:intl/intl.dart';

/// Utilities for standard date formatting throughout the application
class DateFormatter {
  DateFormatter._();

  static final DateFormat _shortDate = DateFormat('MMM d, yyyy');
  static final DateFormat _dayMonth = DateFormat('MMM d');
  static final DateFormat _monthYear = DateFormat('MMMM yyyy');
  static final DateFormat _timeOnly = DateFormat('h:mm a');

  static String formatDate(DateTime date) {
    return _shortDate.format(date);
  }

  static String formatDayMonth(DateTime date) {
    return _dayMonth.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYear.format(date);
  }

  static String formatTime(DateTime time) {
    return _timeOnly.format(time);
  }

  /// Returns a clean relative date string (e.g. "Today", "Yesterday", "Tomorrow", "MMM d, yyyy")
  static String formatRelativeDate(DateTime date, {DateTime? relativeTo}) {
    final now = relativeTo ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final difference = target.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1 && difference < 7) return 'In $difference days';
    if (difference < -1 && difference > -7) return '${difference.abs()} days ago';

    return _shortDate.format(date);
  }
}
