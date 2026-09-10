package com.awqatsalaah.awqat_salaah.boot

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import com.awqatsalaah.awqat_salaah.widget.PrayerWidgetProvider
import com.awqatsalaah.awqat_salaah.widget.WidgetDiagnostics

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            WidgetDiagnostics.log(context, "BootReceiver: ${intent.action} — refreshing widgets & re-scheduling alarms")

            // Refresh and re-render all active widgets on boot
            // This will also re-schedule AlarmManager via updateAppWidget()
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            if (appWidgetIds.isEmpty()) {
                WidgetDiagnostics.log(context, "BootReceiver: No active widgets found")
                return
            }

            WidgetDiagnostics.log(context, "BootReceiver: Updating ${appWidgetIds.size} widget(s)")
            for (appWidgetId in appWidgetIds) {
                PrayerWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}
