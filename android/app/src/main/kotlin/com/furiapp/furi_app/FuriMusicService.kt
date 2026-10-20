package com.furiapp.furi_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.drawable.Icon
import android.media.MediaMetadata
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.SystemClock
import androidx.core.content.ContextCompat
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

class FuriMusicService : Service() {

    companion object {
        const val CHANNEL_ID = "furi_media_playback_v3"
        const val NOTIFICATION_ID = 99999

        const val ACTION_UPDATE = "com.furiapp.furi_app.ACTION_UPDATE"
        const val ACTION_UPDATE_PROGRESS = "com.furiapp.furi_app.ACTION_UPDATE_PROGRESS"
        const val ACTION_PREV = "com.furiapp.furi_app.ACTION_PREV"
        const val ACTION_PLAY_PAUSE = "com.furiapp.furi_app.ACTION_PLAY_PAUSE"
        const val ACTION_NEXT = "com.furiapp.furi_app.ACTION_NEXT"
        const val ACTION_STOP = "com.furiapp.furi_app.ACTION_STOP"

        const val EXTRA_TITLE = "title"
        const val EXTRA_ARTIST = "artist"
        const val EXTRA_THUMBNAIL_URL = "thumbnailUrl"
        const val EXTRA_IS_PLAYING = "isPlaying"
        const val EXTRA_POSITION_MS = "positionMs"
        const val EXTRA_DURATION_MS = "durationMs"
    }

    private var mediaSession: MediaSession? = null
    private lateinit var notificationManager: NotificationManager
    private val mainHandler = Handler(Looper.getMainLooper())
    private val artExecutor = Executors.newSingleThreadExecutor()

    private var currentTitle: String = "F.U.R.I Música"
    private var currentArtist: String = "Reproduciendo"
    private var currentThumbnailUrl: String = ""
    private var isPlaying: Boolean = false
    private var currentPositionMs: Long = 0L
    private var currentDurationMs: Long = 0L
    private var isInForeground: Boolean = false

    private var cachedArtUrl: String = ""
    private var cachedArtBitmap: Bitmap? = null
    private var defaultArtBitmap: Bitmap? = null

