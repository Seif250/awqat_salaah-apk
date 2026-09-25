import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/constants/prayer_constants.dart';
import '../core/utils/date_utils.dart';
import '../features/prayer_times/data/models/prayer_day_model.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('com.awqatsalaah/widget');

  /// Send full prayer schedule (timestamps + formatted strings) to native widget.
  /// Kotlin side will auto-determine next prayer and run live countdown.
  static Future<void> updateHomeWidget({
    required PrayerDayModel prayerDay,
    required String cityName,
    required bool isArabic,
    required bool is24Hour,
    int tomorrowFajrTimestamp = 0,
  }) async {
    try {
      final isDuringIqamah = prayerDay.phase == PrayerPhase.duringIqamah;
      final focusedPrayer = prayerDay.getPrayer(prayerDay.focusPrayerType);

      final nextPrayerName = isDuringIqamah
          ? (isArabic
              ? '${prayerDay.focusPrayerType.nameArabic} (أُذِّن الآن)'
              : '${prayerDay.focusPrayerType.nameEnglish} (Adhan)')
          : (isArabic
              ? prayerDay.focusPrayerType.nameArabic
              : prayerDay.focusPrayerType.nameEnglish);

      final nextPrayerTimeFormatted = DateUtilsHelper.formatPrayerTime(
        prayerDay.targetTime,
        is24Hour: is24Hour,
      );

      final iqamahTime = focusedPrayer?.iqamahTime;
      final iqamahSubtitle = isDuringIqamah
          ? (iqamahTime != null
              ? 'متبقي للإقامة (في ${DateUtilsHelper.formatPrayerTime(iqamahTime, is24Hour: is24Hour)})'
              : 'انتظار الإقامة')
          : (iqamahTime != null && focusedPrayer!.iqamahOffsetMinutes > 0
              ? 'الإقامة: ${DateUtilsHelper.formatPrayerTime(iqamahTime, is24Hour: is24Hour)} (+${focusedPrayer.iqamahOffsetMinutes}د)'
              : 'أوقات الصلاة اليومية');

      final Map<String, dynamic> data = {
        // ── Legacy formatted strings (still used by widget display) ──
        'widget_city_name': cityName,
        'widget_app_title': 'وِرد',
        'widget_next_prayer_name': nextPrayerName,
        'widget_next_prayer_time': isDuringIqamah
            ? (iqamahTime != null ? DateUtilsHelper.formatPrayerTime(iqamahTime, is24Hour: is24Hour) : nextPrayerTimeFormatted)
            : nextPrayerTimeFormatted,
        'widget_countdown_text': iqamahSubtitle,
        'widget_next_prayer_timestamp':
            prayerDay.targetTime.millisecondsSinceEpoch,
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

        // ── NEW: Raw timestamps for native auto-update logic ──
        'widget_ts_fajr': prayerDay.fajr.time.millisecondsSinceEpoch,
        'widget_ts_sunrise': prayerDay.sunrise.time.millisecondsSinceEpoch,
        'widget_ts_dhuhr': prayerDay.dhuhr.time.millisecondsSinceEpoch,
        'widget_ts_asr': prayerDay.asr.time.millisecondsSinceEpoch,
        'widget_ts_maghrib': prayerDay.maghrib.time.millisecondsSinceEpoch,
        'widget_ts_isha': prayerDay.isha.time.millisecondsSinceEpoch,

        // ── NEW: Iqamah timestamps ──
        'widget_ts_iqamah_fajr':
            prayerDay.fajr.iqamahTime?.millisecondsSinceEpoch ?? 0,
        'widget_ts_iqamah_dhuhr':
            prayerDay.dhuhr.iqamahTime?.millisecondsSinceEpoch ?? 0,
        'widget_ts_iqamah_asr':
            prayerDay.asr.iqamahTime?.millisecondsSinceEpoch ?? 0,
        'widget_ts_iqamah_maghrib':
            prayerDay.maghrib.iqamahTime?.millisecondsSinceEpoch ?? 0,
        'widget_ts_iqamah_isha':
            prayerDay.isha.iqamahTime?.millisecondsSinceEpoch ?? 0,

        // ── NEW: Prayer names for native use ──
        'widget_name_fajr': isArabic ? 'الفجر' : 'Fajr',
        'widget_name_sunrise': isArabic ? 'الشروق' : 'Sunrise',
        'widget_name_dhuhr': isArabic ? 'الظهر' : 'Dhuhr',
        'widget_name_asr': isArabic ? 'العصر' : 'Asr',
        'widget_name_maghrib': isArabic ? 'المغرب' : 'Maghrib',
        'widget_name_isha': isArabic ? 'العشاء' : 'Isha',

        // ── Settings ──
        'widget_is_24hour': is24Hour,
        'widget_is_arabic': isArabic,

        // ── Tomorrow's Fajr for overnight rollover ──
        'widget_ts_tomorrow_fajr': tomorrowFajrTimestamp,
      };

      await _channel.invokeMethod('updateWidget', data);
    } catch (e) {
      debugPrint('🕌 WidgetService.updateHomeWidget ERROR: $e');
    }
  }

  /// Retrieve diagnostic log from native widget for troubleshooting.
  static Future<String> getWidgetDiagnostics() async {
    try {
      final result = await _channel.invokeMethod<String>('getWidgetDiagnostics');
      return result ?? 'لا توجد بيانات تشخيصية';
    } catch (e) {
      return 'خطأ في قراءة التشخيص: $e';
    }
  }

  /// Force immediate widget refresh from Flutter side.
  static Future<void> forceRefreshWidget() async {
    try {
      await _channel.invokeMethod('forceRefreshWidget');
    } catch (e) {
      debugPrint('🕌 WidgetService.forceRefreshWidget ERROR: $e');
    }
  }
}
