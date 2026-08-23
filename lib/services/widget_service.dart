import 'package:flutter/services.dart';
import '../core/constants/prayer_constants.dart';
import '../core/utils/date_utils.dart';
import '../features/prayer_times/data/models/prayer_day_model.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.awqatsalaah/widget');

  static Future<void> updateHomeWidget({
    required PrayerDayModel prayerDay,
    required String cityName,
    required bool isArabic,
    required bool is24Hour,
  }) async {
    try {
      final nextPrayerName = isArabic
          ? prayerDay.nextPrayerType.nameArabic
          : prayerDay.nextPrayerType.nameEnglish;

      final nextPrayerTimeFormatted = DateUtilsHelper.formatPrayerTime(
        prayerDay.nextPrayerTime,
        is24Hour: is24Hour,
      );

      final Map<String, dynamic> data = {
        'widget_city_name': cityName,
        'widget_next_prayer_name': nextPrayerName,
        'widget_next_prayer_time': nextPrayerTimeFormatted,
        'widget_next_prayer_timestamp':
            prayerDay.nextPrayerTime.millisecondsSinceEpoch,
        'widget_fajr': DateUtilsHelper.formatPrayerTime(prayerDay.fajr.time,
            is24Hour: is24Hour),
        'widget_sunrise': DateUtilsHelper.formatPrayerTime(
            prayerDay.sunrise.time,
            is24Hour: is24Hour),
        'widget_dhuhr': DateUtilsHelper.formatPrayerTime(prayerDay.dhuhr.time,
            is24Hour: is24Hour),
        'widget_asr': DateUtilsHelper.formatPrayerTime(prayerDay.asr.time,
            is24Hour: is24Hour),
        'widget_maghrib': DateUtilsHelper.formatPrayerTime(
            prayerDay.maghrib.time,
            is24Hour: is24Hour),
        'widget_isha': DateUtilsHelper.formatPrayerTime(prayerDay.isha.time,
            is24Hour: is24Hour),
      };

      await _channel.invokeMethod('updateWidget', data);
    } catch (_) {
      // Ignored if widget not added on home screen yet
    }
  }
}
