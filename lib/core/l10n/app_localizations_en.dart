// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Prayer Times';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get remaining => 'Remaining';

  @override
  String get hours => 'Hours';

  @override
  String get minutes => 'Minutes';

  @override
  String get seconds => 'Seconds';

  @override
  String get fajr => 'Fajr';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get dhuhr => 'Dhuhr';

  @override
  String get asr => 'Asr';

  @override
  String get maghrib => 'Maghrib';

  @override
  String get isha => 'Isha';

  @override
  String get settings => 'Settings';

  @override
  String get location => 'Location';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get manualCity => 'Manual City';

  @override
  String get calculationMethod => 'Calculation Method';

  @override
  String get madhab => 'Madhab';

  @override
  String get shafi => 'Shafi';

  @override
  String get hanafi => 'Hanafi';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationBeforePrayer => 'Notification Before Prayer';

  @override
  String get atPrayerTime => 'At prayer time';

  @override
  String minutesBefore(int count) {
    return '$count minutes before';
  }

  @override
  String get theme => 'Theme';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get timeFormat24 => '24-hour format';

  @override
  String get onboardingWelcome => 'Welcome to Prayer Times';

  @override
  String get onboardingDescription =>
      'Get accurate prayer times based on your location with astronomical calculations.';

  @override
  String get onboardingLocationTitle => 'Choose Your Location';

  @override
  String get onboardingLocationDesc =>
      'We need your location to calculate accurate prayer times.';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get selectCityManually => 'Select City Manually';

  @override
  String get searchCity => 'Search city...';

  @override
  String get selectCalculationMethod => 'Select Calculation Method';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String todayAt(String time) {
    return 'Today at $time';
  }

  @override
  String prayerTimeNotification(String prayer) {
    return '$prayer Prayer';
  }

  @override
  String prayerTimeStarted(String prayer) {
    return '$prayer time has started.';
  }

  @override
  String prayerInMinutes(String prayer, int count) {
    return '$prayer is in $count minutes.';
  }

  @override
  String get locationPermissionTitle => 'Location Permission';

  @override
  String get locationPermissionDesc =>
      'Prayer times are calculated based on your geographical location. We need access to your location to provide accurate times.';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get notificationPermissionTitle => 'Notification Permission';

  @override
  String get notificationPermissionDesc =>
      'Allow notifications to receive silent reminders for prayer times.';

  @override
  String get egyptianAuthority => 'Egyptian General Authority';

  @override
  String get muslimWorldLeague => 'Muslim World League';

  @override
  String get isna => 'ISNA';

  @override
  String get ummAlQura => 'Umm Al-Qura';

  @override
  String get karachi => 'University of Islamic Sciences, Karachi';

  @override
  String get moonsightingCommittee => 'Moonsighting Committee';

  @override
  String get kuwait => 'Kuwait';

  @override
  String get qatar => 'Qatar';

  @override
  String get singapore => 'Singapore';

  @override
  String get tehran => 'Tehran';

  @override
  String get turkey => 'Turkey';

  @override
  String get dubai => 'Dubai';

  @override
  String get northAmerica => 'North America (ISNA)';

  @override
  String get prayerTimeAdjustments => 'Prayer Time Adjustments';

  @override
  String adjustmentMinutes(int count) {
    return '$count min';
  }

  @override
  String get disable => 'Disable';

  @override
  String get enable => 'Enable';

  @override
  String get about => 'About';

  @override
  String version(String version) {
    return 'Version $version';
  }
}
