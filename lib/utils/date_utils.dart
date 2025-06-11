import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatTime(DateTime dateTime, {bool use24HourFormat = true}) {
    final format = use24HourFormat ? DateFormat.Hm() : DateFormat.jm();
    return format.format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat.yMd().format(dateTime);
  }

  static String formatDateTime(DateTime dateTime,
      {bool use24HourFormat = true}) {
    return '${formatDate(dateTime)} ${formatTime(dateTime, use24HourFormat: use24HourFormat)}';
  }
}
