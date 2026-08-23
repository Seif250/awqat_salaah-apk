package com.awqatsalaah.awqat_salaah

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.annotation.NonNull
import com.awqatsalaah.awqat_salaah.widget.PrayerWidgetProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.awqatsalaah/widget"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "updateWidget") {
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

                        // Push update to all active instances of the widget
                        val appWidgetManager = AppWidgetManager.getInstance(context)
                        val ids = appWidgetManager.getAppWidgetIds(
                            ComponentName(context, PrayerWidgetProvider::class.java)
                        )
                        for (id in ids) {
                            PrayerWidgetProvider.updateAppWidget(context, appWidgetManager, id)
                        }
                    }
                    result.success(true)
                } catch (e: Exception) {
                    result.error("WIDGET_ERROR", e.localizedMessage, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
