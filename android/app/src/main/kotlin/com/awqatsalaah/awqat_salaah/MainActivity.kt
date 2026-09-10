package com.awqatsalaah.awqat_salaah

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.annotation.NonNull
import com.awqatsalaah.awqat_salaah.widget.PrayerWidgetProvider
import com.awqatsalaah.awqat_salaah.widget.WidgetDiagnostics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.awqatsalaah/widget"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    try {
                        val args = call.arguments as? Map<*, *>
                        if (args != null) {
                            val prefs = context.getSharedPreferences("PrayerWidgetPrefs", Context.MODE_PRIVATE)
                            val editor = prefs.edit()

                            for ((key, value) in args) {
                                if (key is String) {
                                    when (value) {
                                        is String -> editor.putString(key, value)
                                        is Long -> editor.putLong(key, value)
                                        is Int -> editor.putLong(key, value.toLong())
                                        is Boolean -> editor.putBoolean(key, value)
                                    }
                                }
                            }
                            editor.apply()

                            WidgetDiagnostics.log(context, "Flutter→updateWidget: data saved to prefs")

                            // Also compute and store tomorrow's fajr timestamp if not provided
                            // (Flutter sends today's times; native uses widget_ts_tomorrow_fajr)
                            // We handle this by scheduling alarm to first available future time

                            // Push update to all active instances of the widget
                            val appWidgetManager = AppWidgetManager.getInstance(context)
                            val ids = appWidgetManager.getAppWidgetIds(
                                ComponentName(context, PrayerWidgetProvider::class.java)
                            )
                            WidgetDiagnostics.log(context, "Flutter→updateWidget: pushing to ${ids.size} widget(s)")
                            for (id in ids) {
                                PrayerWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        WidgetDiagnostics.log(context, "Flutter→updateWidget ERROR: ${e.localizedMessage}")
                        result.error("WIDGET_ERROR", e.localizedMessage, null)
                    }
                }

                "getWidgetDiagnostics" -> {
                    try {
                        val log = WidgetDiagnostics.readLog(context)
                        result.success(log)
                    } catch (e: Exception) {
                        result.error("DIAG_ERROR", e.localizedMessage, null)
                    }
                }

                "forceRefreshWidget" -> {
                    try {
                        WidgetDiagnostics.log(context, "Flutter→forceRefreshWidget called")
                        val appWidgetManager = AppWidgetManager.getInstance(context)
                        val ids = appWidgetManager.getAppWidgetIds(
                            ComponentName(context, PrayerWidgetProvider::class.java)
                        )
                        for (id in ids) {
                            PrayerWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        WidgetDiagnostics.log(context, "Flutter→forceRefreshWidget ERROR: ${e.localizedMessage}")
                        result.error("REFRESH_ERROR", e.localizedMessage, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}
