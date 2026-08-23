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
        // App opened on tap
      },
    );

    // Create High Importance Notification Channel for Android 8.0+
    const androidChannel = AndroidNotificationChannel(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      description: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    final androidImplementation = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
      // Request Android 13+ POST_NOTIFICATIONS permission
      await androidImplementation.requestNotificationsPermission();
      // Request exact alarm permission if available
      try {
        await androidImplementation.requestExactAlarmsPermission();
      } catch (_) {}
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Show an immediate test notification to verify delivery
  Future<void> showTestNotification({required bool isSoundEnabled}) async {
    final androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: isSoundEnabled,
      enableVibration: isSoundEnabled,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      999,
      '🕌 تجربة إشعارات أوقات الصلاة',
      'الإشعارات تعمل بنجاح وستصلك عند مواعيد الصلاة والإقامة بإذن الله.',
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
      final id = entry.key;
      final prayer = entry.value;

      // Exact notification time with offset
      final notificationTime = prayer.time.subtract(Duration(minutes: offsetMinutes));

      if (notificationTime.isAfter(now)) {
        final prayerName = isArabic ? prayer.type.nameArabic : prayer.type.nameEnglish;

        String title;
        String body;

        if (offsetMinutes == 0) {
          title = isArabic ? '🕌 حان الآن موعد صلاة $prayerName' : '🕌 $prayerName Prayer Time';
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
          id: id,
          title: title,
          body: body,
          scheduledDate: notificationTime,
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
      priority: Priority.high,
      playSound: isSoundEnabled,
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
