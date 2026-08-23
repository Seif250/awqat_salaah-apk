class AppConstants {
  static const String appName = 'أوقات الصلاة';
  static const String appVersion = '1.0.0';

  // Storage Keys - Location
  static const String keyIsFirstLaunch = 'is_first_launch';
  static const String keyLatitude = 'latitude';
  static const String keyLongitude = 'longitude';
  static const String keyCityName = 'city_name';
  static const String keyCountryName = 'country_name';
  static const String keyIsAutoLocation = 'is_auto_location';

  // Storage Keys - Calculation & Preferences
  static const String keyCalculationMethod = 'calculation_method';
  static const String keyMadhab = 'madhab';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyNotificationSoundEnabled = 'notifications_sound_enabled';
  static const String keyNotificationOffset = 'notification_offset_minutes';
  static const String keyThemeMode = 'theme_mode';
  static const String keyIs24HourFormat = 'is_24_hour_format';

  // Storage Keys - Minute Adjustments
  static const String keyAdjustFajr = 'adjust_fajr';
  static const String keyAdjustSunrise = 'adjust_sunrise';
  static const String keyAdjustDhuhr = 'adjust_dhuhr';
  static const String keyAdjustAsr = 'adjust_asr';
  static const String keyAdjustMaghrib = 'adjust_maghrib';
  static const String keyAdjustIsha = 'adjust_isha';

  // Storage Keys - Iqamah Intervals (Minutes after Adhan)
  static const String keyIqamahFajr = 'iqamah_fajr';
  static const String keyIqamahDhuhr = 'iqamah_dhuhr';
  static const String keyIqamahAsr = 'iqamah_asr';
  static const String keyIqamahMaghrib = 'iqamah_maghrib';
  static const String keyIqamahIsha = 'iqamah_isha';

  // HomeWidget Constants
  static const String widgetGroupId = 'group.com.awqatsalaah.widget';
  static const String widgetName = 'PrayerWidgetProvider';
  static const String keyWidgetNextPrayerName = 'widget_next_prayer_name';
  static const String keyWidgetNextPrayerTime = 'widget_next_prayer_time';
  static const String keyWidgetNextPrayerTimestamp = 'widget_next_prayer_timestamp';
  static const String keyWidgetCityName = 'widget_city_name';
  static const String keyWidgetFajr = 'widget_fajr';
  static const String keyWidgetSunrise = 'widget_sunrise';
  static const String keyWidgetDhuhr = 'widget_dhuhr';
  static const String keyWidgetAsr = 'widget_asr';
  static const String keyWidgetMaghrib = 'widget_maghrib';
  static const String keyWidgetIsha = 'widget_isha';

  // Notification Channel with Takbeer sound
  static const String notificationChannelId = 'prayer_times_takbeer_channel_v4';
  static const String notificationChannelName = 'تنبيهات الأذان والإقامة (تكبير)';
  static const String notificationChannelDesc = 'إشعارات وتنبيهات أوقات الصلاة بصوت التكبير وتذكير الإقامة';
  static const String notificationSoundName = 'takbeer';
}
