import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/prayer_constants.dart';

class SettingsState extends Equatable {
  final AppCalculationMethod calculationMethod;
  final AppMadhab madhab;
  final bool notificationsEnabled;
  final int notificationOffsetMinutes;
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

  const SettingsState({
    this.calculationMethod = AppCalculationMethod.egyptian,
    this.madhab = AppMadhab.shafi,
    this.notificationsEnabled = true,
    this.notificationOffsetMinutes = 0,
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
  });

  SettingsState copyWith({
    AppCalculationMethod? calculationMethod,
    AppMadhab? madhab,
    bool? notificationsEnabled,
    int? notificationOffsetMinutes,
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
  }) {
    return SettingsState(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      madhab: madhab ?? this.madhab,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationOffsetMinutes:
          notificationOffsetMinutes ?? this.notificationOffsetMinutes,
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
    );
  }

  @override
  List<Object?> get props => [
        calculationMethod,
        madhab,
        notificationsEnabled,
        notificationOffsetMinutes,
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
      ];
}
