package com.awqatsalaah.awqat_salaah

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.database.ContentObserver
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import com.awqatsalaah.awqat_salaah.widget.WidgetDiagnostics

/**
 * AdhanSilencer is responsible for immediately silencing and cancelling active Adhan
 * sound and notifications whenever the user presses:
 * 1. Hardware Volume Up button
 * 2. Hardware Volume Down button
 * 3. Hardware Power button (Screen Off / Lock)
 *
 * Works in foreground, background, and on the lock screen.
 */
object AdhanSilencer {
    private var isInitialized = false
    var activePlayer: MediaPlayer? = null
    var isManualPlaying: Boolean = false

    private val PRAYER_CHANNELS = listOf(
        "prayer_channel_azan_full_v1",
        "prayer_channel_azan_hayya_v1",
        "prayer_channel_takbeer_v1",
        "prayer_times_azan_channel_v9",
        "prayer_times_default_sound",
        "prayer_times_channel_sound"
    )

    private val handler = Handler(Looper.getMainLooper())

    /**
     * Initializes global broadcast receivers and content observers on the Application context.
     */
    fun init(appContext: Context) {
        if (isInitialized) return
        isInitialized = true

        try {
            // 1. Receiver for Screen Off (Power button pressed) and Volume Changed Action
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction("android.media.VOLUME_CHANGED_ACTION")
            }
            appContext.registerReceiver(object : BroadcastReceiver() {
                override fun onReceive(context: Context, intent: Intent?) {
                    val action = intent?.action ?: return
                    WidgetDiagnostics.log(context, "AdhanSilencer: Broadcast received: $action")
                    silenceAdhan(context)
                }
            }, filter)

            // 2. ContentObserver on system volume settings for hardware Volume Up/Down clicks
            try {
                val observer = object : ContentObserver(handler) {
                    override fun onChange(selfChange: Boolean) {
                        super.onChange(selfChange)
                        silenceAdhan(appContext)
                    }
                }
                appContext.contentResolver.registerContentObserver(
                    Settings.System.CONTENT_URI,
                    true,
                    observer
                )
            } catch (e: Exception) {
                WidgetDiagnostics.log(appContext, "ContentObserver registration error: ${e.message}")
            }

            WidgetDiagnostics.log(appContext, "AdhanSilencer fully initialized with Volume & Power listeners")
        } catch (e: Exception) {
            WidgetDiagnostics.log(appContext, "AdhanSilencer init ERROR: ${e.message}")
        }
    }

    /**
     * Checks if any prayer notification is currently active and visible in the notification manager.
     */
    fun isAdhanNotificationActive(context: Context): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return false
                val activeNotifs = nm.activeNotifications
                for (sbn in activeNotifs) {
                    val channelId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        sbn.notification.channelId
                    } else null

                    val id = sbn.id
                    val isPrayerId = (id in 10000..99999) || id == 8888 || (id in 100..106)
                    val isPrayerChannel = channelId != null && (
                        PRAYER_CHANNELS.contains(channelId) || channelId.startsWith("prayer_")
                    )

                    if (isPrayerId || isPrayerChannel) {
                        return true
                    }
                }
            } catch (e: Exception) {
                WidgetDiagnostics.log(context, "isAdhanActive check error: ${e.message}")
            }
        }
        return false
    }

    /**
     * Silences any active Adhan sound, cancels the prayer notification, and stops any playing MediaPlayer.
     * Returns true if an active Adhan or player was silenced, false otherwise.
     */
    fun silenceAdhan(context: Context): Boolean {
        val hasActiveNotification = isAdhanNotificationActive(context)
        val hasActivePlayer = (activePlayer != null && activePlayer?.isPlaying == true) || isManualPlaying

        if (!hasActiveNotification && !hasActivePlayer) {
            return false // Normal volume or power press — no Adhan to silence
        }

        WidgetDiagnostics.log(context, "AdhanSilencer: Silencing Adhan via hardware key (hasNotif=$hasActiveNotification, hasPlayer=$hasActivePlayer)")

        // 1. Cancel prayer notifications to immediately stop notification sound playback
        try {
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && nm != null) {
                for (sbn in nm.activeNotifications) {
                    val id = sbn.id
                    val channelId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) sbn.notification.channelId else null
                    val isPrayerId = (id in 10000..99999) || id == 8888 || (id in 100..106)
                    val isPrayerChannel = channelId != null && (
                        PRAYER_CHANNELS.contains(channelId) || channelId.startsWith("prayer_")
                    )

                    if (isPrayerId || isPrayerChannel) {
                        nm.cancel(id)
                        WidgetDiagnostics.log(context, "AdhanSilencer: Cancelled notification id=$id")
                    }
                }
            } else {
                nm?.cancelAll()
            }
        } catch (e: Exception) {
            WidgetDiagnostics.log(context, "AdhanSilencer: Notification cancel error: ${e.message}")
        }

        // 2. Stop any active MediaPlayer
        try {
            activePlayer?.apply {
                if (isPlaying) {
                    stop()
                }
                release()
            }
            activePlayer = null
            isManualPlaying = false
        } catch (e: Exception) {
            WidgetDiagnostics.log(context, "AdhanSilencer: MediaPlayer stop error: ${e.message}")
        }

        // 3. Transient audio focus request to immediately cut off any ongoing hardware alarm stream
        try {
            val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            if (am != null) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    val focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                        .setAudioAttributes(
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ALARM)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build()
                        )
                        .build()
                    am.requestAudioFocus(focusRequest)
                    // Release immediately so system audio returns to normal state
                    handler.postDelayed({
                        try {
                            am.abandonAudioFocusRequest(focusRequest)
                        } catch (_: Exception) {}
                    }, 500)
                } else {
                    @Suppress("DEPRECATION")
                    am.requestAudioFocus(null, AudioManager.STREAM_ALARM, AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
                    handler.postDelayed({
                        try {
                            @Suppress("DEPRECATION")
                            am.abandonAudioFocus(null)
                        } catch (_: Exception) {}
                    }, 500)
                }
            }
        } catch (e: Exception) {
            WidgetDiagnostics.log(context, "AdhanSilencer: Audio focus request error: ${e.message}")
        }

        return true
    }
}
