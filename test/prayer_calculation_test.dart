import 'package:flutter_test/flutter_test.dart';
import 'package:awqat_salaah/core/constants/prayer_constants.dart';
import 'package:awqat_salaah/services/prayer_calculation_service.dart';

void main() {
  late PrayerCalculationService calculationService;

  setUp(() {
    calculationService = PrayerCalculationService();
  });

  group('Prayer Calculation Tests (Cairo, Egypt)', () {
    const cairoLat = 30.0444;
    const cairoLng = 31.2357;
    final testDate = DateTime(2026, 8, 21);

    test('calculates all 6 prayer and sun times in correct chronological order', () {
      final prayerDay = calculationService.calculatePrayerTimes(
        latitude: cairoLat,
        longitude: cairoLng,
        date: testDate,
        method: AppCalculationMethod.egyptian,
        madhab: AppMadhab.shafi,
      );

      final fajr = prayerDay.fajr.time;
      final sunrise = prayerDay.sunrise.time;
      final dhuhr = prayerDay.dhuhr.time;
      final asr = prayerDay.asr.time;
      final maghrib = prayerDay.maghrib.time;
      final isha = prayerDay.isha.time;

      expect(fajr.isBefore(sunrise), isTrue);
      expect(sunrise.isBefore(dhuhr), isTrue);
      expect(dhuhr.isBefore(asr), isTrue);
      expect(asr.isBefore(maghrib), isTrue);
      expect(maghrib.isBefore(isha), isTrue);
    });

    test('Hanafi madhab produces later Asr prayer time than Shafi madhab', () {
      final shafiDay = calculationService.calculatePrayerTimes(
        latitude: cairoLat,
        longitude: cairoLng,
        date: testDate,
        method: AppCalculationMethod.egyptian,
        madhab: AppMadhab.shafi,
      );

      final hanafiDay = calculationService.calculatePrayerTimes(
        latitude: cairoLat,
        longitude: cairoLng,
        date: testDate,
        method: AppCalculationMethod.egyptian,
        madhab: AppMadhab.hanafi,
      );

      expect(hanafiDay.asr.time.isAfter(shafiDay.asr.time), isTrue);
    });

    test('Minute adjustments properly offset calculated times', () {
      final baseDay = calculationService.calculatePrayerTimes(
        latitude: cairoLat,
        longitude: cairoLng,
        date: testDate,
        method: AppCalculationMethod.egyptian,
      );

      final adjustedDay = calculationService.calculatePrayerTimes(
        latitude: cairoLat,
        longitude: cairoLng,
        date: testDate,
        method: AppCalculationMethod.egyptian,
        adjustFajr: 5,
        adjustMaghrib: -3,
      );

      expect(
        adjustedDay.fajr.time.difference(baseDay.fajr.time).inMinutes,
        equals(5),
      );
      expect(
        adjustedDay.maghrib.time.difference(baseDay.maghrib.time).inMinutes,
        equals(-3),
      );
    });
  });
}
