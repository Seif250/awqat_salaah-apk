package com.awqatsalaah.awqat_salaah.boot

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import com.awqatsalaah.awqat_salaah.widget.PrayerWidgetProvider

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON" ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            // Refresh and re-render all active widgets on boot
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = ComponentName(context, PrayerWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)

            for (appWidgetId in appWidgetIds) {
                PrayerWidgetProvider.updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
}
