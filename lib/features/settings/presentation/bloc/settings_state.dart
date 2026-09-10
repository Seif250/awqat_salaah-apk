import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/prayer_constants.dart';

class SettingsState extends Equatable {
  final AppCalculationMethod calculationMethod;
  final AppMadhab madhab;
  final bool notificationsEnabled;
  final bool notificationSoundEnabled;
  final String notificationSoundType;
  final int notificationOffsetMinutes;
  final List<int> notificationOffsets;
  final ThemeMode themeMode;
  final bool is24HourFormat;

  // Minute Adjustments
  final int adjustFajr;
  final int adjustSunrise;
  final int adjustDhuhr;
  final int adjustAsr;
  final int adjustMaghrib;
  final int adjustIsha;

  // Iqamah Offsets (Minutes after Adhan)
  final int iqamahFajr;
  final int iqamahDhuhr;
  final int iqamahAsr;
  final int iqamahMaghrib;
  final int iqamahIsha;

  // Azkar Reminders
  final bool isAzkarMorningReminderEnabled;
  final bool isAzkarEveningReminderEnabled;
  final bool isAzkarSleepReminderEnabled;
  final bool isAzkarQiyamReminderEnabled;
  final int azkarQiyamMinutesBeforeFajr;

  const SettingsState({
    this.calculationMethod = AppCalculationMethod.egyptian,
    this.madhab = AppMadhab.shafi,
    this.notificationsEnabled = true,
    this.notificationSoundEnabled = true,
    this.notificationSoundType = 'hayya',
    this.notificationOffsetMinutes = 0,
    this.notificationOffsets = const [0],
    this.themeMode = ThemeMode.system,
    this.is24HourFormat = false,
    this.adjustFajr = 0,
    this.adjustSunrise = 0,
    this.adjustDhuhr = 0,
    this.adjustAsr = 0,
    this.adjustMaghrib = 0,
    this.adjustIsha = 0,
    this.iqamahFajr = 20,
    this.iqamahDhuhr = 15,
    this.iqamahAsr = 15,
    this.iqamahMaghrib = 10,
    this.iqamahIsha = 15,
    this.isAzkarMorningReminderEnabled = true,
    this.isAzkarEveningReminderEnabled = true,
    this.isAzkarSleepReminderEnabled = true,
    this.isAzkarQiyamReminderEnabled = true,
    this.azkarQiyamMinutesBeforeFajr = 60,
  });

  SettingsState copyWith({
    AppCalculationMethod? calculationMethod,
    AppMadhab? madhab,
    bool? notificationsEnabled,
    bool? notificationSoundEnabled,
    String? notificationSoundType,
    int? notificationOffsetMinutes,
    List<int>? notificationOffsets,
    ThemeMode? themeMode,
    bool? is24HourFormat,
    int? adjustFajr,
    int? adjustSunrise,
    int? adjustDhuhr,
    int? adjustAsr,
    int? adjustMaghrib,
    int? adjustIsha,
    int? iqamahFajr,
    int? iqamahDhuhr,
    int? iqamahAsr,
    int? iqamahMaghrib,
    int? iqamahIsha,
    bool? isAzkarMorningReminderEnabled,
    bool? isAzkarEveningReminderEnabled,
    bool? isAzkarSleepReminderEnabled,
    bool? isAzkarQiyamReminderEnabled,
    int? azkarQiyamMinutesBeforeFajr,
  }) {
    return SettingsState(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationSoundEnabled:
          notificationSoundEnabled ?? this.notificationSoundEnabled,
      notificationSoundType:
          notificationSoundType ?? this.notificationSoundType,
      notificationOffsetMinutes:
          notificationOffsetMinutes ?? this.notificationOffsetMinutes,
      notificationOffsets: notificationOffsets ?? this.notificationOffsets,
      themeMode: themeMode ?? this.themeMode,
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
      adjustFajr: adjustFajr ?? this.adjustFajr,
      adjustSunrise: adjustSunrise ?? this.adjustSunrise,
      adjustDhuhr: adjustDhuhr ?? this.adjustDhuhr,
      adjustAsr: adjustAsr ?? this.adjustAsr,
      adjustMaghrib: adjustMaghrib ?? this.adjustMaghrib,
      adjustIsha: adjustIsha ?? this.adjustIsha,
      iqamahFajr: iqamahFajr ?? this.iqamahFajr,
      iqamahDhuhr: iqamahDhuhr ?? this.iqamahDhuhr,
      iqamahAsr: iqamahAsr ?? this.iqamahAsr,
      iqamahMaghrib: iqamahMaghrib ?? this.iqamahMaghrib,
      iqamahIsha: iqamahIsha ?? this.iqamahIsha,
      isAzkarMorningReminderEnabled:
          isAzkarMorningReminderEnabled ?? this.isAzkarMorningReminderEnabled,
      isAzkarEveningReminderEnabled:
          isAzkarEveningReminderEnabled ?? this.isAzkarEveningReminderEnabled,
      isAzkarSleepReminderEnabled:
          isAzkarSleepReminderEnabled ?? this.isAzkarSleepReminderEnabled,
      isAzkarQiyamReminderEnabled:
          isAzkarQiyamReminderEnabled ?? this.isAzkarQiyamReminderEnabled,
      azkarQiyamMinutesBeforeFajr:
          azkarQiyamMinutesBeforeFajr ?? this.azkarQiyamMinutesBeforeFajr,
    );
  }

  @override
  List<Object?> get props => [
        calculationMethod,
        madhab,
        notificationsEnabled,
        notificationSoundEnabled,
        notificationSoundType,
        notificationOffsetMinutes,
        notificationOffsets,
        themeMode,
        is24HourFormat,
        adjustFajr,
        adjustSunrise,
        adjustDhuhr,
        adjustAsr,
        adjustMaghrib,
        adjustIsha,
        iqamahFajr,
        iqamahDhuhr,
        iqamahAsr,
        iqamahMaghrib,
        iqamahIsha,
        isAzkarMorningReminderEnabled,
        isAzkarEveningReminderEnabled,
        isAzkarSleepReminderEnabled,
        isAzkarQiyamReminderEnabled,
        azkarQiyamMinutesBeforeFajr,
      ];
}
