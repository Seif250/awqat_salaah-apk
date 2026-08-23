import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/prayer_constants.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {
  const LoadSettingsEvent();
}

class ChangeCalculationMethodEvent extends SettingsEvent {
  final AppCalculationMethod method;
  const ChangeCalculationMethodEvent(this.method);

  @override
  List<Object?> get props => [method];
}

class ChangeMadhabEvent extends SettingsEvent {
  final AppMadhab madhab;
  const ChangeMadhabEvent(this.madhab);

  @override
  List<Object?> get props => [madhab];
}

class ToggleNotificationsEvent extends SettingsEvent {
  final bool enabled;
  const ToggleNotificationsEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ChangeNotificationOffsetEvent extends SettingsEvent {
  final int offsetMinutes;
  const ChangeNotificationOffsetEvent(this.offsetMinutes);

  @override
  List<Object?> get props => [offsetMinutes];
}

class ChangeThemeModeEvent extends SettingsEvent {
  final ThemeMode themeMode;
  const ChangeThemeModeEvent(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class Toggle24HourFormatEvent extends SettingsEvent {
  final bool is24Hour;
  const Toggle24HourFormatEvent(this.is24Hour);

  @override
  List<Object?> get props => [is24Hour];
}

class UpdateAdjustmentsEvent extends SettingsEvent {
  final int? fajr;
  final int? sunrise;
  final int? dhuhr;
  final int? asr;
  final int? maghrib;
  final int? isha;

  const UpdateAdjustmentsEvent({
    this.fajr,
    this.sunrise,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
  });

  @override
  List<Object?> get props => [fajr, sunrise, dhuhr, asr, maghrib, isha];
}
