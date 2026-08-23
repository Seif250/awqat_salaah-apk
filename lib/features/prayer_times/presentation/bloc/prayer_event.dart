import 'package:equatable/equatable.dart';

abstract class PrayerEvent extends Equatable {
  const PrayerEvent();

  @override
  List<Object?> get props => [];
}

class LoadPrayerTimesEvent extends PrayerEvent {
  const LoadPrayerTimesEvent();
}

class RefreshPrayerTimesEvent extends PrayerEvent {
  const RefreshPrayerTimesEvent();
}

class TimerTickEvent extends PrayerEvent {
  const TimerTickEvent();
}
