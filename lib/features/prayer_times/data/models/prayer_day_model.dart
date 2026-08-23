import 'package:equatable/equatable.dart';
import '../../../../core/constants/prayer_constants.dart';
import 'prayer_time_model.dart';

class PrayerDayModel extends Equatable {
  final DateTime date;
  final PrayerTimeModel fajr;
  final PrayerTimeModel sunrise;
  final PrayerTimeModel dhuhr;
  final PrayerTimeModel asr;
  final PrayerTimeModel maghrib;
  final PrayerTimeModel isha;
  final PrayerType nextPrayerType;
  final DateTime nextPrayerTime;
  final Duration timeRemainingToNextPrayer;

  const PrayerDayModel({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.nextPrayerType,
    required this.nextPrayerTime,
    required this.timeRemainingToNextPrayer,
  });

  List<PrayerTimeModel> get allTimes => [
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
      ];

  List<PrayerTimeModel> get prayerTimesOnly => [
        fajr,
        dhuhr,
        asr,
        maghrib,
        isha,
      ];

  PrayerTimeModel? getPrayer(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return fajr;
      case PrayerType.sunrise:
        return sunrise;
      case PrayerType.dhuhr:
        return dhuhr;
      case PrayerType.asr:
        return asr;
      case PrayerType.maghrib:
        return maghrib;
      case PrayerType.isha:
        return isha;
      case PrayerType.none:
        return null;
    }
  }

  /// Returns the prayer that is currently in its Iqamah window (between Adhan and Iqamah), if any
  PrayerTimeModel? activeIqamahPrayer(DateTime now) {
    for (final p in prayerTimesOnly) {
      if (p.isCurrentlyInIqamahWindow(now)) {
        return p;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
        date,
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
        nextPrayerType,
        nextPrayerTime,
        timeRemainingToNextPrayer,
      ];
}
