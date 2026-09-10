package com.awqatsalaah.awqat_salaah.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/**
 * BroadcastReceiver that fires at each prayer time via AlarmManager.
 * Updates the widget to the next prayer and re-schedules the next alarm.
 */
class WidgetAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            WidgetDiagnostics.log(context, "AlarmReceiver: onReceive triggered, action=${intent.action}")

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            if (appWidgetIds.isEmpty()) {
                WidgetDiagnostics.log(context, "AlarmReceiver: No active widget instances found")
                return
            }

            WidgetDiagnostics.log(context, "AlarmReceiver: Updating ${appWidgetIds.size} widget(s)")
            for (appWidgetId in appWidgetIds) {
                PrayerWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        } catch (e: Throwable) {
            WidgetDiagnostics.log(context, "AlarmReceiver ERROR: ${e.message}")
            e.printStackTrace()
        }
    }
}
