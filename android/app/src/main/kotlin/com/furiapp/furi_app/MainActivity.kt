package com.furiapp.furi_app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.net.http.SslError
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Message
import android.view.KeyEvent
import android.view.View
import android.view.ViewGroup
import android.webkit.ClientCertRequest
import android.webkit.HttpAuthHandler
import android.webkit.RenderProcessGoneDetail
import android.webkit.SslErrorHandler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val MUSIC_CHANNEL = "com.furiapp.furi_app/music_service"
        private const val REQ_POST_NOTIFICATIONS = 4010
        private var methodChannel: MethodChannel? = null
        private val mainHandler = Handler(Looper.getMainLooper())

        fun dispatchMusicAction(actionId: String, positionMs: Long?) {
            mainHandler.post {
                try {
                    val args = hashMapOf<String, Any?>("actionId" to actionId)
                    if (positionMs != null) {
                        args["positionMs"] = positionMs
                    }
                    methodChannel?.invokeMethod("onMusicAction", args)
                } catch (_: Exception) {
                }
            }
        }
    }

    private var askedNotificationPermissionThisSession = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MUSIC_CHANNEL)
        methodChannel = channel

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateMediaState" -> {
                    ensureNotificationPermissionIfNeeded()
                    val title = call.argument<String>("title") ?: "F.U.R.I Música"
                    val artist = call.argument<String>("artist") ?: "F.U.R.I"
                    val thumbnailUrl = call.argument<String>("thumbnailUrl") ?: ""
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val positionMs = (call.argument<Number>("positionMs")?.toLong()) ?: 0L
                    val durationMs = (call.argument<Number>("durationMs")?.toLong()) ?: 0L

                    val intent = Intent(applicationContext, FuriMusicService::class.java).apply {
                        action = FuriMusicService.ACTION_UPDATE
                        putExtra(FuriMusicService.EXTRA_TITLE, title)
                        putExtra(FuriMusicService.EXTRA_ARTIST, artist)
                        putExtra(FuriMusicService.EXTRA_THUMBNAIL_URL, thumbnailUrl)
                        putExtra(FuriMusicService.EXTRA_IS_PLAYING, isPlaying)
                        putExtra(FuriMusicService.EXTRA_POSITION_MS, positionMs)
                        putExtra(FuriMusicService.EXTRA_DURATION_MS, durationMs)
                    }
                    startMusicServiceSafely(intent, isPlaying)
                    result.success(true)
                }

                "updateMediaProgress" -> {
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: false
                    val positionMs = (call.argument<Number>("positionMs")?.toLong()) ?: 0L
                    val durationMs = (call.argument<Number>("durationMs")?.toLong()) ?: 0L

                    val intent = Intent(applicationContext, FuriMusicService::class.java).apply {
                        action = FuriMusicService.ACTION_UPDATE_PROGRESS
                        putExtra(FuriMusicService.EXTRA_IS_PLAYING, isPlaying)
                        putExtra(FuriMusicService.EXTRA_POSITION_MS, positionMs)
                        putExtra(FuriMusicService.EXTRA_DURATION_MS, durationMs)
                    }
                    try {
                        applicationContext.startService(intent)
                    } catch (_: Exception) {
                    }
                    result.success(true)
                }

                "stopMediaService" -> {
                    val intent = Intent(applicationContext, FuriMusicService::class.java).apply {
                        action = FuriMusicService.ACTION_STOP
                    }
                    try {
                        applicationContext.startService(intent)
                    } catch (_: Exception) {
                        try {
                            applicationContext.stopService(Intent(applicationContext, FuriMusicService::class.java))
                        } catch (_: Exception) {
                        }
                    }
                    result.success(true)
                }

                "protectWebViews" -> {
                    protectAllWebViews()
                    // Re-ejecutar tras 250ms y 800ms por si la plataforma monta el WebView de forma asíncrona
                    mainHandler.postDelayed({ protectAllWebViews() }, 250)
                    mainHandler.postDelayed({ protectAllWebViews() }, 800)
                    result.success(true)
                }

                "flushCookies" -> {
                    try {
                        android.webkit.CookieManager.getInstance().flush()
                        result.success(true)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }

                "checkPinterestAuthCookie" -> {
                    try {
                        val cookies = android.webkit.CookieManager.getInstance().getCookie("https://www.pinterest.com")
                        val hasSession = cookies != null && (cookies.contains("_pinterest_sess") || cookies.contains("_auth=1"))
                        result.success(hasSession)
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startMusicServiceSafely(intent: Intent, isPlaying: Boolean) {
        try {
            if (isPlaying && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(applicationContext, intent)
            } else {
                applicationContext.startService(intent)
            }
        } catch (_: Exception) {
            try {
                applicationContext.startService(intent)
            } catch (_: Exception) {
            }
        }
    }

    private fun ensureNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !askedNotificationPermissionThisSession) {
            val granted = ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
            if (!granted) {
                askedNotificationPermissionThisSession = true
                try {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        REQ_POST_NOTIFICATIONS
                    )
                } catch (_: Exception) {
                }
            }
        }
    }

    private fun protectAllWebViews() {
        val root = window?.decorView ?: return
        traverseAndProtectWebViews(root)
    }

    private fun traverseAndProtectWebViews(view: View) {
        if (view is WebView) {
            configureSafeWebView(view)
        }
        if (view is ViewGroup) {
            for (i in 0 until view.childCount) {
                val child = view.getChildAt(i)
                if (child != null) {
                    traverseAndProtectWebViews(child)
                }
            }
        }
    }

    private fun configureSafeWebView(webView: WebView) {
        try {
            webView.settings.apply {
                setSupportMultipleWindows(false)
                javaScriptCanOpenWindowsAutomatically = false
                domStorageEnabled = true
                databaseEnabled = true
                allowFileAccess = true
                allowContentAccess = true
                saveFormData = true
                useWideViewPort = true
                loadWithOverviewMode = true
                cacheMode = WebSettings.LOAD_DEFAULT
            }

            android.webkit.CookieManager.getInstance().apply {
                setAcceptCookie(true)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    setAcceptThirdPartyCookies(webView, true)
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                try {
                    val swController = android.webkit.ServiceWorkerController.getInstance()
                    swController.serviceWorkerWebSettings.cacheMode = WebSettings.LOAD_DEFAULT
                    swController.serviceWorkerWebSettings.allowContentAccess = true
                    swController.serviceWorkerWebSettings.allowFileAccess = true
                } catch (_: Exception) {
                }
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val existingClient = webView.webViewClient
                if (existingClient !is SafeFuriWebViewClient) {
                    webView.webViewClient = SafeFuriWebViewClient(existingClient)
                }
            }
        } catch (_: Exception) {
        }
    }

    private class SafeFuriWebViewClient(
        private val delegate: WebViewClient?
    ) : WebViewClient() {

        override fun onPageStarted(view: WebView, url: String, favicon: Bitmap?) {
            delegate?.onPageStarted(view, url, favicon) ?: super.onPageStarted(view, url, favicon)
        }

        override fun onPageFinished(view: WebView, url: String) {
            delegate?.onPageFinished(view, url)
        }

        override fun onPageCommitVisible(view: WebView, url: String) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                delegate?.onPageCommitVisible(view, url)
            }
        }

        override fun onLoadResource(view: WebView, url: String) {
            delegate?.onLoadResource(view, url)
        }

        override fun doUpdateVisitedHistory(view: WebView, url: String, isReload: Boolean) {
            delegate?.doUpdateVisitedHistory(view, url, isReload)
        }

        override fun onReceivedError(
            view: WebView,
            request: WebResourceRequest,
            error: WebResourceError
        ) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                delegate?.onReceivedError(view, request, error)
            }
        }

        override fun onReceivedHttpError(
            view: WebView,
            request: WebResourceRequest,
            errorResponse: WebResourceResponse
        ) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                delegate?.onReceivedHttpError(view, request, errorResponse)
            }
        }

        override fun onReceivedSslError(
            view: WebView,
            handler: SslErrorHandler,
            error: SslError
        ) {
            delegate?.onReceivedSslError(view, handler, error) ?: super.onReceivedSslError(view, handler, error)
        }

        override fun onReceivedClientCertRequest(view: WebView, request: ClientCertRequest) {
            delegate?.onReceivedClientCertRequest(view, request)
        }

        override fun onReceivedHttpAuthRequest(
            view: WebView,
            handler: HttpAuthHandler,
            host: String,
            realm: String
        ) {
            delegate?.onReceivedHttpAuthRequest(view, handler, host, realm)
        }

        override fun onFormResubmission(view: WebView, dontResend: Message, resend: Message) {
            delegate?.onFormResubmission(view, dontResend, resend)
        }

        override fun onScaleChanged(view: WebView, oldScale: Float, newScale: Float) {
            delegate?.onScaleChanged(view, oldScale, newScale)
        }

        override fun onUnhandledKeyEvent(view: WebView, event: KeyEvent) {
            delegate?.onUnhandledKeyEvent(view, event)
        }

        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            val uri = request.url ?: return true
            val scheme = uri.scheme?.lowercase() ?: ""
            if (scheme != "http" && scheme != "https") {
                // Bloquear esquemas externos (intent://, pinterest://, market://) sin cancelar redirects HTTP
                return true
            }
            val host = uri.host?.lowercase() ?: ""
            if (host.contains("play.google.com") || host.contains("apps.apple.com")) {
                return true
            }
            return false
        }

        @Deprecated("Deprecated in Java")
        override fun shouldOverrideUrlLoading(view: WebView, url: String): Boolean {
            val uri = android.net.Uri.parse(url) ?: return true
            val scheme = uri.scheme?.lowercase() ?: ""
            if (scheme != "http" && scheme != "https") {
                return true
            }
            val host = uri.host?.lowercase() ?: ""
            if (host.contains("play.google.com") || host.contains("apps.apple.com")) {
                return true
            }
            return false
        }

        override fun onRenderProcessGone(
            view: WebView,
            detail: RenderProcessGoneDetail
        ): Boolean {
            // CRÍTICO: devolver true evita que Android mate toda la app F.U.R.I si el proceso renderer de Chromium colapsa por RAM/GPU
            dispatchMusicAction("webview_renderer_gone", null)
            return true
        }
    }
}
