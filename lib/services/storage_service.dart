import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/prayer_constants.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // First Launch
  bool get isFirstLaunch => _prefs.getBool(AppConstants.keyIsFirstLaunch) ?? true;
  Future<void> setFirstLaunchCompleted() =>
      _prefs.setBool(AppConstants.keyIsFirstLaunch, false);

  // Location Data (Default to Cairo, Egypt)
  double get latitude => _prefs.getDouble(AppConstants.keyLatitude) ?? 30.0444;
  double get longitude => _prefs.getDouble(AppConstants.keyLongitude) ?? 31.2357;
  String get cityName => _prefs.getString(AppConstants.keyCityName) ?? 'القاهرة';
  String get countryName => _prefs.getString(AppConstants.keyCountryName) ?? 'مصر';
  bool get isAutoLocation => _prefs.getBool(AppConstants.keyIsAutoLocation) ?? true;

  Future<void> setLocation({
    required double latitude,
    required double longitude,
    required String cityName,
    required String countryName,
    required bool isAuto,
  }) async {
    await _prefs.setDouble(AppConstants.keyLatitude, latitude);
    await _prefs.setDouble(AppConstants.keyLongitude, longitude);
    await _prefs.setString(AppConstants.keyCityName, cityName);
    await _prefs.setString(AppConstants.keyCountryName, countryName);
    await _prefs.setBool(AppConstants.keyIsAutoLocation, isAuto);
  }

  // Calculation Method
  AppCalculationMethod get calculationMethod {
    final index = _prefs.getInt(AppConstants.keyCalculationMethod);
    if (index != null && index >= 0 && index < AppCalculationMethod.values.length) {
      return AppCalculationMethod.values[index];
    }
    return AppCalculationMethod.egyptian; // Default for Egyptian users
  }

  Future<void> setCalculationMethod(AppCalculationMethod method) =>
      _prefs.setInt(AppConstants.keyCalculationMethod, method.index);

  // Madhab
  AppMadhab get madhab {
    final index = _prefs.getInt(AppConstants.keyMadhab);
    if (index != null && index >= 0 && index < AppMadhab.values.length) {
      return AppMadhab.values[index];
    }
    return AppMadhab.shafi; // Default Shafi
  }

  Future<void> setMadhab(AppMadhab madhab) =>
      _prefs.setInt(AppConstants.keyMadhab, madhab.index);

  // Notifications
  bool get notificationsEnabled =>
      _prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) =>
      _prefs.setBool(AppConstants.keyNotificationsEnabled, enabled);

  int get notificationOffsetMinutes =>
      _prefs.getInt(AppConstants.keyNotificationOffset) ?? 0; // 0 = at prayer time

  Future<void> setNotificationOffsetMinutes(int minutes) =>
      _prefs.setInt(AppConstants.keyNotificationOffset, minutes);

  // Theme Mode
  ThemeMode get themeMode {
    final modeStr = _prefs.getString(AppConstants.keyThemeMode);
    if (modeStr == 'light') return ThemeMode.light;
    if (modeStr == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    return _prefs.setString(AppConstants.keyThemeMode, val);
  }

  // Time format
  bool get is24HourFormat =>
      _prefs.getBool(AppConstants.keyIs24HourFormat) ?? false;

  Future<void> setIs24HourFormat(bool is24) =>
      _prefs.setBool(AppConstants.keyIs24HourFormat, is24);

  // Prayer Adjustments
  int get adjustFajr => _prefs.getInt(AppConstants.keyAdjustFajr) ?? 0;
  int get adjustSunrise => _prefs.getInt(AppConstants.keyAdjustSunrise) ?? 0;
  int get adjustDhuhr => _prefs.getInt(AppConstants.keyAdjustDhuhr) ?? 0;
  int get adjustAsr => _prefs.getInt(AppConstants.keyAdjustAsr) ?? 0;
  int get adjustMaghrib => _prefs.getInt(AppConstants.keyAdjustMaghrib) ?? 0;
  int get adjustIsha => _prefs.getInt(AppConstants.keyAdjustIsha) ?? 0;

  Future<void> setAdjustments({
    int? fajr,
    int? sunrise,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) async {
    if (fajr != null) await _prefs.setInt(AppConstants.keyAdjustFajr, fajr);
    if (sunrise != null) await _prefs.setInt(AppConstants.keyAdjustSunrise, sunrise);
    if (dhuhr != null) await _prefs.setInt(AppConstants.keyAdjustDhuhr, dhuhr);
    if (asr != null) await _prefs.setInt(AppConstants.keyAdjustAsr, asr);
    if (maghrib != null) await _prefs.setInt(AppConstants.keyAdjustMaghrib, maghrib);
    if (isha != null) await _prefs.setInt(AppConstants.keyAdjustIsha, isha);
  }

  // Iqamah Intervals (Defaults: Fajr 20m, Dhuhr 15m, Asr 15m, Maghrib 10m, Isha 15m)
  int get iqamahFajr => _prefs.getInt(AppConstants.keyIqamahFajr) ?? 20;
  int get iqamahDhuhr => _prefs.getInt(AppConstants.keyIqamahDhuhr) ?? 15;
  int get iqamahAsr => _prefs.getInt(AppConstants.keyIqamahAsr) ?? 15;
  int get iqamahMaghrib => _prefs.getInt(AppConstants.keyIqamahMaghrib) ?? 10;
  int get iqamahIsha => _prefs.getInt(AppConstants.keyIqamahIsha) ?? 15;

  Future<void> setIqamahOffsets({
    int? fajr,
    int? dhuhr,
    int? asr,
    int? maghrib,
    int? isha,
  }) async {
    if (fajr != null) await _prefs.setInt(AppConstants.keyIqamahFajr, fajr);
    if (dhuhr != null) await _prefs.setInt(AppConstants.keyIqamahDhuhr, dhuhr);
    if (asr != null) await _prefs.setInt(AppConstants.keyIqamahAsr, asr);
    if (maghrib != null) await _prefs.setInt(AppConstants.keyIqamahMaghrib, maghrib);
    if (isha != null) await _prefs.setInt(AppConstants.keyIqamahIsha, isha);
  }
}
