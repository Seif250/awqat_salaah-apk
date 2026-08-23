package com.awqatsalaah.awqat_salaah.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.os.SystemClock
import android.widget.RemoteViews
import com.awqatsalaah.awqat_salaah.MainActivity
import com.awqatsalaah.awqat_salaah.R

class PrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences("PrayerWidgetPrefs", Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.prayer_widget_layout)

            // Read persisted prayer strings from Flutter
            val cityName = prefs.getString("widget_city_name", "القاهرة") ?: "القاهرة"
            val nextPrayerName = prefs.getString("widget_next_prayer_name", "الصلاة القادمة") ?: "الصلاة القادمة"
            val nextPrayerTime = prefs.getString("widget_next_prayer_time", "--:--") ?: "--:--"
            val nextPrayerTimestamp = prefs.getLong("widget_next_prayer_timestamp", 0L)

            val fajr = prefs.getString("widget_fajr", "--:--") ?: "--:--"
            val dhuhr = prefs.getString("widget_dhuhr", "--:--") ?: "--:--"
            val asr = prefs.getString("widget_asr", "--:--") ?: "--:--"
            val maghrib = prefs.getString("widget_maghrib", "--:--") ?: "--:--"
            val isha = prefs.getString("widget_isha", "--:--") ?: "--:--"

            // Bind values to RemoteViews
            views.setTextViewText(R.id.widget_city_name, cityName)
            views.setTextViewText(R.id.widget_next_prayer_name, nextPrayerName)
            views.setTextViewText(R.id.widget_next_prayer_time, nextPrayerTime)

            views.setTextViewText(R.id.widget_time_fajr, fajr)
            views.setTextViewText(R.id.widget_time_dhuhr, dhuhr)
            views.setTextViewText(R.id.widget_time_asr, asr)
            views.setTextViewText(R.id.widget_time_maghrib, maghrib)
            views.setTextViewText(R.id.widget_time_isha, isha)

            // Configure Native Chronometer Countdown (Zero Battery Drain)
            if (nextPrayerTimestamp > 0) {
                val now = System.currentTimeMillis()
                val remainingMillis = nextPrayerTimestamp - now
                if (remainingMillis > 0) {
                    val baseElapsed = SystemClock.elapsedRealtime() + remainingMillis
                    views.setChronometer(R.id.widget_chronometer, baseElapsed, "%s", true)
                    views.setChronometerCountDown(R.id.widget_chronometer, true)
                } else {
                    views.setChronometer(R.id.widget_chronometer, SystemClock.elapsedRealtime(), "00:00:00", false)
                }
            }

            // Launch Flutter MainActivity when widget is tapped
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Push update to the home screen widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
