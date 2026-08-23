import 'package:equatable/equatable.dart';
import '../../data/models/prayer_day_model.dart';

abstract class PrayerState extends Equatable {
  const PrayerState();

  @override
  List<Object?> get props => [];
}

class PrayerInitial extends PrayerState {
  const PrayerInitial();
}

class PrayerLoading extends PrayerState {
  const PrayerLoading();
}

class PrayerLoaded extends PrayerState {
  final PrayerDayModel prayerDay;
  final Duration remainingDuration;
  final String cityName;
  final String countryName;
  final DateTime lastCalculated;

  const PrayerLoaded({
    required this.prayerDay,
    required this.remainingDuration,
    required this.cityName,
    required this.countryName,
    required this.lastCalculated,
  });

  PrayerLoaded copyWith({
    PrayerDayModel? prayerDay,
    Duration? remainingDuration,
    String? cityName,
    String? countryName,
    DateTime? lastCalculated,
  }) {
    return PrayerLoaded(
      prayerDay: prayerDay ?? this.prayerDay,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      cityName: cityName ?? this.cityName,
      countryName: countryName ?? this.countryName,
      lastCalculated: lastCalculated ?? this.lastCalculated,
    );
  }

  @override
  List<Object?> get props => [
        prayerDay,
        remainingDuration,
        cityName,
        countryName,
        lastCalculated,
      ];
}

class PrayerError extends PrayerState {
  final String message;

  const PrayerError(this.message);

  @override
  List<Object?> get props => [message];
}
