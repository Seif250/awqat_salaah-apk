import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/app_constants.dart';
import '../core/constants/prayer_constants.dart';
import '../features/prayer_times/data/models/prayer_day_model.dart';
import '../features/prayer_times/data/models/prayer_time_model.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> init() async {
    tz.initializeTimeZones();

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
      priority: Priority.high,
      playSound: isSoundEnabled,
      sound: isSoundEnabled
          ? const RawResourceAndroidNotificationSound(AppConstants.notificationSoundName)
          : null,
      enableVibration: isSoundEnabled,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      999,
      '🕌 الله أكبر الله أكبر — تجربة تنبيه الصلاة',
      'التنبيه يعمل بصوت التكبير وسينبهك عند الأذان ومع فترات الإقامة بإذن الله.',
      notificationDetails,
    );
  }

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

      // 1. Primary Adhan Notification
      final adhanNotificationTime = prayer.time.subtract(Duration(minutes: offsetMinutes));

      if (adhanNotificationTime.isAfter(now)) {
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

      // 2. Periodic Iqamah Interval Reminders (e.g. every 5 minutes during Iqamah window)
      if (prayer.type.isActualPrayer && prayer.iqamahOffsetMinutes > 5) {
        final totalIqamahMinutes = prayer.iqamahOffsetMinutes;
        
        // Reminder intervals every 5 minutes from Adhan until Iqamah
        for (int m = 5; m < totalIqamahMinutes; m += 5) {
          final reminderTime = prayer.time.add(Duration(minutes: m));
          final remainingToIqamah = totalIqamahMinutes - m;

          if (reminderTime.isAfter(now)) {
            final prayerName = isArabic ? prayer.type.nameArabic : prayer.type.nameEnglish;
            final reminderTitle = isArabic
                ? '⏳ تذكير إقامة صلاة $prayerName'
                : '⏳ $prayerName Iqamah Reminder';
            final reminderBody = isArabic
                ? 'متبقي $remainingToIqamah دقائق على إقامة صلاة $prayerName'
                : '$remainingToIqamah minutes remaining to $prayerName Iqamah.';

            await _scheduleSingleNotification(
              id: baseId * 100 + m,
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
      priority: Priority.high,
      playSound: isSoundEnabled,
      sound: isSoundEnabled
          ? const RawResourceAndroidNotificationSound(AppConstants.notificationSoundName)
          : null,
      enableVibration: isSoundEnabled,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
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
