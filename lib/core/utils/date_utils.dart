import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';
import 'arabic_numbers.dart';

class DateUtilsHelper {
  /// Format prayer time cleanly in Arabic (e.g. "04:08 م" or "16:08" for 24h)
  static String formatPrayerTime(DateTime dateTime, {bool is24Hour = false}) {
    if (is24Hour) {
      return DateFormat('HH:mm').format(dateTime);
    }
    final rawHour = dateTime.hour % 12;
    final hour = (rawHour == 0 ? 12 : rawHour).toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final marker = dateTime.hour >= 12 ? 'م' : 'ص';
    return '$hour:$minute $marker';
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
    return DateFormat('EEEE، d MMMM yyyy', locale).format(date);
  }

  static const List<String> _hijriMonthsArabic = [
    '',
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الثاني',
    'جمادى الأولى',
    'جمادى الثانية',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  static String getHijriDateFormatted(DateTime date, {String locale = 'ar'}) {
    final hijri = HijriCalendar.fromDate(date);
    if (locale.startsWith('ar')) {
      final monthName = (hijri.hMonth >= 1 && hijri.hMonth <= 12)
          ? _hijriMonthsArabic[hijri.hMonth]
          : hijri.longMonthName;
      return '${toArabicDigits(hijri.hDay)} $monthName ${toArabicDigits(hijri.hYear)} هـ';
    }
    return '${hijri.hDay} ${hijri.toFormat('MMMM')} ${hijri.hYear} AH';
  }
}
