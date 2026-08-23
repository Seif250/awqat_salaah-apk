import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get appTitle;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'Seconds'**
  String get seconds;

  /// No description provided for @fajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get fajr;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @dhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get dhuhr;

  /// No description provided for @asr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get asr;

  /// No description provided for @maghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get maghrib;

  /// No description provided for @isha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get isha;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @manualCity.
  ///
  /// In en, this message translates to:
  /// **'Manual City'**
  String get manualCity;

  /// No description provided for @calculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get calculationMethod;

  /// No description provided for @madhab.
  ///
  /// In en, this message translates to:
  /// **'Madhab'**
  String get madhab;

  /// No description provided for @shafi.
  ///
  /// In en, this message translates to:
  /// **'Shafi'**
  String get shafi;

  /// No description provided for @hanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get hanafi;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationBeforePrayer.
  ///
  /// In en, this message translates to:
  /// **'Notification Before Prayer'**
  String get notificationBeforePrayer;

  /// No description provided for @atPrayerTime.
  ///
  /// In en, this message translates to:
  /// **'At prayer time'**
  String get atPrayerTime;

  /// No description provided for @minutesBefore.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes before'**
  String minutesBefore(int count);

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @timeFormat24.
  ///
  /// In en, this message translates to:
  /// **'24-hour format'**
  String get timeFormat24;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Prayer Times'**
  String get onboardingWelcome;

  /// No description provided for @onboardingDescription.
  ///
  /// In en, this message translates to:
  /// **'Get accurate prayer times based on your location with astronomical calculations.'**
  String get onboardingDescription;

  /// No description provided for @onboardingLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Location'**
  String get onboardingLocationTitle;

  /// No description provided for @onboardingLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'We need your location to calculate accurate prayer times.'**
  String get onboardingLocationDesc;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @selectCityManually.
  ///
  /// In en, this message translates to:
  /// **'Select City Manually'**
  String get selectCityManually;

  /// No description provided for @searchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city...'**
  String get searchCity;

  /// No description provided for @selectCalculationMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Calculation Method'**
  String get selectCalculationMethod;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// No description provided for @prayerTimeNotification.
  ///
  /// In en, this message translates to:
  /// **'{prayer} Prayer'**
  String prayerTimeNotification(String prayer);

  /// No description provided for @prayerTimeStarted.
  ///
  /// In en, this message translates to:
  /// **'{prayer} time has started.'**
  String prayerTimeStarted(String prayer);

  /// No description provided for @prayerInMinutes.
  ///
  /// In en, this message translates to:
  /// **'{prayer} is in {count} minutes.'**
  String prayerInMinutes(String prayer, int count);

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Prayer times are calculated based on your geographical location. We need access to your location to provide accurate times.'**
  String get locationPermissionDesc;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications to receive silent reminders for prayer times.'**
  String get notificationPermissionDesc;

  /// No description provided for @egyptianAuthority.
  ///
  /// In en, this message translates to:
  /// **'Egyptian General Authority'**
  String get egyptianAuthority;

  /// No description provided for @muslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get muslimWorldLeague;

  /// No description provided for @isna.
  ///
  /// In en, this message translates to:
  /// **'ISNA'**
  String get isna;

  /// No description provided for @ummAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm Al-Qura'**
  String get ummAlQura;

  /// No description provided for @karachi.
  ///
  /// In en, this message translates to:
  /// **'University of Islamic Sciences, Karachi'**
  String get karachi;

  /// No description provided for @moonsightingCommittee.
  ///
  /// In en, this message translates to:
  /// **'Moonsighting Committee'**
  String get moonsightingCommittee;

  /// No description provided for @kuwait.
  ///
  /// In en, this message translates to:
  /// **'Kuwait'**
  String get kuwait;

  /// No description provided for @qatar.
  ///
  /// In en, this message translates to:
  /// **'Qatar'**
  String get qatar;

  /// No description provided for @singapore.
  ///
  /// In en, this message translates to:
  /// **'Singapore'**
  String get singapore;

  /// No description provided for @tehran.
  ///
  /// In en, this message translates to:
  /// **'Tehran'**
  String get tehran;

  /// No description provided for @turkey.
  ///
  /// In en, this message translates to:
  /// **'Turkey'**
  String get turkey;

  /// No description provided for @dubai.
  ///
  /// In en, this message translates to:
  /// **'Dubai'**
  String get dubai;

  /// No description provided for @northAmerica.
  ///
  /// In en, this message translates to:
  /// **'North America (ISNA)'**
  String get northAmerica;

  /// No description provided for @prayerTimeAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Prayer Time Adjustments'**
  String get prayerTimeAdjustments;

  /// No description provided for @adjustmentMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String adjustmentMinutes(int count);

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
