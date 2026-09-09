import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
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

  bool _initialized = false;

  /// Diagnostic log for troubleshooting — last N entries
  final List<String> diagnosticLog = [];
  void _log(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    final entry = '[$ts] $msg';
    diagnosticLog.add(entry);
    if (diagnosticLog.length > 200) diagnosticLog.removeAt(0);
    debugPrint('🕌 NotifSvc: $msg');
  }

  Future<void> init() async {
    if (_initialized) return;

    try {
      // ── 1. Timezone ──
      tz.initializeTimeZones();
      await _setupTimezone();

      // ── 2. Initialize plugin ──
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          _log('Notification tapped: id=${details.id}');
        },
      );
      _log('Plugin initialized successfully');

      // ── 3. Create notification channels ──
      await _createNotificationChannel();

      // ── 4. Request notifications permission gracefully ──
      await _requestPermissions();

      _initialized = true;
      _log('NotificationService fully initialized ✅');
    } catch (e, stack) {
      _log('CRITICAL: init() failed: $e\n$stack');
    }
  }

  Future<void> _setupTimezone() async {
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final timeZoneName = timeZoneInfo.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      _log('Timezone initialized via FlutterTimezone: $timeZoneName');
      return;
    } catch (e) {
      _log('FlutterTimezone failed: $e, falling back to offset match');
    }

    try {
      // Fallback: match by offset
      final offset = DateTime.now().timeZoneOffset;
      final offsetMs = offset.inMilliseconds;

      const commonZones = [
        'Africa/Cairo',
        'Asia/Riyadh',
        'Asia/Dubai',
        'Europe/Istanbul',
        'Asia/Karachi',
        'Asia/Kolkata',
        'Asia/Kuala_Lumpur',
        'Europe/London',
        'America/New_York',
        'America/Chicago',
        'America/Los_Angeles',
      ];

      for (final zoneName in commonZones) {
        try {
          final loc = tz.getLocation(zoneName);
          if (loc.currentTimeZone.offset == offsetMs) {
            tz.setLocalLocation(loc);
            _log('Timezone fallback: $zoneName (offset ${offset.inHours}h)');
            return;
          }
        } catch (_) {}
      }

      final matching = tz.timeZoneDatabase.locations.values.firstWhere(
        (l) => l.currentTimeZone.offset == offsetMs,
        orElse: () => tz.getLocation('UTC'),
      );
      tz.setLocalLocation(matching);
      _log('Timezone database fallback: ${matching.name} (offset ${offset.inHours}h)');
    } catch (e) {
      _log('Timezone setup error: $e (using UTC)');
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl == null) {
        _log('WARNING: AndroidFlutterLocalNotificationsPlugin is null');
        return;
      }

      // Clean up previous channel versions to prevent cached stale channel configs
      try {
        await androidImpl.deleteNotificationChannel('prayer_times_takbeer_channel_v7');
        await androidImpl.deleteNotificationChannel('prayer_times_takbeer_channel_v6');
        await androidImpl.deleteNotificationChannel('prayer_times_takbeer_channel_v5');
      } catch (_) {}

      // Channel WITH custom Azan sound & alarm stream
      const channelWithSound = AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        description: AppConstants.notificationChannelDesc,
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(AppConstants.notificationSoundName),
        enableVibration: true,
        showBadge: true,
      );

      await androidImpl.createNotificationChannel(channelWithSound);
      _log('Channel created: ${AppConstants.notificationChannelId}');

      // Fallback channel with DEFAULT sound
      const fallbackChannel = AndroidNotificationChannel(
        'prayer_times_default_sound',
        'تنبيهات الصلاة (صوت افتراضي)',
        description: 'إشعارات أوقات الصلاة بالصوت الافتراضي للنظام',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImpl.createNotificationChannel(fallbackChannel);
      _log('Fallback channel created: prayer_times_default_sound');

      // Azkar channel with gentle notification sound
      const azkarChannel = AndroidNotificationChannel(
        AppConstants.azkarChannelId,
        AppConstants.azkarChannelName,
        description: AppConstants.azkarChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      await androidImpl.createNotificationChannel(azkarChannel);
      _log('Azkar channel created: ${AppConstants.azkarChannelId}');
    } catch (e) {
      _log('Channel creation error: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        try {
          await androidImpl.requestNotificationsPermission();
          _log('Notification permission requested');
        } catch (e) {
          _log('Notification permission error: $e');
        }
      }
    } catch (e) {
      _log('Permission request error: $e');
    }

    // NOTE: requestBatteryOptimizationExemption() intentionally removed from startup!
    // It is now strictly manual from the Settings page so it never annoys the user.
  }

  /// Request notification permission directly (usable from settings / home)
  Future<bool> requestNotificationsPermission() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final result = await androidImpl.requestNotificationsPermission();
        return result ?? false;
      }
      return true;
    } catch (e) {
      _log('requestNotificationsPermission error: $e');
      return false;
    }
  }

  /// Check if the system allows notifications for this app
  Future<bool> areNotificationsEnabled() async {
    try {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final result = await androidImpl.areNotificationsEnabled();
        return result ?? false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Check if exact alarms are permitted
  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Request the system to exempt this app from battery optimization (Manual only).
  Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      _log('Battery opt status: $status');
      if (!status.isGranted) {
        final result = await Permission.ignoreBatteryOptimizations.request();
        _log('Battery opt request result: $result');
        return result.isGranted;
      }
      return true;
    } catch (e) {
      _log('Battery opt error: $e');
      return false;
    }
  }

  Future<bool> isBatteryOptimizationExempted() async {
    if (!Platform.isAndroid) return true;
    try {
      return (await Permission.ignoreBatteryOptimizations.status).isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    _log('All notifications cancelled');
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
    } catch (e) {
      _log('cancelNotification $id error: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      _log('getPendingNotifications caught error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TEST METHODS — for verifying notifications work on the device
  // ═══════════════════════════════════════════════════════════════

  /// SIMPLEST possible test — default sound, minimal config
  Future<String> showSimpleTestNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'prayer_times_default_sound',
        'تنبيهات الصلاة (صوت افتراضي)',
        channelDescription: 'إشعارات أوقات الصلاة بالصوت الافتراضي للنظام',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        777,
        '✅ تجربة ناجحة — الإشعارات تعمل!',
        'هذا إشعار تجريبي بالصوت الافتراضي للنظام',
        details,
      );
      _log('Simple test notification shown (id=777) ✅');
      return 'success';
    } catch (e) {
      _log('Simple test FAILED: $e');
      return 'error: $e';
    }
  }

  /// Test with TAKBEER custom sound
  Future<String> showTakbeerTestNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(AppConstants.notificationSoundName),
        enableVibration: true,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
      );

      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        888,
        '🕌 الله أكبر الله أكبر — تجربة صوت التكبير',
        'التنبيه يعمل بصوت التكبير والحمد لله',
        details,
      );
      _log('Takbeer test notification shown (id=888) ✅');
      return 'success';
    } catch (e) {
      _log('Takbeer test FAILED: $e');
      return 'error: $e';
    }
  }

  /// Show an immediate test notification (legacy method)
  Future<void> showTestNotification({required bool isSoundEnabled}) async {
    await showTakbeerTestNotification();
  }

  /// Schedule a test alarm N seconds from now
  Future<String> scheduleTestAlarmInSeconds({
    required int seconds,
    required bool isSoundEnabled,
  }) async {
    try {
      final now = DateTime.now();
      final fireAt = now.add(Duration(seconds: seconds));
      final tzDate = _localDateTimeToTZ(fireAt);

      _log('Scheduling test: now=$now, fireAt=$fireAt, tz=${tz.local.name}, tzDate=$tzDate');

      const androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(AppConstants.notificationSoundName),
        enableVibration: true,
        autoCancel: true,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
      );

      const details = NotificationDetails(android: androidDetails);

      final result = await _scheduleWithFallback(
        id: 8888,
        title: '🕌 الله أكبر — تجربة الأذان المجدول',
        body: 'نجحت تجربة الأذان المجدول والحمد لله! ⏰',
        tzDate: tzDate,
        details: details,
      );

      // Verify
      try {
        final pending = await getPendingNotifications();
        final found = pending.any((p) => p.id == 8888);
        _log('Test alarm verify: registered=$found, totalPending=${pending.length}');
      } catch (e) {
        _log('Test alarm verify error: $e');
      }

      return result;
    } catch (e) {
      _log('Schedule test FAILED: $e');
      return 'error: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CORE SCHEDULING
  // ═══════════════════════════════════════════════════════════════

  tz.TZDateTime _localDateTimeToTZ(DateTime local) {
    return tz.TZDateTime.from(local, tz.local);
  }

  /// Schedule with cascading fallback: exactAllowWhileIdle → alarmClock → inexact
  Future<String> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime tzDate,
    required NotificationDetails details,
  }) async {
    // Try 1: exactAllowWhileIdle (primary mode for prayer times - wakes from Doze, exact second)
    try {
      await _notificationsPlugin.zonedSchedule(
        id, title, body, tzDate, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('✅ Scheduled id=$id via exactAllowWhileIdle at $tzDate');
      return 'exactAllowWhileIdle';
    } catch (e) {
      _log('⚠️ exactAllowWhileIdle failed id=$id: $e');
    }

    // Try 2: alarmClock (fallback)
    try {
      await _notificationsPlugin.zonedSchedule(
        id, title, body, tzDate, details,
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('✅ Scheduled id=$id via alarmClock at $tzDate');
      return 'alarmClock';
    } catch (e) {
      _log('⚠️ alarmClock failed id=$id: $e');
    }

    // Try 3: inexact (last resort)
    try {
      await _notificationsPlugin.zonedSchedule(
        id, title, body, tzDate, details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('✅ Scheduled id=$id via inexact at $tzDate');
      return 'inexact';
    } catch (e) {
      _log('❌ ALL modes failed id=$id: $e');
      return 'failed: $e';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WEEKLY PRAYER SCHEDULING
  // ═══════════════════════════════════════════════════════════════

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

    if (!isEnabled || notificationOffsets.isEmpty) {
      _log('Notifications disabled or no offsets — skipping');
      return;
    }

    _log('Weekly scheduling: offsets=$notificationOffsets, days=$daysToSchedule, tz=${tz.local.name}');

    final now = DateTime.now();
    int ok = 0, skip = 0, fail = 0;

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

        for (int k = 0; k < notificationOffsets.length; k++) {
          final offset = notificationOffsets[k];
          final notifId = 10000 + (dayOffset * 1000) + (prayerIndex * 100) + (k + 1);

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
                  ? ' • الإقامة بعد ${prayer.iqamahOffsetMinutes} دقيقة' : '';
              body = isArabic ? 'دخل الآن وقت صلاة $prayerName$iqamahInfo' : '$prayerName time has started.';
            } else {
              title = isArabic ? '⏳ اقتراب موعد صلاة $prayerName' : '⏳ $prayerName Prayer Upcoming';
              body = isArabic ? 'متبقي $minutesBefore دقائق على أذان صلاة $prayerName' : '$prayerName is in $minutesBefore minutes.';
            }
          } else {
            alertTime = prayer.time.add(Duration(minutes: offset));
            title = isArabic ? '⏳ تذكير بعد أذان $prayerName' : '⏳ $prayerName Post-Adhan Reminder';
            body = isArabic ? 'مضى $offset دقائق على أذان صلاة $prayerName' : '$offset minutes passed since $prayerName Adhan.';
          }

          if (alertTime.isAfter(now.add(const Duration(seconds: 5)))) {
            final result = await _scheduleSingleNotification(
              id: notifId, title: title, body: body,
              scheduledDate: alertTime, isSoundEnabled: isSoundEnabled,
            );
            if (result.startsWith('failed')) { fail++; } else { ok++; }
          } else {
            skip++;
          }
        }
      }
    }

    _log('Weekly done: $ok scheduled, $skip skipped, $fail failed');
    final pending = await getPendingNotifications();
    _log('System reports ${pending.length} pending notifications');
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

    final prayers = [
      MapEntry(101, prayerDay.fajr),
      MapEntry(102, prayerDay.dhuhr),
      MapEntry(103, prayerDay.asr),
      MapEntry(104, prayerDay.maghrib),
      MapEntry(105, prayerDay.isha),
    ];

    final now = DateTime.now();
    for (final entry in prayers) {
      final prayer = entry.value;
      final alertTime = prayer.time.subtract(Duration(minutes: offsetMinutes));
      if (alertTime.isAfter(now.add(const Duration(seconds: 5)))) {
        final prayerName = isArabic ? prayer.type.nameArabic : prayer.type.nameEnglish;
        String title, body;
        if (offsetMinutes == 0) {
          title = isArabic ? '🕌 الله أكبر — حان موعد صلاة $prayerName' : '🕌 $prayerName Prayer Time';
          final iqInfo = (prayer.iqamahTime != null && prayer.iqamahOffsetMinutes > 0) ? ' • الإقامة بعد ${prayer.iqamahOffsetMinutes} دقيقة' : '';
          body = isArabic ? 'دخل الآن وقت صلاة $prayerName$iqInfo' : '$prayerName time has started.';
        } else {
          title = isArabic ? '⏳ اقتراب موعد صلاة $prayerName' : '⏳ $prayerName Upcoming';
          body = isArabic ? 'متبقي $offsetMinutes دقائق على أذان صلاة $prayerName' : '$prayerName in $offsetMinutes min.';
        }
        await _scheduleSingleNotification(id: entry.key, title: title, body: body, scheduledDate: alertTime, isSoundEnabled: isSoundEnabled);
      }
    }
  }

  Future<String> _scheduleSingleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required bool isSoundEnabled,
  }) async {
    final tzDate = _localDateTimeToTZ(scheduledDate);

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

    final details = NotificationDetails(android: androidDetails);

    return await _scheduleWithFallback(
      id: id, title: title, body: body, tzDate: tzDate, details: details,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // AZKAR SCHEDULING (Morning, Evening, Sleep, Qiyam)
  // ═══════════════════════════════════════════════════════════

  static const int idMorningAzkar = 20001;
  static const int idMorningLateReminder = 20002;
  static const int idEveningAzkar = 20003;
  static const int idEveningLateReminder = 20004;
  static const int idSleepAzkar = 20005;
  static const int idQiyamReminder = 20006;

  Future<void> scheduleAzkarNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final now = DateTime.now();
    if (!scheduledDate.isAfter(now.add(const Duration(seconds: 5)))) {
      return;
    }

    final tzDate = _localDateTimeToTZ(scheduledDate);

    final androidDetails = const AndroidNotificationDetails(
      AppConstants.azkarChannelId,
      AppConstants.azkarChannelName,
      channelDescription: AppConstants.azkarChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    final details = NotificationDetails(android: androidDetails);

    await _scheduleWithFallback(
      id: id,
      title: title,
      body: body,
      tzDate: tzDate,
      details: details,
    );
  }

  Future<void> scheduleDailyAzkarReminders({
    required DateTime fajrTime,
    required DateTime dhuhrTime,
    required DateTime asrTime,
    required DateTime ishaTime,
    required bool morningEnabled,
    required bool eveningEnabled,
    required bool qiyamEnabled,
    required bool sleepEnabled,
    int qiyamMinutesBeforeFajr = 60,
    bool isMorningCompleted = false,
    bool isEveningCompleted = false,
  }) async {
    // 1. Morning Azkar (30 min after Fajr)
    if (morningEnabled && !isMorningCompleted) {
      final morningTime = fajrTime.add(const Duration(minutes: 30));
      await scheduleAzkarNotification(
        id: idMorningAzkar,
        title: '☀️ أذكار الصباح',
        body: 'ابدأ يومك بنور الأذكار.. حصّن نفسك في حفظ الله ورعايته.',
        scheduledDate: morningTime,
      );

      // Morning late reminder (45 min before Dhuhr)
      final lateMorningTime = dhuhrTime.subtract(const Duration(minutes: 45));
      await scheduleAzkarNotification(
        id: idMorningLateReminder,
        title: '⏳ تذكير بأذكار الصباح',
        body: 'متبقي القليل على صلاة الظهر.. لا يفوتك ورد الصباح وبركته.',
        scheduledDate: lateMorningTime,
      );
    } else {
      await cancelNotification(idMorningAzkar);
      await cancelNotification(idMorningLateReminder);
    }

    // 2. Evening Azkar (at Asr)
    if (eveningEnabled && !isEveningCompleted) {
      final eveningTime = asrTime;
      await scheduleAzkarNotification(
        id: idEveningAzkar,
        title: '🌙 أذكار المساء',
        body: 'حان وقت أذكار المساء.. حصنك وأمانك لليلتك.',
        scheduledDate: eveningTime,
      );

      // Evening late reminder (45 min before Isha)
      final lateEveningTime = ishaTime.subtract(const Duration(minutes: 45));
      await scheduleAzkarNotification(
        id: idEveningLateReminder,
        title: '⏳ تذكير بأذكار المساء',
        body: 'متبقي القليل على صلاة العشاء.. تذكير بقراءة ورد المساء.',
        scheduledDate: lateEveningTime,
      );
    } else {
      await cancelNotification(idEveningAzkar);
      await cancelNotification(idEveningLateReminder);
    }

    // 3. Sleep Azkar (at 10:30 PM)
    if (sleepEnabled) {
      final now = DateTime.now();
      var sleepTime = DateTime(now.year, now.month, now.day, 22, 30);
      if (sleepTime.isBefore(now)) {
        sleepTime = sleepTime.add(const Duration(days: 1));
      }
      await scheduleAzkarNotification(
        id: idSleepAzkar,
        title: '🛏️ أذكار النوم',
        body: 'آية الكرسي وخواتيم البقرة وأذكار النوم راحة وطمأنينة لقلبك.',
        scheduledDate: sleepTime,
      );
    } else {
      await cancelNotification(idSleepAzkar);
    }

    // 4. Qiyam Al-Layl Reminder
    if (qiyamEnabled) {
      final qiyamTime = fajrTime.subtract(Duration(minutes: qiyamMinutesBeforeFajr));
      await scheduleAzkarNotification(
        id: idQiyamReminder,
        title: '🌌 قيام الليل والأسحار',
        body: '«لا إله إلا الله وحده لا شريك له.. سبحان الله والحمد لله.. اللهم اغفر لي» ركعة بالليل ودعاء مستجاب.',
        scheduledDate: qiyamTime,
      );
    } else {
      await cancelNotification(idQiyamReminder);
    }
  }

  Future<void> cancelAzkarNotification(int id) async {
    await cancelNotification(id);
  }
}
