package com.awqatsalaah.awqat_salaah.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.SystemClock
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
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

                for (prayer in PRAYER_ORDER) {
                    val adhanTs = timestamps[prayer] ?: 0
                    if (adhanTs <= 0) continue

                    if (now < adhanTs) {
                        focusPrayer = prayer
                        targetTimestamp = adhanTs
                        phase = "beforeAdhan"
                        break
                    }

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

                val prayerDisplayName = prefs.getString("widget_name_$focusPrayer", focusPrayer) ?: focusPrayer
                prefs.edit().putString("widget_current_focus_prayer", "$prayerDisplayName ($phase)").apply()

                WidgetDiagnostics.log(context, "Focus: $focusPrayer ($phase), target: ${WidgetDiagnostics.formatTs(targetTimestamp)}")

                // ── Header: Location & App Title ──
                val cityName = prefs.getString("widget_city_name", "القاهرة") ?: "القاهرة"
                val appTitle = prefs.getString("widget_app_title", "فُرقان") ?: "فُرقان"
                views.setTextViewText(R.id.widget_city_name, cityName)
                views.setTextViewText(R.id.widget_title, appTitle)

                // ── Middle: Next Prayer Highlight (Left) ──
                val nextPrayerDisplay = if (phase == "duringIqamah") {
                    "$prayerDisplayName (أُذِّن الآن)"
                } else {
                    prayerDisplayName
                }
                views.setTextViewText(R.id.widget_next_prayer_name, nextPrayerDisplay)

                val nextPrayerTimeFormatted = if (targetTimestamp > 0) {
                    formatWidgetTime(targetTimestamp, is24Hour)
                } else {
                    prefs.getString("widget_next_prayer_time", "--:--") ?: "--:--"
                }
                views.setTextViewText(R.id.widget_next_prayer_time, nextPrayerTimeFormatted)

                // ── Middle: Live Chronometer Countdown (Right) ──
                if (targetTimestamp > 0 && targetTimestamp > now) {
                    val elapsedDiff = targetTimestamp - now
                    val chronometerBase = SystemClock.elapsedRealtime() + elapsedDiff
                    views.setChronometer(R.id.widget_chronometer, chronometerBase, null, true)

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.widget_chronometer, true)
                    }
                    views.setViewVisibility(R.id.widget_chronometer, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_chronometer, android.view.View.GONE)
                }

                // ── Bottom: 5 Prayers with Dynamic Highlight & Matching Icons ──
                val goldColor = ContextCompat.getColor(context, R.color.widget_text_gold)
                val primaryColor = ContextCompat.getColor(context, R.color.widget_text_primary)
                val secondaryColor = ContextCompat.getColor(context, R.color.widget_text_secondary)

                // Map sunrise to dhuhr as the next obligatory prayer
                val activePrayerKey = if (focusPrayer == "sunrise") "dhuhr" else focusPrayer

                // Helper to format clean prayer time without AM/PM
                fun cleanPrayerTime(key: String, rawFallback: String?): String {
                    val ts = timestamps[key]
                    if (ts != null && ts > 0) {
                        return formatWidgetTime(ts, is24Hour)
                    }
                    if (rawFallback == null || rawFallback.isEmpty()) return "--:--"
                    return rawFallback.replace(" AM", "").replace(" PM", "").replace(" ص", "").replace(" م", "").trim()
                }

                val fajrTimeStr = cleanPrayerTime("fajr", prefs.getString("widget_fajr", "--:--"))
                val dhuhrTimeStr = cleanPrayerTime("dhuhr", prefs.getString("widget_dhuhr", "--:--"))
                val asrTimeStr = cleanPrayerTime("asr", prefs.getString("widget_asr", "--:--"))
                val maghribTimeStr = cleanPrayerTime("maghrib", prefs.getString("widget_maghrib", "--:--"))
                val ishaTimeStr = cleanPrayerTime("isha", prefs.getString("widget_isha", "--:--"))

                views.setTextViewText(R.id.widget_time_fajr, fajrTimeStr)
                views.setTextViewText(R.id.widget_time_dhuhr, dhuhrTimeStr)
                views.setTextViewText(R.id.widget_time_asr, asrTimeStr)
                views.setTextViewText(R.id.widget_time_maghrib, maghribTimeStr)
                views.setTextViewText(R.id.widget_time_isha, ishaTimeStr)

                // List of prayers with their view ids and column container id
                data class PrayerItemConfig(
                    val key: String,
                    val colId: Int,
                    val iconId: Int,
                    val labelId: Int,
                    val timeId: Int
                )

                val prayersConfig = listOf(
                    PrayerItemConfig("fajr", R.id.widget_col_fajr, R.id.widget_icon_fajr, R.id.widget_label_fajr, R.id.widget_time_fajr),
                    PrayerItemConfig("dhuhr", R.id.widget_col_dhuhr, R.id.widget_icon_dhuhr, R.id.widget_label_dhuhr, R.id.widget_time_dhuhr),
                    PrayerItemConfig("asr", R.id.widget_col_asr, R.id.widget_icon_asr, R.id.widget_label_asr, R.id.widget_time_asr),
                    PrayerItemConfig("maghrib", R.id.widget_col_maghrib, R.id.widget_icon_maghrib, R.id.widget_label_maghrib, R.id.widget_time_maghrib),
                    PrayerItemConfig("isha", R.id.widget_col_isha, R.id.widget_icon_isha, R.id.widget_label_isha, R.id.widget_time_isha)
                )

                for (config in prayersConfig) {
                    val isActive = (config.key == activePrayerKey)

                    if (isActive) {
                        views.setTextColor(config.labelId, goldColor)
                        views.setTextColor(config.timeId, goldColor)
                        views.setInt(config.colId, "setBackgroundResource", R.drawable.widget_active_prayer_bg)
                        val activeIcon = when (config.key) {
                            "fajr" -> R.drawable.ic_widget_fajr_active
                            "dhuhr" -> R.drawable.ic_widget_dhuhr_active
                            "asr" -> R.drawable.ic_widget_asr_active
                            "maghrib" -> R.drawable.ic_widget_maghrib_active
                            "isha" -> R.drawable.ic_widget_isha_active
                            else -> R.drawable.ic_widget_dhuhr_active
                        }
                        views.setImageViewResource(config.iconId, activeIcon)
                    } else {
                        views.setTextColor(config.labelId, secondaryColor)
                        views.setTextColor(config.timeId, primaryColor)
                        views.setInt(config.colId, "setBackgroundResource", R.drawable.widget_inactive_prayer_bg)
                        val normalIcon = when (config.key) {
                            "fajr" -> R.drawable.ic_widget_fajr
                            "dhuhr" -> R.drawable.ic_widget_dhuhr
                            "asr" -> R.drawable.ic_widget_asr
                            "maghrib" -> R.drawable.ic_widget_maghrib
                            "isha" -> R.drawable.ic_widget_isha
                            else -> R.drawable.ic_widget_dhuhr
                        }
                        views.setImageViewResource(config.iconId, normalIcon)
                    }
                }

                // ── Tap to open app: Direct, reliable launch from anywhere on the widget ──
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, flags)

                // Attach click listener to root and all major section containers for 100% responsiveness
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_header, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_middle_card, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_bottom_row, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_col_fajr, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_col_dhuhr, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_col_asr, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_col_maghrib, pendingIntent)
                views.setOnClickPendingIntent(R.id.widget_col_isha, pendingIntent)

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
         */
        private fun scheduleNextAlarm(
            context: Context,
            now: Long,
            timestamps: Map<String, Long>,
            iqamahTimestamps: Map<String, Long>,
            tomorrowFajr: Long
        ) {
            try {
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
         * Format a timestamp to a clean widget time string (e.g. 12:53 or 5:09).
         */
        private fun formatWidgetTime(timestampMs: Long, is24Hour: Boolean): String {
            return try {
                val pattern = if (is24Hour) "HH:mm" else "h:mm"
                val sdf = SimpleDateFormat(pattern, Locale("ar"))
                sdf.format(Date(timestampMs))
            } catch (e: Throwable) {
                "--:--"
            }
        }
    }
}
