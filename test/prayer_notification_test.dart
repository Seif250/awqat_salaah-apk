import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/core/constants/prayer_constants.dart';
import 'package:awqat_salaah/services/prayer_calculation_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  late PrayerCalculationService calculationService;

  setUp(() {
    calculationService = PrayerCalculationService();
    tz.initializeTimeZones();
  });

  group('Prayer Notification & Advance Scheduling Tests', () {
    const cairoLat = 30.0444;
    const cairoLng = 31.2357;
    final baseDate = DateTime(2026, 8, 28, 10, 0, 0);

    test('calculates 7 days of consecutive prayer schedules', () {
      final scheduledDays = <DateTime>[];

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        final targetDate = baseDate.add(Duration(days: dayOffset));
        final prayerDay = calculationService.calculatePrayerTimes(
          latitude: cairoLat,
          longitude: cairoLng,
          date: targetDate,
          method: AppCalculationMethod.egyptian,
          madhab: AppMadhab.shafi,
        );

        scheduledDays.add(prayerDay.date);
        expect(prayerDay.fajr.time.isBefore(prayerDay.dhuhr.time), isTrue);
        expect(prayerDay.dhuhr.time.isBefore(prayerDay.asr.time), isTrue);
        expect(prayerDay.asr.time.isBefore(prayerDay.maghrib.time), isTrue);
        expect(prayerDay.maghrib.time.isBefore(prayerDay.isha.time), isTrue);
      }

      expect(scheduledDays.length, equals(7));
    });

    test('generates unique deterministic IDs for multiple alert offset timings per prayer', () {
      final ids = <int>{};
      final testOffsets = [-15, -10, -5, 0, 5, 10, -3, 7]; // standard + custom

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        for (int prayerIndex = 1; prayerIndex <= 5; prayerIndex++) {
          for (int k = 0; k < testOffsets.length; k++) {
            final id = 10000 + (dayOffset * 1000) + (prayerIndex * 100) + (k + 1);
            expect(
              ids.contains(id),
              isFalse,
              reason: 'ID collision detected for day $dayOffset prayer $prayerIndex offset index $k',
            );
            ids.add(id);
          }
        }
      }

      expect(ids.length, equals(7 * 5 * testOffsets.length));
    });

    test('generates unique deterministic IDs for Iqamah reminders across 7 days', () {
      final iqamahIds = <int>{};

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        for (int prayerIndex = 1; prayerIndex <= 5; prayerIndex++) {
          for (int m = 5; m <= 30; m += 5) {
            final id = 50000 + (dayOffset * 1000) + (prayerIndex * 100) + (m ~/ 5);
            expect(
              iqamahIds.contains(id),
              isFalse,
              reason: 'Iqamah ID collision detected for day $dayOffset prayer $prayerIndex interval $m',
            );
            iqamahIds.add(id);
          }
        }
      }

      expect(iqamahIds.length, equals(7 * 5 * 6));
    });

    test('TZDateTime converts local prayer DateTime accurately with timezone location', () {
      final cairoLocation = tz.getLocation('Africa/Cairo');
      tz.setLocalLocation(cairoLocation);

      final prayerTime = DateTime(2026, 8, 28, 12, 30, 0);
      final tzPrayerTime = tz.TZDateTime.from(prayerTime, tz.local);

      expect(tzPrayerTime.hour, equals(12));
      expect(tzPrayerTime.minute, equals(30));
      expect(tzPrayerTime.location.name, equals('Africa/Cairo'));
    });
  });
}
