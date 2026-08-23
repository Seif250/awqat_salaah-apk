import 'package:adhan/adhan.dart';
import '../core/constants/prayer_constants.dart';
import '../features/prayer_times/data/models/prayer_day_model.dart';
import '../features/prayer_times/data/models/prayer_time_model.dart';

class PrayerCalculationService {
  CalculationParameters _getCalculationParameters(
    AppCalculationMethod method,
    AppMadhab madhab,
  ) {
    CalculationParameters params;

    switch (method) {
      case AppCalculationMethod.egyptian:
        params = CalculationMethod.egyptian.getParameters();
        break;
      case AppCalculationMethod.muslimWorldLeague:
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case AppCalculationMethod.isna:
        params = CalculationMethod.north_america.getParameters();
        break;
      case AppCalculationMethod.ummAlQura:
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case AppCalculationMethod.karachi:
        params = CalculationMethod.karachi.getParameters();
        break;
      case AppCalculationMethod.moonsightingCommittee:
        params = CalculationParameters(fajrAngle: 18.0, ishaAngle: 18.0);
        break;
      case AppCalculationMethod.kuwait:
        params = CalculationMethod.kuwait.getParameters();
        break;
      case AppCalculationMethod.qatar:
        params = CalculationMethod.qatar.getParameters();
        break;
      case AppCalculationMethod.singapore:
        params = CalculationMethod.singapore.getParameters();
        break;
      case AppCalculationMethod.tehran:
        params = CalculationMethod.tehran.getParameters();
        break;
      case AppCalculationMethod.turkey:
        params = CalculationMethod.turkey.getParameters();
        break;
      case AppCalculationMethod.dubai:
        params = CalculationMethod.dubai.getParameters();
        break;
      case AppCalculationMethod.northAmerica:
        params = CalculationMethod.north_america.getParameters();
        break;
    }

    params.madhab = (madhab == AppMadhab.hanafi) ? Madhab.hanafi : Madhab.shafi;
    return params;
  }

  PrayerDayModel calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    AppCalculationMethod method = AppCalculationMethod.egyptian,
    AppMadhab madhab = AppMadhab.shafi,
    int adjustFajr = 0,
    int adjustSunrise = 0,
    int adjustDhuhr = 0,
    int adjustAsr = 0,
    int adjustMaghrib = 0,
    int adjustIsha = 0,
    int iqamahFajr = 20,
    int iqamahDhuhr = 15,
    int iqamahAsr = 15,
    int iqamahMaghrib = 10,
    int iqamahIsha = 15,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final dateComponents = DateComponents.from(date);
    final params = _getCalculationParameters(method, madhab);

    final rawPrayerTimes = PrayerTimes(coordinates, dateComponents, params);

    // Apply manual minute adjustments if any
    final fajr = rawPrayerTimes.fajr.add(Duration(minutes: adjustFajr));
    final sunrise = rawPrayerTimes.sunrise.add(Duration(minutes: adjustSunrise));
    final dhuhr = rawPrayerTimes.dhuhr.add(Duration(minutes: adjustDhuhr));
    final asr = rawPrayerTimes.asr.add(Duration(minutes: adjustAsr));
    final maghrib = rawPrayerTimes.maghrib.add(Duration(minutes: adjustMaghrib));
    final isha = rawPrayerTimes.isha.add(Duration(minutes: adjustIsha));

    final now = DateTime.now();
    PrayerType nextPrayer = PrayerType.none;
    DateTime nextTime = fajr;
    PrayerType currentPrayer = PrayerType.none;

    // Determine current and next prayer
    if (now.isBefore(fajr)) {
      nextPrayer = PrayerType.fajr;
      nextTime = fajr;
      currentPrayer = PrayerType.isha; // From previous night
    } else if (now.isBefore(sunrise)) {
      nextPrayer = PrayerType.sunrise;
      nextTime = sunrise;
      currentPrayer = PrayerType.fajr;
    } else if (now.isBefore(dhuhr)) {
      nextPrayer = PrayerType.dhuhr;
      nextTime = dhuhr;
      currentPrayer = PrayerType.sunrise;
    } else if (now.isBefore(asr)) {
      nextPrayer = PrayerType.asr;
      nextTime = asr;
      currentPrayer = PrayerType.dhuhr;
    } else if (now.isBefore(maghrib)) {
      nextPrayer = PrayerType.maghrib;
      nextTime = maghrib;
      currentPrayer = PrayerType.asr;
    } else if (now.isBefore(isha)) {
      nextPrayer = PrayerType.isha;
      nextTime = isha;
      currentPrayer = PrayerType.maghrib;
    } else {
      // After Isha today, the next prayer is tomorrow's Fajr
      final tomorrow = date.add(const Duration(days: 1));
      final tomorrowComponents = DateComponents.from(tomorrow);
      final tomorrowPrayerTimes = PrayerTimes(coordinates, tomorrowComponents, params);
      nextPrayer = PrayerType.fajr;
      nextTime = tomorrowPrayerTimes.fajr.add(Duration(minutes: adjustFajr));
      currentPrayer = PrayerType.isha;
    }

    final remaining = nextTime.difference(now);

    return PrayerDayModel(
      date: date,
      fajr: PrayerTimeModel(
        type: PrayerType.fajr,
        time: fajr,
        isNext: nextPrayer == PrayerType.fajr,
        isCurrent: currentPrayer == PrayerType.fajr,
        iqamahOffsetMinutes: iqamahFajr,
      ),
      sunrise: PrayerTimeModel(
        type: PrayerType.sunrise,
        time: sunrise,
        isNext: nextPrayer == PrayerType.sunrise,
        isCurrent: currentPrayer == PrayerType.sunrise,
        iqamahOffsetMinutes: 0,
      ),
      dhuhr: PrayerTimeModel(
        type: PrayerType.dhuhr,
        time: dhuhr,
        isNext: nextPrayer == PrayerType.dhuhr,
        isCurrent: currentPrayer == PrayerType.dhuhr,
        iqamahOffsetMinutes: iqamahDhuhr,
      ),
      asr: PrayerTimeModel(
        type: PrayerType.asr,
        time: asr,
        isNext: nextPrayer == PrayerType.asr,
        isCurrent: currentPrayer == PrayerType.asr,
        iqamahOffsetMinutes: iqamahAsr,
      ),
      maghrib: PrayerTimeModel(
        type: PrayerType.maghrib,
        time: maghrib,
        isNext: nextPrayer == PrayerType.maghrib,
        isCurrent: currentPrayer == PrayerType.maghrib,
        iqamahOffsetMinutes: iqamahMaghrib,
      ),
      isha: PrayerTimeModel(
        type: PrayerType.isha,
        time: isha,
        isNext: nextPrayer == PrayerType.isha,
        isCurrent: currentPrayer == PrayerType.isha,
        iqamahOffsetMinutes: iqamahIsha,
      ),
      nextPrayerType: nextPrayer,
      nextPrayerTime: nextTime,
      timeRemainingToNextPrayer: remaining.isNegative ? Duration.zero : remaining,
    );
  }
}
