import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/app_constants.dart';
import '../core/constants/prayer_constants.dart';
import '../features/prayer_times/data/models/prayer_day_model.dart';

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
        // App open on tap
      },
    );

    // Create Silent Notification Channel for Android 8.0+
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.defaultImportance,
      playSound: false, // NO SOUND
      enableVibration: false, // NO VIBRATION
      showBadge: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
      // Request Android 13+ POST_NOTIFICATIONS permission
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> schedulePrayerNotifications({
    required PrayerDayModel prayerDay,
    required bool isEnabled,
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
      final id = entry.key;
      final prayer = entry.value;

      // Exact notification time with offset
      final notificationTime = prayer.time.subtract(Duration(minutes: offsetMinutes));

      if (notificationTime.isAfter(now)) {
        final prayerName = isArabic ? prayer.type.nameArabic : prayer.type.nameEnglish;

        String title;
        String body;

        if (offsetMinutes == 0) {
          title = isArabic ? 'حان الآن موعد صلاة $prayerName' : '$prayerName Prayer Time';
          body = isArabic ? 'دخل الآن وقت صلاة $prayerName' : '$prayerName time has started.';
        } else {
          title = isArabic ? 'اقتراب موعد صلاة $prayerName' : '$prayerName Prayer Upcoming';
          body = isArabic
              ? 'متبقي $offsetMinutes دقائق على أذان صلاة $prayerName'
              : '$prayerName is in $offsetMinutes minutes.';
        }

        await _scheduleSingleNotification(
          id: id,
          title: title,
          body: body,
          scheduledDate: notificationTime,
        );
      }
    }
  }

  Future<void> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false, // NO SOUND
      enableVibration: false, // NO VIBRATION
      autoCancel: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

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
      // If exact alarm permission is not granted on newer Android, fallback to inexact
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
