import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

class DateUtilsHelper {
  static String formatPrayerTime(DateTime dateTime, {bool is24Hour = false}) {
    if (is24Hour) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String formatCountdown(Duration duration) {
    if (duration.isNegative) {
      return '00:00:00';
    }
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  static String getGregorianDateFormatted(DateTime date, {String locale = 'ar'}) {
    return DateFormat('EEEE, d MMMM yyyy', locale).format(date);
  }

  static String getHijriDateFormatted(DateTime date, {String locale = 'ar'}) {
    final hijri = HijriCalendar.fromDate(date);
    if (locale.startsWith('ar')) {
      return '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';
    }
    return '${hijri.hDay} ${hijri.toFormat('MMMM')} ${hijri.hYear} AH';
  }
}
