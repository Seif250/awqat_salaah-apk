import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/core/utils/date_utils.dart';

void main() {
  group('DateUtilsHelper Tests', () {
    test('formatCountdown formats positive durations as HH:mm:ss', () {
      const duration = Duration(hours: 2, minutes: 15, seconds: 30);
      final formatted = DateUtilsHelper.formatCountdown(duration);
      expect(formatted, equals('02:15:30'));
    });

    test('formatCountdown formats negative duration as 00:00:00', () {
      const duration = Duration(seconds: -10);
      final formatted = DateUtilsHelper.formatCountdown(duration);
      expect(formatted, equals('00:00:00'));
    });

    test('formatPrayerTime in 24-hour and 12-hour format', () {
      final time = DateTime(2026, 8, 21, 15, 30);
      final time24 = DateUtilsHelper.formatPrayerTime(time, is24Hour: true);
      final time12 = DateUtilsHelper.formatPrayerTime(time, is24Hour: false);

      expect(time24, equals('15:30'));
      expect(time12, contains('03:30'));
    });
  });
}
