package com.awqatsalaah.awqat_salaah.widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.DrawableCompat
import com.awqatsalaah.awqat_salaah.MainActivity
import com.awqatsalaah.awqat_salaah.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action
        if (action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED ||
            action == Intent.ACTION_DATE_CHANGED
        ) {
            WidgetDiagnostics.log(context, "onReceive system time event: $action")
            refreshAllWidgets(context)
        }
    }

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

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
        updateAppWidget(context, appWidgetManager, appWidgetId)
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        WidgetDiagnostics.log(context, "onEnabled: First widget added to home screen")
        refreshAllWidgets(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        WidgetDiagnostics.log(context, "onDisabled: Last widget removed, cancelling alarms")
        cancelAlarm(context)
    }

    companion object {
        private const val ALARM_REQUEST_CODE = 9001
        private const val ALARM_BACKUP_CODE = 9002
        private const val ONE_DAY_MS = 86_400_000L

        private val PRAYER_ORDER = listOf("fajr", "sunrise", "dhuhr", "asr", "maghrib", "isha")
        private val IQAMAH_PRAYERS = listOf("fajr", "dhuhr", "asr", "maghrib", "isha")

        private val bitmapCache = mutableMapOf<String, Bitmap>()

        private data class WidgetThemeColors(
            val bgRes: Int,
            val pillRes: Int,
            val accentColor: Int,
            val primaryTextColor: Int,
            val secondaryTextColor: Int,
            val mutedIconColor: Int,
            val dividerColor: Int
        )

        private fun resolveWidgetTheme(context: Context, prefs: SharedPreferences): WidgetThemeColors {
            val palette = prefs.getString("widget_palette", "royalEmerald") ?: "royalEmerald"
            val themeMode = prefs.getString("widget_theme_mode", "system") ?: "system"
            val systemDark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) ==
                Configuration.UI_MODE_NIGHT_YES
            val isDark = palette == "amoledGold" ||
                themeMode == "dark" ||
                (themeMode == "system" && systemDark)

            return when (palette) {
                "amoledGold" -> WidgetThemeColors(
                    bgRes = R.drawable.widget_bg_amoled,
                    pillRes = R.drawable.widget_pill_dark,
                    accentColor = 0xFFD8B355.toInt(),
                    primaryTextColor = 0xFFF4F3EE.toInt(),
                    secondaryTextColor = 0xFFA6A9A4.toInt(),
                    mutedIconColor = 0xFF8F9691.toInt(),
                    dividerColor = 0xFF252927.toInt()
                )
                "goldenMushaf" -> if (isDark) {
                    WidgetThemeColors(
                        bgRes = R.drawable.widget_bg_golden_dark,
                        pillRes = R.drawable.widget_pill_golden_dark,
                        accentColor = 0xFFEFD386.toInt(),
                        primaryTextColor = 0xFFF5F0E4.toInt(),
                        secondaryTextColor = 0xFFB6AC97.toInt(),
                        mutedIconColor = 0xFFA09682.toInt(),
                        dividerColor = 0xFF393227.toInt()
                    )
                } else {
                    WidgetThemeColors(
                        bgRes = R.drawable.widget_bg_golden_light,
                        pillRes = R.drawable.widget_pill_golden_light,
                        accentColor = 0xFF1A5238.toInt(),
                        primaryTextColor = 0xFF1E1910.toInt(),
                        secondaryTextColor = 0xFF655A47.toInt(),
                        mutedIconColor = 0xFF70644E.toInt(),
                        dividerColor = 0xFFE4DAC1.toInt()
                    )
                }
                else -> if (isDark) {
                    WidgetThemeColors(
                        bgRes = R.drawable.widget_bg_dark,
                        pillRes = R.drawable.widget_pill_dark,
                        accentColor = 0xFFF1D788.toInt(),
                        primaryTextColor = 0xFFEFF6F2.toInt(),
                        secondaryTextColor = 0xFFA0B8AD.toInt(),
                        mutedIconColor = 0xFF8BA398.toInt(),
                        dividerColor = 0xFF2A4236.toInt()
                    )
                } else {
                    WidgetThemeColors(
                        bgRes = R.drawable.widget_bg_emerald_light,
                        pillRes = R.drawable.widget_pill_emerald_light,
                        accentColor = 0xFF0F5E3B.toInt(),
                        primaryTextColor = 0xFF102219.toInt(),
                        secondaryTextColor = 0xFF53665C.toInt(),
                        mutedIconColor = 0xFF5F7268.toInt(),
                        dividerColor = 0xFFDFE9E3.toInt()
                    )
                }
            }
        }

        private fun getTintedVectorBitmap(
            context: Context,
            drawableId: Int,
            sizeDp: Int,
            tintColor: Int
        ): Bitmap? {
            val cacheKey = "${drawableId}_${sizeDp}_${tintColor}"
            val cached = bitmapCache[cacheKey]
            if (cached != null && !cached.isRecycled) {
                return cached
            }
            return try {
                val baseDrawable = ContextCompat.getDrawable(context, drawableId) ?: return null
                val wrapped = DrawableCompat.wrap(baseDrawable.mutate())
                DrawableCompat.setTint(wrapped, tintColor)

                val density = context.resources.displayMetrics.density
                val sizePx = (sizeDp * density).toInt().coerceAtLeast(1)
                val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                wrapped.setBounds(0, 0, canvas.width, canvas.height)
                wrapped.draw(canvas)
                bitmapCache[cacheKey] = bitmap
                bitmap
            } catch (e: Throwable) {
                WidgetDiagnostics.log(context, "getTintedVectorBitmap ERROR: ${e.message}")
                null
            }
        }

        fun refreshAllWidgets(context: Context) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                for (id in appWidgetIds) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            } catch (e: Throwable) {
                WidgetDiagnostics.log(context, "refreshAllWidgets ERROR: ${e.message}")
            }
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val prefs = context.getSharedPreferences("PrayerWidgetPrefs", Context.MODE_PRIVATE)
                val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)
                val now = System.currentTimeMillis()
                val theme = resolveWidgetTheme(context, prefs)

                prefs.edit().putLong("widget_last_update_ts", now).apply()

                // Apply Dynamic Theme Surfaces & Colors
                views.setInt(R.id.widget_root, "setBackgroundResource", theme.bgRes)
                views.setInt(R.id.widget_divider, "setBackgroundColor", theme.dividerColor)
                views.setTextColor(R.id.widget_city_name, theme.secondaryTextColor)
                views.setTextColor(R.id.widget_title, theme.accentColor)
                views.setTextColor(R.id.widget_next_prayer_label, theme.accentColor)
                views.setTextColor(R.id.widget_next_prayer_name, theme.primaryTextColor)
                views.setTextColor(R.id.widget_next_prayer_time, theme.secondaryTextColor)
                views.setTextColor(R.id.widget_countdown_label, theme.secondaryTextColor)
                views.setTextColor(R.id.widget_chronometer, theme.accentColor)
                views.setTextColor(R.id.widget_countdown_text, theme.accentColor)

                // Read Timestamps & Auto-Rollover if stored schedule is from a past day
                val timestamps = mutableMapOf<String, Long>()
                for (prayer in PRAYER_ORDER) {
                    timestamps[prayer] = prefs.getLong("widget_ts_$prayer", 0L)
                }
                val iqamahTimestamps = mutableMapOf<String, Long>()
                for (prayer in IQAMAH_PRAYERS) {
                    iqamahTimestamps[prayer] = prefs.getLong("widget_ts_iqamah_$prayer", 0L)
                }
                var tomorrowFajr = prefs.getLong("widget_ts_tomorrow_fajr", 0L)
                val is24Hour = prefs.getBoolean("widget_is_24hour", false)
                val hasSchedule = timestamps.values.any { it > 0L }

                if (hasSchedule) {
                    val lastTodayIsha = timestamps["isha"] ?: 0L
                    val boundary = if (tomorrowFajr > 0L) tomorrowFajr else (lastTodayIsha + ONE_DAY_MS / 2)
                    if (boundary > 0L && now > boundary) {
                        val daysPassed = ((now - boundary) / ONE_DAY_MS) + 1L
                        val shiftMs = daysPassed * ONE_DAY_MS
                        for (p in PRAYER_ORDER) {
                            val ts = timestamps[p] ?: 0L
                            if (ts > 0L) timestamps[p] = ts + shiftMs
                        }
                        for (p in IQAMAH_PRAYERS) {
                            val iq = iqamahTimestamps[p] ?: 0L
                            if (iq > 0L) iqamahTimestamps[p] = iq + shiftMs
                        }
                        if (tomorrowFajr > 0L) tomorrowFajr += shiftMs
                    }
                }

                // Header: Location & Wordmark
                val cityName = prefs.getString("widget_city_name", "القاهرة") ?: "القاهرة"
                val appTitle = prefs.getString("widget_app_title", "وِرد") ?: "وِرد"
                views.setTextViewText(R.id.widget_city_name, cityName)
                views.setTextViewText(R.id.widget_title, appTitle)

                getTintedVectorBitmap(context, R.drawable.ic_widget_location, 12, theme.accentColor)?.let {
                    views.setImageViewBitmap(R.id.widget_location_icon, it)
                }

                // Focus Prayer & Countdown
                if (!hasSchedule) {
                    views.setTextViewText(R.id.widget_next_prayer_label, "تطبيق وِرد")
                    views.setTextViewText(R.id.widget_next_prayer_name, "افتح للمزامنة")
                    views.setTextViewText(R.id.widget_next_prayer_time, "")
                    views.setViewVisibility(R.id.widget_chronometer, View.GONE)
                    views.setTextViewText(R.id.widget_countdown_text, "--:--")
                    views.setViewVisibility(R.id.widget_countdown_text, View.VISIBLE)
                } else {
                    var focusPrayer: String? = null
                    var targetTimestamp = 0L
                    var phase = "beforeAdhan"

                    for (prayer in PRAYER_ORDER) {
                        val adhanTs = timestamps[prayer] ?: 0L
                        if (adhanTs <= 0L) continue

                        if (now < adhanTs) {
                            focusPrayer = prayer
                            targetTimestamp = adhanTs
                            phase = "beforeAdhan"
                            break
                        }

                        if (prayer != "sunrise") {
                            val iqamahTs = iqamahTimestamps[prayer] ?: 0L
                            if (iqamahTs > 0L && now < iqamahTs) {
                                focusPrayer = prayer
                                targetTimestamp = iqamahTs
                                phase = "duringIqamah"
                                break
                            }
                        }
                    }

                    if (focusPrayer == null) {
                        focusPrayer = "fajr"
                        targetTimestamp = tomorrowFajr
                        phase = "beforeAdhan"
                    }

                    val defaultNames = mapOf(
                        "fajr" to "الفجر",
                        "sunrise" to "الشروق",
                        "dhuhr" to "الظهر",
                        "asr" to "العصر",
                        "maghrib" to "المغرب",
                        "isha" to "العشاء"
                    )
                    val prayerDisplayName = prefs.getString("widget_name_$focusPrayer", defaultNames[focusPrayer])
                        ?: defaultNames[focusPrayer]
                        ?: focusPrayer

                    prefs.edit().putString("widget_current_focus_prayer", "$prayerDisplayName ($phase)").apply()

                    val labelText = if (phase == "duringIqamah") "الإقامة بعد" else "الصلاة القادمة"
                    views.setTextViewText(R.id.widget_next_prayer_label, labelText)
                    views.setTextViewText(R.id.widget_next_prayer_name, prayerDisplayName)

                    val heroTimeStr = if (targetTimestamp > 0L) {
                        formatWidgetTime(targetTimestamp, is24Hour, includePeriod = true)
                    } else {
                        "--:--"
                    }
                    views.setTextViewText(R.id.widget_next_prayer_time, heroTimeStr)

                    if (targetTimestamp > now) {
                        val diff = targetTimestamp - now
                        val chronometerBase = SystemClock.elapsedRealtime() + diff
                        views.setChronometer(R.id.widget_chronometer, chronometerBase, null, true)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            views.setChronometerCountDown(R.id.widget_chronometer, true)
                        }
                        views.setViewVisibility(R.id.widget_chronometer, View.VISIBLE)
                        views.setViewVisibility(R.id.widget_countdown_text, View.GONE)
                    } else {
                        views.setViewVisibility(R.id.widget_chronometer, View.GONE)
                        views.setTextViewText(R.id.widget_countdown_text, "الآن")
                        views.setViewVisibility(R.id.widget_countdown_text, View.VISIBLE)
                    }

                    val activePrayerKey = if (focusPrayer == "sunrise") "dhuhr" else focusPrayer

                    fun prayerRowTime(key: String, fallbackPref: String): String {
                        val ts = timestamps[key] ?: 0L
                        if (ts > 0L) return formatWidgetTime(ts, is24Hour, includePeriod = false)
                        val raw = prefs.getString(fallbackPref, "--:--") ?: "--:--"
                        return raw.replace(" AM", "").replace(" PM", "").replace(" ص", "").replace(" م", "").trim()
                    }

                    views.setTextViewText(R.id.widget_time_fajr, prayerRowTime("fajr", "widget_fajr"))
                    views.setTextViewText(R.id.widget_time_dhuhr, prayerRowTime("dhuhr", "widget_dhuhr"))
                    views.setTextViewText(R.id.widget_time_asr, prayerRowTime("asr", "widget_asr"))
                    views.setTextViewText(R.id.widget_time_maghrib, prayerRowTime("maghrib", "widget_maghrib"))
                    views.setTextViewText(R.id.widget_time_isha, prayerRowTime("isha", "widget_isha"))

                    data class PrayerViewIds(
                        val key: String,
                        val colId: Int,
                        val iconId: Int,
                        val labelId: Int,
                        val timeId: Int,
                        val iconDrawableId: Int
                    )

                    val items = listOf(
                        PrayerViewIds("fajr", R.id.widget_col_fajr, R.id.widget_icon_fajr, R.id.widget_label_fajr, R.id.widget_time_fajr, R.drawable.ic_widget_fajr),
                        PrayerViewIds("dhuhr", R.id.widget_col_dhuhr, R.id.widget_icon_dhuhr, R.id.widget_label_dhuhr, R.id.widget_time_dhuhr, R.drawable.ic_widget_dhuhr),
                        PrayerViewIds("asr", R.id.widget_col_asr, R.id.widget_icon_asr, R.id.widget_label_asr, R.id.widget_time_asr, R.drawable.ic_widget_asr),
                        PrayerViewIds("maghrib", R.id.widget_col_maghrib, R.id.widget_icon_maghrib, R.id.widget_label_maghrib, R.id.widget_time_maghrib, R.drawable.ic_widget_maghrib),
                        PrayerViewIds("isha", R.id.widget_col_isha, R.id.widget_icon_isha, R.id.widget_label_isha, R.id.widget_time_isha, R.drawable.ic_widget_isha)
                    )

                    for (item in items) {
                        val isActive = item.key == activePrayerKey
                        if (isActive) {
                            views.setInt(item.colId, "setBackgroundResource", theme.pillRes)
                            views.setTextColor(item.labelId, theme.accentColor)
                            views.setTextColor(item.timeId, theme.accentColor)
                        } else {
                            views.setInt(item.colId, "setBackgroundResource", R.drawable.widget_inactive_prayer_bg)
                            views.setTextColor(item.labelId, theme.secondaryTextColor)
                            views.setTextColor(item.timeId, theme.primaryTextColor)
                        }

                        val tint = if (isActive) theme.accentColor else theme.mutedIconColor
                        getTintedVectorBitmap(context, item.iconDrawableId, 14, tint)?.let {
                            views.setImageViewBitmap(item.iconId, it)
                        }
                    }

                    scheduleNextAlarm(context, now, timestamps, iqamahTimestamps, tomorrowFajr)
                }

                // Launch App on Tap
                val launchIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_MAIN
                    addCategory(Intent.CATEGORY_LAUNCHER)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                val piFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }
                val pendingIntent = PendingIntent.getActivity(context, 0, launchIntent, piFlags)
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                WidgetDiagnostics.log(context, "updateAppWidget ERROR: ${e.message}\n${e.stackTraceToString().take(400)}")
            }
        }

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
                    val adhanTs = timestamps[prayer] ?: 0L
                    if (adhanTs > now) futurePoints.add(adhanTs)
                    if (prayer != "sunrise") {
                        val iqamahTs = iqamahTimestamps[prayer] ?: 0L
                        if (iqamahTs > now) futurePoints.add(iqamahTs)
                    }
                }
                if (tomorrowFajr > now) futurePoints.add(tomorrowFajr)
                if (futurePoints.isEmpty()) return

                val nextAlarmTs = futurePoints.min()
                val alarmTs = nextAlarmTs + 1500L

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
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarmTs, pendingAlarmIntent)
                    } else {
                        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarmTs, pendingAlarmIntent)
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarmTs, pendingAlarmIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, alarmTs, pendingAlarmIntent)
                }

                // Safety periodic refresh every 30 min so OEM Doze limits never stall the widget
                val backupIntent = PendingIntent.getBroadcast(
                    context, ALARM_BACKUP_CODE, alarmIntent, pendingFlags
                )
                alarmManager.setInexactRepeating(
                    AlarmManager.RTC,
                    now + 1_800_000L,
                    AlarmManager.INTERVAL_HALF_HOUR,
                    backupIntent
                )

                WidgetDiagnostics.log(context, "Alarm scheduled at ${WidgetDiagnostics.formatTs(nextAlarmTs)}")
            } catch (e: Throwable) {
                WidgetDiagnostics.log(context, "scheduleNextAlarm ERROR: ${e.message}")
            }
        }

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
                val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                alarmManager.cancel(PendingIntent.getBroadcast(context, ALARM_REQUEST_CODE, alarmIntent, pendingFlags))
                alarmManager.cancel(PendingIntent.getBroadcast(context, ALARM_BACKUP_CODE, alarmIntent, pendingFlags))
            } catch (e: Throwable) {
                WidgetDiagnostics.log(context, "cancelAlarm ERROR: ${e.message}")
            }
        }

        private fun formatWidgetTime(timestampMs: Long, is24Hour: Boolean, includePeriod: Boolean): String {
            return try {
                val pattern = if (is24Hour) "HH:mm" else "hh:mm"
                val base = SimpleDateFormat(pattern, Locale.US).format(Date(timestampMs))
                if (is24Hour || !includePeriod) return base
                val hour24 = SimpleDateFormat("H", Locale.US).format(Date(timestampMs)).toIntOrNull() ?: 0
                val period = if (hour24 >= 12) "م" else "ص"
                "$base $period"
            } catch (_: Throwable) {
                "--:--"
            }
        }
    }
}