    override fun onCreate() {
        super.onCreate()
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        initMediaSession()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "F.U.R.I Reproductor de Música",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Controles de reproducción y barra de progreso de música de F.U.R.I"
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun initMediaSession() {
        val session = MediaSession(this, "FuriMediaSession")
        @Suppress("DEPRECATION")
        session.setFlags(
            MediaSession.FLAG_HANDLES_MEDIA_BUTTONS or
                MediaSession.FLAG_HANDLES_TRANSPORT_CONTROLS
        )
        session.setCallback(object : MediaSession.Callback() {
            override fun onPlay() {
                isPlaying = true
                updatePlaybackState()
                showOrUpdateNotification()
                MainActivity.dispatchMusicAction("music_play", null)
            }

            override fun onPause() {
                isPlaying = false
                updatePlaybackState()
                showOrUpdateNotification()
                MainActivity.dispatchMusicAction("music_pause", null)
            }

            override fun onSkipToNext() {
                MainActivity.dispatchMusicAction("music_next", null)
            }

            override fun onSkipToPrevious() {
                MainActivity.dispatchMusicAction("music_prev", null)
            }

            override fun onSeekTo(pos: Long) {
                currentPositionMs = pos.coerceAtLeast(0L)
                updatePlaybackState()
                MainActivity.dispatchMusicAction("music_seek", currentPositionMs)
            }

            override fun onStop() {
                isPlaying = false
                MainActivity.dispatchMusicAction("music_stop", null)
                stopForegroundService()
            }
        })

        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        if (launchIntent != null) {
            val pi = PendingIntent.getActivity(
                this,
                100,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            session.setSessionActivity(pi)
        }

        session.isActive = true
        mediaSession = session
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_UPDATE -> {
                val newTitle = intent.getStringExtra(EXTRA_TITLE) ?: currentTitle
                val newArtist = intent.getStringExtra(EXTRA_ARTIST)?.takeIf { it.isNotBlank() } ?: "F.U.R.I Música"
                val newThumb = intent.getStringExtra(EXTRA_THUMBNAIL_URL) ?: ""
                val newPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, isPlaying)
                val pos = intent.getLongExtra(EXTRA_POSITION_MS, currentPositionMs)
                val dur = intent.getLongExtra(EXTRA_DURATION_MS, currentDurationMs)

                val trackChanged = newTitle != currentTitle || newArtist != currentArtist
                currentTitle = newTitle
                currentArtist = newArtist
                isPlaying = newPlaying
                if (pos >= 0L) currentPositionMs = pos
                if (dur > 0L) {
                    currentDurationMs = dur
                } else if (trackChanged) {
                    currentDurationMs = 0L
                }

                if (newThumb.isNotBlank() && newThumb != currentThumbnailUrl) {
                    currentThumbnailUrl = newThumb
                    loadAlbumArtAsync(newThumb)
                } else if (newThumb.isBlank() && trackChanged) {
                    currentThumbnailUrl = ""
                    cachedArtBitmap = null
                }

                if (mediaSession?.isActive != true) {
                    mediaSession?.isActive = true
                }
                updateMediaMetadata()
                updatePlaybackState()
                showOrUpdateNotification()
            }

            ACTION_UPDATE_PROGRESS -> {
                val pos = intent.getLongExtra(EXTRA_POSITION_MS, currentPositionMs)
                val dur = intent.getLongExtra(EXTRA_DURATION_MS, currentDurationMs)
                val newPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, isPlaying)

                val durChanged = dur > 0L && dur != currentDurationMs
                val playingChanged = newPlaying != isPlaying

                if (pos >= 0L) currentPositionMs = pos
                if (dur > 0L) currentDurationMs = dur
                isPlaying = newPlaying

                if (durChanged) {
                    updateMediaMetadata()
                }
                updatePlaybackState()
                if (playingChanged || !isInForeground) {
                    showOrUpdateNotification()
                }
            }

            ACTION_PREV -> {
                MainActivity.dispatchMusicAction("music_prev", null)
            }

            ACTION_PLAY_PAUSE -> {
                isPlaying = !isPlaying
                updatePlaybackState()
                showOrUpdateNotification()
                MainActivity.dispatchMusicAction("music_play_pause", null)
            }

            ACTION_NEXT -> {
                MainActivity.dispatchMusicAction("music_next", null)
            }

            ACTION_STOP -> {
                stopForegroundService()
            }
        }
        return START_STICKY
    }

    private fun updateMediaMetadata() {
        val session = mediaSession ?: return
        val art = cachedArtBitmap ?: getOrCreateDefaultArt()
        val effectiveDuration = if (currentDurationMs > 0L) currentDurationMs else -1L

        val metadataBuilder = MediaMetadata.Builder()
            .putString(MediaMetadata.METADATA_KEY_TITLE, currentTitle)
            .putString(MediaMetadata.METADATA_KEY_ARTIST, currentArtist)
            .putString(MediaMetadata.METADATA_KEY_ALBUM, "F.U.R.I")
            .putLong(MediaMetadata.METADATA_KEY_DURATION, effectiveDuration)
            .putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, art)
            .putBitmap(MediaMetadata.METADATA_KEY_ART, art)

        session.setMetadata(metadataBuilder.build())
    }

    private fun updatePlaybackState() {
        val session = mediaSession ?: return
        val state = if (isPlaying) PlaybackState.STATE_PLAYING else PlaybackState.STATE_PAUSED
        val speed = if (isPlaying) 1.0f else 0.0f
        val actions = PlaybackState.ACTION_PLAY or
            PlaybackState.ACTION_PAUSE or
            PlaybackState.ACTION_PLAY_PAUSE or
            PlaybackState.ACTION_SKIP_TO_PREVIOUS or
            PlaybackState.ACTION_SKIP_TO_NEXT or
            PlaybackState.ACTION_SEEK_TO or
            PlaybackState.ACTION_STOP

        val stateBuilder = PlaybackState.Builder()
            .setActions(actions)
            .setState(state, currentPositionMs, speed, SystemClock.elapsedRealtime())

        session.setPlaybackState(stateBuilder.build())
    }

    private fun buildNotification(): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPendingIntent = if (launchIntent != null) {
            PendingIntent.getActivity(
                this,
                101,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        val prevPendingIntent = createServiceActionPendingIntent(ACTION_PREV, 201)
        val playPausePendingIntent = createServiceActionPendingIntent(ACTION_PLAY_PAUSE, 202)
        val nextPendingIntent = createServiceActionPendingIntent(ACTION_NEXT, 203)

        val prevAction = Notification.Action.Builder(
            Icon.createWithResource(this, R.drawable.ic_music_prev),
            "Anterior",
            prevPendingIntent
        ).build()

        val playPauseIcon = if (isPlaying) R.drawable.ic_music_pause else R.drawable.ic_music_play
        val playPauseTitle = if (isPlaying) "Pausar" else "Reproducir"
        val playPauseAction = Notification.Action.Builder(
            Icon.createWithResource(this, playPauseIcon),
            playPauseTitle,
            playPausePendingIntent
        ).build()

        val nextAction = Notification.Action.Builder(
            Icon.createWithResource(this, R.drawable.ic_music_next),
            "Siguiente",
            nextPendingIntent
        ).build()

        val mediaStyle = Notification.MediaStyle()
            .setShowActionsInCompactView(0, 1, 2)
        mediaSession?.sessionToken?.let { token ->
            mediaStyle.setMediaSession(token)
        }

        val art = cachedArtBitmap ?: getOrCreateDefaultArt()

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        builder
            .setSmallIcon(R.drawable.ic_notification_fox)
            .setLargeIcon(art)
            .setContentTitle(currentTitle)
            .setContentText(currentArtist)
            .setSubText("F.U.R.I")
            .setStyle(mediaStyle)
            .addAction(prevAction)
            .addAction(playPauseAction)
            .addAction(nextAction)
            .setOngoing(isPlaying)
            .setAutoCancel(false)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setCategory(Notification.CATEGORY_TRANSPORT)
            .setColor(Color.parseColor("#181818"))

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setForegroundServiceBehavior(Notification.FOREGROUND_SERVICE_IMMEDIATE)
        }

        if (contentPendingIntent != null) {
            builder.setContentIntent(contentPendingIntent)
        }

        return builder.build()
    }

    private fun createServiceActionPendingIntent(action: String, requestCode: Int): PendingIntent {
        val intent = Intent(this, FuriMusicService::class.java).apply {
            this.action = action
        }
        return PendingIntent.getService(
            this,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun showOrUpdateNotification() {
        val notification = buildNotification()
        try {
            if (!isInForeground || isPlaying) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                    )
                } else {
                    startForeground(NOTIFICATION_ID, notification)
                }
                isInForeground = true
            } else {
                notificationManager.notify(NOTIFICATION_ID, notification)
            }
        } catch (e: Exception) {
            // Fallback directo al NotificationManager si Android restringe startForeground en background
            try {
                notificationManager.notify(NOTIFICATION_ID, notification)
            } catch (_: Exception) {
            }
        }
    }

    private fun loadAlbumArtAsync(url: String) {
        if (url == cachedArtUrl && cachedArtBitmap != null) return
        artExecutor.execute {
            try {
                val connection = (URL(url).openConnection() as HttpURLConnection).apply {
                    connectTimeout = 6000
                    readTimeout = 6000
                    doInput = true
                    connect()
                }
                if (connection.responseCode == HttpURLConnection.HTTP_OK) {
                    val bmp = connection.inputStream.use { stream ->
                        BitmapFactory.decodeStream(stream)
                    }
                    if (bmp != null) {
                        mainHandler.post {
                            if (url == currentThumbnailUrl) {
                                cachedArtUrl = url
                                cachedArtBitmap = bmp
                                updateMediaMetadata()
                                showOrUpdateNotification()
                            }
                        }
                    }
                }
                connection.disconnect()
            } catch (_: Exception) {
            }
        }
    }

    private fun getOrCreateDefaultArt(): Bitmap {
        defaultArtBitmap?.let { return it }
        val size = 256
        val bmp = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)

        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#181818")
            style = Paint.Style.FILL
        }
        canvas.drawRect(0f, 0f, size.toFloat(), size.toFloat(), bgPaint)

        val circlePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#242424")
            style = Paint.Style.FILL
        }
        canvas.drawCircle(size / 2f, size / 2f, size * 0.34f, circlePaint)

        try {
            val drawable = ContextCompat.getDrawable(this, R.drawable.ic_notification_fox)
            if (drawable != null) {
                val pad = (size * 0.28f).toInt()
                drawable.setBounds(pad, pad, size - pad, size - pad)
                drawable.setTint(Color.parseColor("#FF7A00"))
                drawable.draw(canvas)
            }
        } catch (_: Exception) {
        }

        defaultArtBitmap = bmp
        return bmp
    }

    private fun stopForegroundService() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {
        }
        isInForeground = false
        try {
            notificationManager.cancel(NOTIFICATION_ID)
        } catch (_: Exception) {
        }
        mediaSession?.isActive = false
        stopSelf()
    }

    override fun onDestroy() {
        try {
            mediaSession?.isActive = false
            mediaSession?.release()
        } catch (_: Exception) {
        }
        mediaSession = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
