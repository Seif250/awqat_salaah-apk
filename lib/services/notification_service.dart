import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/app_constants.dart';
import '../core/constants/prayer_constants.dart';
import '../features/prayer_times/data/models/prayer_day_model.dart';
import 'prayer_calculation_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      final locationName = timezoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // If local timezone detection fails, timezone stays as initialized
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // App opened on tap
      },
    );

    // Create High Importance Notification Channel with Takbeer Sound
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(AppConstants.notificationSoundName),
      enableVibration: true,
      showBadge: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
      await androidImplementation.requestNotificationsPermission();
      try {
        await androidImplementation.requestExactAlarmsPermission();
      } catch (_) {}
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Show an immediate test notification to verify delivery & Takbeer sound
  Future<void> showTestNotification({required bool isSoundEnabled}) async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: isSoundEnabled,
      sound: isSoundEnabled
          ? const RawResourceAndroidNotificationSound(AppConstants.notificationSoundName)
          : null,
      enableVibration: isSoundEnabled,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      999,
      '🕌 الله أكبر الله أكبر — تجربة تنبيه الصلاة',
      'التنبيه يعمل بصوت التكبير وسينبهك عند الأذان ومع فترات الإقامة بإذن الله.',
      notificationDetails,
    );
  }

  /// Schedule prayer notifications 7 days in advance for all chosen alert timings
  Future<void> scheduleWeeklyPrayerNotifications({
    required PrayerCalculationService calculationService,
    required double latitude,
    required double longitude,
    required AppCalculationMethod method,
    required AppMadhab madhab,
    required int adjustFajr,
    required int adjustSunrise,
    required int adjustDhuhr,
    required int adjustAsr,
    required int adjustMaghrib,
    required int adjustIsha,
    required int iqamahFajr,
    required int iqamahDhuhr,
    required int iqamahAsr,
    required int iqamahMaghrib,
    required int iqamahIsha,
    required bool isEnabled,
    required bool isSoundEnabled,
    required List<int> notificationOffsets,
    required bool isArabic,
    required bool is24Hour,
    int daysToSchedule = 7,
  }) async {
    await cancelAllNotifications();

    if (!isEnabled || notificationOffsets.isEmpty) return;

    final now = DateTime.now();

    for (int dayOffset = 0; dayOffset < daysToSchedule; dayOffset++) {
      final targetDate = now.add(Duration(days: dayOffset));
      final prayerDay = calculationService.calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: targetDate,
        method: method,
        madhab: madhab,
        adjustFajr: adjustFajr,
        adjustSunrise: adjustSunrise,
        adjustDhuhr: adjustDhuhr,
        adjustAsr: adjustAsr,
        adjustMaghrib: adjustMaghrib,
        adjustIsha: adjustIsha,
        iqamahFajr: iqamahFajr,
        iqamahDhuhr: iqamahDhuhr,
        iqamahAsr: iqamahAsr,
        iqamahMaghrib: iqamahMaghrib,
        iqamahIsha: iqamahIsha,
      );

      final prayers = [
        MapEntry(1, prayerDay.fajr),
        MapEntry(2, prayerDay.dhuhr),
        MapEntry(3, prayerDay.asr),
        MapEntry(4, prayerDay.maghrib),
        MapEntry(5, prayerDay.isha),
      ];

      for (final entry in prayers) {
        final prayerIndex = entry.key;
        final prayer = entry.value;

        // Schedule every selected offset timing for this prayer
        for (int k = 0; k < notificationOffsets.length; k++) {
          final offset = notificationOffsets[k];
          final notificationId = 10000 + (dayOffset * 1000) + (prayerIndex * 100) + (k + 1);

          DateTime alertTime;
          String title;
          String body;
          final prayerName = isArabic ? prayer.type.nameArabic : prayer.type.nameEnglish;

          if (offset <= 0) {
            final minutesBefore = -offset;
            alertTime = prayer.time.subtract(Duration(minutes: minutesBefore));

            if (offset == 0) {
              title = isArabic ? '🕌 الله أكبر — حان موعد صلاة $prayerName' : '🕌 $prayerName Prayer Time';
              final iqamahInfo = (prayer.iqamahTime != null && prayer.iqamahOffsetMinutes > 0)
                  ? ' • الإقامة بعد ${prayer.iqamahOffsetMinutes} دقيقة'
                  : '';
              body = isArabic
                  ? 'دخل الآن وقت صلاة $prayerName$iqamahInfo'
                  : '$prayerName time has started.';
            } else {
              title = isArabic ? '⏳ اقتراب موعد صلاة $prayerName' : '⏳ $prayerName Prayer Upcoming';
              body = isArabic
                  ? 'متبقي $minutesBefore دقائق على أذان صلاة $prayerName'
                  : '$prayerName is in $minutesBefore minutes.';
            }
          } else {
            // Offset after Adhan
            alertTime = prayer.time.add(Duration(minutes: offset));
            title = isArabic ? '⏳ تذكير بعد أذان $prayerName' : '⏳ $prayerName Post-Adhan Reminder';
            body = isArabic
                ? 'مضى $offset دقائق على أذان صلاة $prayerName'
                : '$offset minutes passed since $prayerName Adhan.';
          }

          if (alertTime.isAfter(now.add(const Duration(seconds: 2)))) {
            await _scheduleSingleNotification(
              id: notificationId,
              title: title,
              body: body,
              scheduledDate: alertTime,
              isSoundEnabled: isSoundEnabled,
            );
          }
        }

        // Periodic Iqamah window reminders if enabled
        if (prayer.type.isActualPrayer && prayer.iqamahOffsetMinutes > 5) {
          final totalIqamahMinutes = prayer.iqamahOffsetMinutes;
          for (int m = 5; m < totalIqamahMinutes; m += 5) {
            // If already explicitly scheduled as a user offset, skip duplicate
            if (notificationOffsets.contains(m)) continue;

            final reminderTime = prayer.time.add(Duration(minutes: m));
            final remainingToIqamah = totalIqamahMinutes - m;

            if (reminderTime.isAfter(now.add(const Duration(seconds: 2)))) {
              final prayerName = isArabic ? prayer.type.nameArabic : prayer.type.nameEnglish;
              final reminderTitle = isArabic
                  ? '⏳ تذكير إقامة صلاة $prayerName'
                  : '⏳ $prayerName Iqamah Reminder';
              final reminderBody = isArabic
                  ? 'متبقي $remainingToIqamah دقائق على إقامة صلاة $prayerName'
                  : '$remainingToIqamah minutes remaining to $prayerName Iqamah.';

              await _scheduleSingleNotification(
                id: 50000 + (dayOffset * 1000) + (prayerIndex * 100) + (m ~/ 5),
                title: reminderTitle,
                body: reminderBody,
                scheduledDate: reminderTime,
                isSoundEnabled: isSoundEnabled,
              );
            }
          }
        }
      }
    }
  }

  /// Single day schedule helper for backward compatibility
  Future<void> schedulePrayerNotifications({
    required PrayerDayModel prayerDay,
    required bool isEnabled,
    required bool isSoundEnabled,
    required int offsetMinutes,
    required bool isArabic,
    required bool is24Hour,
  }) async {
    await cancelAllNotifications();

    if (!isEnabled) return;

    final prayersToSchedule = [
      MapEntry(101, prayerDay.fajr),
      MapEntry(102, prayerDay.dhuhr),
      MapEntry(103, prayerDay.asr),
      MapEntry(104, prayerDay.maghrib),
      MapEntry(105, prayerDay.isha),
    ];

    final now = DateTime.now();

    for (final entry in prayersToSchedule) {
      final baseId = entry.key;
      final prayer = entry.value;

      final adhanNotificationTime = prayer.time.subtract(Duration(minutes: offsetMinutes));

      if (adhanNotificationTime.isAfter(now.add(const Duration(seconds: 2)))) {
        final prayerName = isArabic ? prayer.type.nameArabic : prayer.type.nameEnglish;

        String title;
        String body;

        if (offsetMinutes == 0) {
          title = isArabic ? '🕌 الله أكبر — حان موعد صلاة $prayerName' : '🕌 $prayerName Prayer Time';
          final iqamahInfo = (prayer.iqamahTime != null && prayer.iqamahOffsetMinutes > 0)
              ? ' • الإقامة بعد ${prayer.iqamahOffsetMinutes} دقيقة'
              : '';
          body = isArabic
              ? 'دخل الآن وقت صلاة $prayerName$iqamahInfo'
              : '$prayerName time has started.';
        } else {
          title = isArabic ? '⏳ اقتراب موعد صلاة $prayerName' : '⏳ $prayerName Prayer Upcoming';
          body = isArabic
              ? 'متبقي $offsetMinutes دقائق على أذان صلاة $prayerName'
              : '$prayerName is in $offsetMinutes minutes.';
        }

        await _scheduleSingleNotification(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: adhanNotificationTime,
          isSoundEnabled: isSoundEnabled,
        );
      }
    }
  }

  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required bool isSoundEnabled,
  }) async {
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      playSound: isSoundEnabled,
      sound: isSoundEnabled
          ? const RawResourceAndroidNotificationSound(AppConstants.notificationSoundName)
          : null,
      enableVibration: isSoundEnabled,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }
}
