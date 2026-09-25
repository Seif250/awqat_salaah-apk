class AppConstants {
  static const String appName = 'وِرد';
  static const String appSubtitle = 'صلاتك، قرآنك، ذكرك';
  static const String appVersion = '2.0.0';

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
  static const String keyNotificationOffsetsList = 'notification_offsets_list';
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

  // Storage Key - Adhan Sound Selection
  static const String keyNotificationSoundType = 'notification_sound_type';

  // Adhan Sound Options
  static const String soundTypeFull = 'full';
  static const String soundTypeHayya = 'hayya';
  static const String soundTypeTakbeer = 'takbeer';

  // Dedicated Notification Channels for each sound
  static const String channelIdAzanFull = 'prayer_channel_azan_full_v1';
  static const String channelNameAzanFull = 'أذان الصلوات (الأذان كامل)';
  static const String soundResourceAzanFull = 'azan_full';

  static const String channelIdAzanHayya = 'prayer_channel_azan_hayya_v1';
  static const String channelNameAzanHayya = 'أذان الصلوات (حي على الصلاة)';
  static const String soundResourceAzanHayya = 'azan';

  static const String channelIdTakbeer = 'prayer_channel_takbeer_v1';
  static const String channelNameTakbeer = 'أذان الصلوات (الله أكبر الله أكبر)';
  static const String soundResourceTakbeer = 'takbeer';

  // Default Legacy Notification Channel (Backward Compatibility)
  static const String notificationChannelId = 'prayer_times_azan_channel_v9';
  static const String notificationChannelName = 'أذان الصلوات الخمس والتنبيهات';
  static const String notificationChannelDesc = 'إشعارات وتنبيهات أوقات الصلاة بصوت الأذان بأعلى أولوية';
  static const String notificationSoundName = 'azan';

  // Azkar Notification Channel & Keys
  static const String azkarChannelId = 'azkar_reminders_channel_v1';
  static const String azkarChannelName = 'تذكير الأذكار والورد اليومي';
  static const String azkarChannelDesc = 'تذكيرات لطيفة بأذكار الصباح والمساء وقيام الليل وأذكار النوم';

  static const String keyAzkarMorningReminderEnabled = 'azkar_morning_reminder_enabled';
  static const String keyAzkarEveningReminderEnabled = 'azkar_evening_reminder_enabled';
  static const String keyAzkarSleepReminderEnabled = 'azkar_sleep_reminder_enabled';
  static const String keyAzkarQiyamReminderEnabled = 'azkar_qiyam_reminder_enabled';
  static const String keyAzkarQiyamMinutesBeforeFajr = 'azkar_qiyam_minutes_before_fajr';
}
