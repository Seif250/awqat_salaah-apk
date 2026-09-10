package com.awqatsalaah.awqat_salaah.widget

import android.content.Context
import android.util.Log
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * Diagnostic logging utility for the prayer widget.
 * Stores a rolling log in SharedPreferences so Flutter can read it
 * for troubleshooting when testing on-device.
 */
object WidgetDiagnostics {
    private const val TAG = "PrayerWidget"
    private const val MAX_LOG_ENTRIES = 80
    private const val PREFS_NAME = "PrayerWidgetPrefs"
    private const val KEY_LOG = "widget_diagnostic_log"
    private val dateFormat = SimpleDateFormat("MM-dd HH:mm:ss", Locale.US)

    /**
     * Append a diagnostic message to the persistent log and to Logcat.
     */
    fun log(context: Context, message: String) {
        Log.d(TAG, message)
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val existing = prefs.getString(KEY_LOG, "") ?: ""
            val timestamp = dateFormat.format(Date())
            val newEntry = "[$timestamp] $message"

            // Keep only last N entries
            val lines = existing.split("\n").toMutableList()
            lines.add(newEntry)
            while (lines.size > MAX_LOG_ENTRIES) {
                lines.removeAt(0)
            }

            prefs.edit().putString(KEY_LOG, lines.joinToString("\n")).apply()
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to write diagnostic log: ${e.message}")
        }
    }

    /**
     * Read the full diagnostic log as a single string.
     */
    fun readLog(context: Context): String {
        return try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val log = prefs.getString(KEY_LOG, "") ?: ""

            // Append current state summary at the end
            val now = System.currentTimeMillis()
            val nextTs = prefs.getLong("widget_scheduled_alarm_ts", 0)
            val lastUpdate = prefs.getLong("widget_last_update_ts", 0)
            val currentPrayer = prefs.getString("widget_current_focus_prayer", "unknown")

            val summary = buildString {
                appendLine("\n═══ حالة الـ Widget الآن ═══")
                appendLine("الوقت الحالي: ${dateFormat.format(Date(now))}")
                appendLine("آخر تحديث: ${if (lastUpdate > 0) dateFormat.format(Date(lastUpdate)) else "لم يتم بعد"}")
                appendLine("الصلاة المعروضة: $currentPrayer")
                if (nextTs > 0) {
                    val remaining = (nextTs - now) / 1000
                    appendLine("المنبه القادم: ${dateFormat.format(Date(nextTs))} (بعد ${remaining}ث)")
                } else {
                    appendLine("المنبه القادم: غير مجدول ⚠️")
                }
            }

            if (log.isNotEmpty()) "$log\n$summary" else summary
        } catch (e: Throwable) {
            "خطأ في قراءة السجل: ${e.message}"
        }
    }

    /**
     * Format a timestamp for display.
     */
    fun formatTs(ts: Long): String {
        return if (ts > 0) dateFormat.format(Date(ts)) else "--:--"
    }
}
