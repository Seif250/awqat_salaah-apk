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

class ToggleNotificationSoundEvent extends SettingsEvent {
  final bool soundEnabled;
  const ToggleNotificationSoundEvent(this.soundEnabled);

  @override
  List<Object?> get props => [soundEnabled];
}

class ChangeNotificationSoundTypeEvent extends SettingsEvent {
  final String soundType;
  const ChangeNotificationSoundTypeEvent(this.soundType);

  @override
  List<Object?> get props => [soundType];
}

class ChangeNotificationOffsetEvent extends SettingsEvent {
  final int offsetMinutes;
  const ChangeNotificationOffsetEvent(this.offsetMinutes);

  @override
  List<Object?> get props => [offsetMinutes];
}

class ChangeNotificationOffsetsEvent extends SettingsEvent {
  final List<int> offsets;
  const ChangeNotificationOffsetsEvent(this.offsets);

  @override
  List<Object?> get props => [offsets];
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

class UpdateIqamahOffsetsEvent extends SettingsEvent {
  final int? fajr;
  final int? dhuhr;
  final int? asr;
  final int? maghrib;
  final int? isha;

  const UpdateIqamahOffsetsEvent({
    this.fajr,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
  });

  @override
  List<Object?> get props => [fajr, dhuhr, asr, maghrib, isha];
}

class ToggleAzkarMorningReminderEvent extends SettingsEvent {
  final bool enabled;
  const ToggleAzkarMorningReminderEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleAzkarEveningReminderEvent extends SettingsEvent {
  final bool enabled;
  const ToggleAzkarEveningReminderEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleAzkarSleepReminderEvent extends SettingsEvent {
  final bool enabled;
  const ToggleAzkarSleepReminderEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class ToggleAzkarQiyamReminderEvent extends SettingsEvent {
  final bool enabled;
  const ToggleAzkarQiyamReminderEvent(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class UpdateAzkarQiyamMinutesEvent extends SettingsEvent {
  final int minutes;
  const UpdateAzkarQiyamMinutesEvent(this.minutes);

  @override
  List<Object?> get props => [minutes];
}
