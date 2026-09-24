package com.awqatsalaah.awqat_salaah

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import androidx.annotation.NonNull
import com.awqatsalaah.awqat_salaah.widget.PrayerWidgetProvider
import com.awqatsalaah.awqat_salaah.widget.WidgetDiagnostics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

import android.view.KeyEvent
import android.view.WindowManager
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.awqatsalaah/widget"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )
        }
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP,
                KeyEvent.KEYCODE_VOLUME_DOWN,
                KeyEvent.KEYCODE_POWER -> {
                    if (AdhanSilencer.silenceAdhan(this)) {
                        return true // Silenced Adhan
                    }
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || 
            keyCode == KeyEvent.KEYCODE_VOLUME_DOWN || 
            keyCode == KeyEvent.KEYCODE_POWER) {
            if (AdhanSilencer.silenceAdhan(this)) {
                return true
            }
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure native Adhan notification channel with USAGE_ALARM is created on Android 8+
        createNativeNotificationChannels(context)

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

                "playAudioPreview" -> {
                    try {
                        val soundType = call.argument<String>("soundType") ?: "hayya"
                        val resId = when (soundType) {
                            "full" -> R.raw.azan_full
                            "takbeer" -> R.raw.takbeer
                            else -> R.raw.azan
                        }
                        previewPlayer?.stop()
                        previewPlayer?.release()
                        previewPlayer = android.media.MediaPlayer.create(context, resId)?.apply {
                            setOnCompletionListener {
                                it.release()
                                previewPlayer = null
                                AdhanSilencer.activePlayer = null
                            }
                            start()
                        }
                        AdhanSilencer.activePlayer = previewPlayer
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", e.localizedMessage, null)
                    }
                }

                "stopAudioPreview" -> {
                    try {
                        previewPlayer?.stop()
                        previewPlayer?.release()
                        previewPlayer = null
                        AdhanSilencer.activePlayer = null
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AUDIO_ERROR", e.localizedMessage, null)
                    }
                }

                "silenceAdhan" -> {
                    try {
                        val silenced = AdhanSilencer.silenceAdhan(context)
                        result.success(silenced)
                    } catch (e: Exception) {
                        result.error("SILENCE_ERROR", e.localizedMessage, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private var previewPlayer: android.media.MediaPlayer? = null

    override fun onDestroy() {
        previewPlayer?.stop()
        previewPlayer?.release()
        previewPlayer = null
        AdhanSilencer.activePlayer = null
        super.onDestroy()
    }

    private fun createNativeNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return

                val audioAttributes = AudioAttributes.Builder()
                    .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build()

                val channels = listOf(
                    Triple("prayer_channel_azan_full_v1", "أذان الصلوات (الأذان كامل)", R.raw.azan_full),
                    Triple("prayer_channel_azan_hayya_v1", "أذان الصلوات (حي على الصلاة)", R.raw.azan),
                    Triple("prayer_channel_takbeer_v1", "أذان الصلوات (الله أكبر الله أكبر)", R.raw.takbeer),
                    Triple("prayer_times_azan_channel_v9", "أذان الصلوات الخمس والتنبيهات", R.raw.azan)
                )

                for ((id, name, rawSound) in channels) {
                    val soundUri = Uri.parse("android.resource://" + context.packageName + "/" + rawSound)
                    val channel = NotificationChannel(id, name, NotificationManager.IMPORTANCE_HIGH).apply {
                        description = "إشعارات وتنبيهات أوقات الصلاة بصوت المؤذن بأعلى أولوية"
                        setSound(soundUri, audioAttributes)
                        enableVibration(true)
                        vibrationPattern = longArrayOf(0, 500, 250, 500, 250, 500)
                        lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                    }
                    notificationManager.createNotificationChannel(channel)
                }
                WidgetDiagnostics.log(context, "Native Adhan NotificationChannels created with USAGE_ALARM")
            } catch (e: Exception) {
                WidgetDiagnostics.log(context, "Failed to create native notification channels: ${e.message}")
            }
        }
    }
}
