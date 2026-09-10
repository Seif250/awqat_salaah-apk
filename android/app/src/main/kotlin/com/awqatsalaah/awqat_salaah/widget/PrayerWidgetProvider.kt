package com.awqatsalaah.awqat_salaah.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import com.awqatsalaah.awqat_salaah.MainActivity
import com.awqatsalaah.awqat_salaah.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        WidgetDiagnostics.log(context, "onUpdate: ${appWidgetIds.size} widget(s)")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetDiagnostics.log(context, "onEnabled: First widget added to home screen")
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetDiagnostics.log(context, "onDisabled: Last widget removed, cancelling alarm")
        cancelAlarm(context)
    }

    companion object {
        private const val ALARM_REQUEST_CODE = 9001

        /**
         * Ordered list of prayer keys for auto-selection.
         * Sunrise is included for "next prayer" flow but is not an iqamah prayer.
         */
        private val PRAYER_ORDER = listOf("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
        private val IQAMAH_PRAYERS = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")

        /**
         * Core update logic — called from onUpdate, AlarmReceiver, BootReceiver, and Flutter MethodChannel.
         */
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val prefs = context.getSharedPreferences("PrayerWidgetPrefs", Context.MODE_PRIVATE)
                val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)
                val now = System.currentTimeMillis()

                // Record update timestamp
                prefs.edit().putLong("widget_last_update_ts", now).apply()

                // ── Read timestamps from SharedPreferences ──
                val timestamps = mutableMapOf<String, Long>()
                for (prayer in PRAYER_ORDER) {
                    timestamps[prayer] = prefs.getLong("widget_ts_$prayer", 0)
                }
                val iqamahTimestamps = mutableMapOf<String, Long>()
                for (prayer in IQAMAH_PRAYERS) {
                    iqamahTimestamps[prayer] = prefs.getLong("widget_ts_iqamah_$prayer", 0)
                }
                val tomorrowFajr = prefs.getLong("widget_ts_tomorrow_fajr", 0)

                val is24Hour = prefs.getBoolean("widget_is_24hour", false)

                // ── Determine current focus prayer and target time ──
                var focusPrayer: String? = null
                var targetTimestamp: Long = 0
                var phase = "beforeAdhan" // or "duringIqamah"

                // Walk through each prayer in order:
                // Check: are we before this prayer's adhan? → focus on it
                // Check: are we between adhan and iqamah? → focus on iqamah
                for (prayer in PRAYER_ORDER) {
                    val adhanTs = timestamps[prayer] ?: 0
                    if (adhanTs <= 0) continue

                    if (now < adhanTs) {
                        // Before this prayer's adhan
                        focusPrayer = prayer
                        targetTimestamp = adhanTs
                        phase = "beforeAdhan"
                        break
                    }

                    // Check iqamah window (skip sunrise — no iqamah)
                    if (prayer != "sunrise") {
                        val iqamahTs = iqamahTimestamps[prayer] ?: 0
                        if (iqamahTs > 0 && now < iqamahTs) {
                            focusPrayer = prayer
                            targetTimestamp = iqamahTs
                            phase = "duringIqamah"
                            break
                        }
                    }
                }

                // If all today's prayers passed, target tomorrow's fajr
                if (focusPrayer == null) {
                    focusPrayer = "fajr"
                    targetTimestamp = if (tomorrowFajr > 0) tomorrowFajr else 0
                    phase = "beforeAdhan"
                    WidgetDiagnostics.log(context, "All prayers passed, targeting tomorrow fajr: ${WidgetDiagnostics.formatTs(tomorrowFajr)}")
                }

                // Save current focus for diagnostics
                val prayerDisplayName = prefs.getString("widget_name_$focusPrayer", focusPrayer) ?: focusPrayer
                prefs.edit().putString("widget_current_focus_prayer", "$prayerDisplayName ($phase)").apply()

                WidgetDiagnostics.log(context, "Focus: $focusPrayer ($phase), target: ${WidgetDiagnostics.formatTs(targetTimestamp)}")

                // ── Read display strings ──
                val cityName = prefs.getString("widget_city_name", "القاهرة") ?: "القاهرة"

                // Build next prayer display name
                val nextPrayerName = if (phase == "duringIqamah") {
                    "$prayerDisplayName (أُذِّن الآن)"
                } else {
                    prayerDisplayName
                }

                // Format time for display
                val nextPrayerTimeFormatted = if (targetTimestamp > 0) {
                    formatTime(targetTimestamp, is24Hour)
                } else {
                    prefs.getString("widget_next_prayer_time", "--:--") ?: "--:--"
                }

                // Build subtitle
                val countdownText = if (phase == "duringIqamah") {
                    "متبقي للإقامة"
                } else {
                    // Show iqamah info if available
                    val iqTs = iqamahTimestamps[focusPrayer] ?: 0
                    if (iqTs > 0 && focusPrayer != "sunrise") {
                        val adhanTs = timestamps[focusPrayer] ?: 0
                        val offsetMin = if (adhanTs > 0) ((iqTs - adhanTs) / 60000).toInt() else 0
                        if (offsetMin > 0) {
                            "الإقامة: ${formatTime(iqTs, is24Hour)} (+${offsetMin}د)"
                        } else {
                            "أوقات الصلاة اليومية"
                        }
                    } else {
                        "أوقات الصلاة اليومية"
                    }
                }

                // ── Bind views ──
                views.setTextViewText(R.id.widget_city_name, cityName)
                views.setTextViewText(R.id.widget_next_prayer_name, nextPrayerName)
                views.setTextViewText(R.id.widget_next_prayer_time, nextPrayerTimeFormatted)
                views.setTextViewText(R.id.widget_countdown_text, countdownText)

                // ── Live Chronometer countdown ──
                if (targetTimestamp > 0 && targetTimestamp > now) {
                    val elapsedDiff = targetTimestamp - now
                    val chronometerBase = SystemClock.elapsedRealtime() + elapsedDiff
                    views.setChronometer(R.id.widget_chronometer, chronometerBase, null, true)

                    // CountDown mode (API 24+)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.widget_chronometer, true)
                    }

                    views.setViewVisibility(R.id.widget_chronometer, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_chronometer, android.view.View.GONE)
                }

                // ── Prayer times grid ──
                val fajrStr = prefs.getString("widget_fajr", "--:--") ?: "--:--"
                val dhuhrStr = prefs.getString("widget_dhuhr", "--:--") ?: "--:--"
                val asrStr = prefs.getString("widget_asr", "--:--") ?: "--:--"
                val maghribStr = prefs.getString("widget_maghrib", "--:--") ?: "--:--"
                val ishaStr = prefs.getString("widget_isha", "--:--") ?: "--:--"

                views.setTextViewText(R.id.widget_time_fajr, fajrStr)
                views.setTextViewText(R.id.widget_time_dhuhr, dhuhrStr)
                views.setTextViewText(R.id.widget_time_asr, asrStr)
                views.setTextViewText(R.id.widget_time_maghrib, maghribStr)
                views.setTextViewText(R.id.widget_time_isha, ishaStr)

                // ── Tap to open app ──
                val intent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(context, 0, intent, flags)
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                // ── Push update ──
                appWidgetManager.updateAppWidget(appWidgetId, views)

                // ── Schedule next alarm ──
                scheduleNextAlarm(context, now, timestamps, iqamahTimestamps, tomorrowFajr)

            } catch (e: Throwable) {
                WidgetDiagnostics.log(context, "updateAppWidget ERROR: ${e.message}\n${e.stackTraceToString().take(500)}")
                e.printStackTrace()
            }
        }

        /**
         * Schedule an exact alarm for the next prayer transition point.
         * We schedule at each adhan and each iqamah end to auto-advance the widget.
         */
        private fun scheduleNextAlarm(
            context: Context,
            now: Long,
            timestamps: Map<String, Long>,
            iqamahTimestamps: Map<String, Long>,
            tomorrowFajr: Long
        ) {
            try {
                // Collect all future transition points
                val futurePoints = mutableListOf<Long>()
                for (prayer in PRAYER_ORDER) {
                    val adhanTs = timestamps[prayer] ?: 0
                    if (adhanTs > now) futurePoints.add(adhanTs)

                    if (prayer != "sunrise") {
                        val iqamahTs = iqamahTimestamps[prayer] ?: 0
                        if (iqamahTs > now) futurePoints.add(iqamahTs)
                    }
                }
                if (tomorrowFajr > now) futurePoints.add(tomorrowFajr)

                if (futurePoints.isEmpty()) {
                    WidgetDiagnostics.log(context, "scheduleNextAlarm: No future transition points, skipping")
                    return
                }

                val nextAlarmTs = futurePoints.min()
                // Add 2 seconds buffer so we fire slightly after the transition
                val alarmTs = nextAlarmTs + 2000

                val prefs = context.getSharedPreferences("PrayerWidgetPrefs", Context.MODE_PRIVATE)
                prefs.edit().putLong("widget_scheduled_alarm_ts", nextAlarmTs).apply()

                val alarmIntent = Intent(context, WidgetAlarmReceiver::class.java).apply {
                    action = "com.awqatsalaah.WIDGET_PRAYER_ALARM"
                }
                val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingAlarmIntent = PendingIntent.getBroadcast(
                    context, ALARM_REQUEST_CODE, alarmIntent, pendingFlags
                )

                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP, alarmTs, pendingAlarmIntent
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP, alarmTs, pendingAlarmIntent
                    )
                }

                WidgetDiagnostics.log(context, "Alarm scheduled at ${WidgetDiagnostics.formatTs(nextAlarmTs)}")
            } catch (e: Throwable) {
                WidgetDiagnostics.log(context, "scheduleNextAlarm ERROR: ${e.message}")
            }
        }

        /**
         * Cancel any pending alarm.
         */
        fun cancelAlarm(context: Context) {
            try {
                val alarmIntent = Intent(context, WidgetAlarmReceiver::class.java).apply {
                    action = "com.awqatsalaah.WIDGET_PRAYER_ALARM"
                }
                val pendingFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingAlarmIntent = PendingIntent.getBroadcast(
                    context, ALARM_REQUEST_CODE, alarmIntent, pendingFlags
                )
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                alarmManager.cancel(pendingAlarmIntent)
                WidgetDiagnostics.log(context, "Alarm cancelled")
            } catch (e: Throwable) {
                WidgetDiagnostics.log(context, "cancelAlarm ERROR: ${e.message}")
            }
        }

        /**
         * Format a timestamp to a human-readable time string.
         */
        private fun formatTime(timestampMs: Long, is24Hour: Boolean): String {
            return try {
                val pattern = if (is24Hour) "HH:mm" else "hh:mm a"
                val sdf = SimpleDateFormat(pattern, Locale("ar"))
                sdf.format(Date(timestampMs))
            } catch (e: Throwable) {
                "--:--"
            }
        }
    }
}
