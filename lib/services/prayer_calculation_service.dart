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
    AppCalculationMethod method = AppCalculationMethod.muslimWorldLeague,
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

    // Apply manual minute adjustments
    final fajr = rawPrayerTimes.fajr.add(Duration(minutes: adjustFajr));
    final sunrise = rawPrayerTimes.sunrise.add(Duration(minutes: adjustSunrise));
    final dhuhr = rawPrayerTimes.dhuhr.add(Duration(minutes: adjustDhuhr));
    final asr = rawPrayerTimes.asr.add(Duration(minutes: adjustAsr));
    final maghrib = rawPrayerTimes.maghrib.add(Duration(minutes: adjustMaghrib));
    final isha = rawPrayerTimes.isha.add(Duration(minutes: adjustIsha));

    // Calculate exact Iqamah timestamps
    final fajrIqamah = fajr.add(Duration(minutes: iqamahFajr));
    final dhuhrIqamah = dhuhr.add(Duration(minutes: iqamahDhuhr));
    final asrIqamah = asr.add(Duration(minutes: iqamahAsr));
    final maghribIqamah = maghrib.add(Duration(minutes: iqamahMaghrib));
    final ishaIqamah = isha.add(Duration(minutes: iqamahIsha));

    final now = DateTime.now();

    PrayerType focusPrayer;
    DateTime targetTime;
    PrayerPhase phase;

    // Full 24-hour phase-aware lifecycle:
    // Before Adhan -> During Iqamah -> Next Prayer
    if (now.isBefore(fajr)) {
      focusPrayer = PrayerType.fajr;
      targetTime = fajr;
      phase = PrayerPhase.beforeAdhan;
    } else if (now.isBefore(fajrIqamah)) {
      focusPrayer = PrayerType.fajr;
      targetTime = fajrIqamah;
      phase = PrayerPhase.duringIqamah;
    } else if (now.isBefore(sunrise)) {
      focusPrayer = PrayerType.sunrise;
      targetTime = sunrise;
      phase = PrayerPhase.beforeAdhan;
    } else if (now.isBefore(dhuhr)) {
      focusPrayer = PrayerType.dhuhr;
      targetTime = dhuhr;
      phase = PrayerPhase.beforeAdhan;
    } else if (now.isBefore(dhuhrIqamah)) {
      focusPrayer = PrayerType.dhuhr;
      targetTime = dhuhrIqamah;
      phase = PrayerPhase.duringIqamah;
    } else if (now.isBefore(asr)) {
      focusPrayer = PrayerType.asr;
      targetTime = asr;
      phase = PrayerPhase.beforeAdhan;
    } else if (now.isBefore(asrIqamah)) {
      focusPrayer = PrayerType.asr;
      targetTime = asrIqamah;
      phase = PrayerPhase.duringIqamah;
    } else if (now.isBefore(maghrib)) {
      focusPrayer = PrayerType.maghrib;
      targetTime = maghrib;
      phase = PrayerPhase.beforeAdhan;
    } else if (now.isBefore(maghribIqamah)) {
      focusPrayer = PrayerType.maghrib;
      targetTime = maghribIqamah;
      phase = PrayerPhase.duringIqamah;
    } else if (now.isBefore(isha)) {
      focusPrayer = PrayerType.isha;
      targetTime = isha;
      phase = PrayerPhase.beforeAdhan;
    } else if (now.isBefore(ishaIqamah)) {
      focusPrayer = PrayerType.isha;
      targetTime = ishaIqamah;
      phase = PrayerPhase.duringIqamah;
    } else {
      // After Isha Iqamah: next prayer is tomorrow's Fajr
      final tomorrow = date.add(const Duration(days: 1));
      final tomorrowComponents = DateComponents.from(tomorrow);
      final tomorrowPrayerTimes = PrayerTimes(coordinates, tomorrowComponents, params);
      focusPrayer = PrayerType.fajr;
      targetTime = tomorrowPrayerTimes.fajr.add(Duration(minutes: adjustFajr));
      phase = PrayerPhase.beforeAdhan;
    }

    final remaining = targetTime.difference(now);

    return PrayerDayModel(
      date: date,
      fajr: PrayerTimeModel(
        type: PrayerType.fajr,
        time: fajr,
        isNext: focusPrayer == PrayerType.fajr && phase == PrayerPhase.beforeAdhan,
        isCurrent: focusPrayer == PrayerType.fajr && phase == PrayerPhase.duringIqamah,
        iqamahOffsetMinutes: iqamahFajr,
      ),
      sunrise: PrayerTimeModel(
        type: PrayerType.sunrise,
        time: sunrise,
        isNext: focusPrayer == PrayerType.sunrise,
        isCurrent: false,
        iqamahOffsetMinutes: 0,
      ),
      dhuhr: PrayerTimeModel(
        type: PrayerType.dhuhr,
        time: dhuhr,
        isNext: focusPrayer == PrayerType.dhuhr && phase == PrayerPhase.beforeAdhan,
        isCurrent: focusPrayer == PrayerType.dhuhr && phase == PrayerPhase.duringIqamah,
        iqamahOffsetMinutes: iqamahDhuhr,
      ),
      asr: PrayerTimeModel(
        type: PrayerType.asr,
        time: asr,
        isNext: focusPrayer == PrayerType.asr && phase == PrayerPhase.beforeAdhan,
        isCurrent: focusPrayer == PrayerType.asr && phase == PrayerPhase.duringIqamah,
        iqamahOffsetMinutes: iqamahAsr,
      ),
      maghrib: PrayerTimeModel(
        type: PrayerType.maghrib,
        time: maghrib,
        isNext: focusPrayer == PrayerType.maghrib && phase == PrayerPhase.beforeAdhan,
        isCurrent: focusPrayer == PrayerType.maghrib && phase == PrayerPhase.duringIqamah,
        iqamahOffsetMinutes: iqamahMaghrib,
      ),
      isha: PrayerTimeModel(
        type: PrayerType.isha,
        time: isha,
        isNext: focusPrayer == PrayerType.isha && phase == PrayerPhase.beforeAdhan,
        isCurrent: focusPrayer == PrayerType.isha && phase == PrayerPhase.duringIqamah,
        iqamahOffsetMinutes: iqamahIsha,
      ),
      focusPrayerType: focusPrayer,
      targetTime: targetTime,
      phase: phase,
      timeRemaining: remaining.isNegative ? Duration.zero : remaining,
    );
  }
}
