package uz.kozshifo.callagent

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import androidx.core.content.ContextCompat
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch

/**
 * Always-on foreground service. It listens to the phone state to measure the
 * ring-wait before pickup, reads the finished call from the CallLog, queues it
 * durably and uploads batches + a heartbeat every [TICK_MS]. Survives reboot via
 * [BootReceiver]; a reconcile pass each tick recovers calls that happened while
 * the app was down.
 */
class CallMonitorService : Service() {

    companion object {
        private const val CHANNEL_ID = "call_monitor"
        private const val NOTIF_ID = 1001
        private const val TICK_MS = 60_000L
        private const val CALLLOG_SETTLE_MS = 1_500L
        private const val BATCH = 50

        fun start(context: Context) {
            ContextCompat.startForegroundService(
                context, Intent(context, CallMonitorService::class.java)
            )
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, CallMonitorService::class.java))
        }
    }

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private lateinit var prefs: Prefs
    private lateinit var queue: UploadQueue

    // Call-state machine (timestamps in ms).
    @Volatile private var ringStartMs = 0L
    @Volatile private var offhookMs = 0L

    private var telephonyCallback: TelephonyCallback? = null
    @Suppress("DEPRECATION")
    private var phoneListener: android.telephony.PhoneStateListener? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        prefs = Prefs(this)
        queue = UploadQueue(this)
        startForegroundNotification()
        registerTelephony()
        // First run: start fresh from the current CallLog tip (no history backfill).
        if (prefs.lastCallLogId < 0 && hasCallLog()) {
            prefs.lastCallLogId = CallLogReader.maxId(contentResolver)
        }
        startLoop()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        unregisterTelephony()
        scope.cancel()
        super.onDestroy()
    }

    // ── Foreground notification ──────────────────────────────────────────────
    private fun startForegroundNotification() {
        val nm = getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(
            NotificationChannel(
                CHANNEL_ID, getString(R.string.channel_name),
                NotificationManager.IMPORTANCE_LOW
            ).apply { description = getString(R.string.channel_desc) }
        )
        val tap = PendingIntent.getActivity(
            this, 0, Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE
        )
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.notif_title))
            .setContentText(getString(R.string.notif_text))
            .setSmallIcon(R.drawable.ic_notification)
            .setOngoing(true)
            .setContentIntent(tap)
            .build()
        val type = if (Build.VERSION.SDK_INT >= 34)
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE else 0
        ServiceCompat.startForeground(this, NOTIF_ID, notification, type)
    }

    // ── Telephony listener (measures the ring-wait) ──────────────────────────
    private fun registerTelephony() {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_PHONE_STATE)
            != PackageManager.PERMISSION_GRANTED
        ) return
        val tm = getSystemService(TelephonyManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= 31) {
            val cb = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                override fun onCallStateChanged(state: Int) = handleState(state)
            }
            telephonyCallback = cb
            tm.registerTelephonyCallback(mainExecutor, cb)
        } else {
            @Suppress("DEPRECATION")
            val l = object : android.telephony.PhoneStateListener() {
                @Deprecated("Pre-API-31 fallback for TelephonyCallback")
                override fun onCallStateChanged(state: Int, phoneNumber: String?) =
                    handleState(state)
            }
            phoneListener = l
            @Suppress("DEPRECATION")
            tm.listen(l, android.telephony.PhoneStateListener.LISTEN_CALL_STATE)
        }
    }

    private fun unregisterTelephony() {
        val tm = getSystemService(TelephonyManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= 31) {
            telephonyCallback?.let { tm.unregisterTelephonyCallback(it) }
        } else {
            @Suppress("DEPRECATION")
            phoneListener?.let { tm.listen(it, android.telephony.PhoneStateListener.LISTEN_NONE) }
        }
    }

    private fun handleState(state: Int) {
        val now = System.currentTimeMillis()
        when (state) {
            TelephonyManager.CALL_STATE_RINGING -> {
                if (ringStartMs == 0L) ringStartMs = now
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                if (offhookMs == 0L) offhookMs = now
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                val ring = ringStartMs
                val offhook = offhookMs
                ringStartMs = 0L
                offhookMs = 0L
                if (ring == 0L && offhook == 0L) return // spurious IDLE, no call
                val waitSec = when {
                    ring > 0 && offhook > 0 -> ((offhook - ring) / 1000).toInt() // answered
                    ring > 0 -> ((now - ring) / 1000).toInt()                    // unanswered
                    else -> 0                                                     // outgoing
                }
                scope.launch { processFinishedCall(waitSec) }
            }
        }
    }

    // ── Capture + upload ─────────────────────────────────────────────────────
    private suspend fun processFinishedCall(waitSeconds: Int) {
        delay(CALLLOG_SETTLE_MS) // the CallLog row is written shortly after IDLE
        if (!hasCallLog()) return
        val entry = CallLogReader.readNewest(contentResolver) ?: return
        queue.enqueue(entry.externalId, CallLogReader.toJson(entry, waitSeconds))
        entry.externalId.toLongOrNull()?.let {
            if (it > prefs.lastCallLogId) prefs.lastCallLogId = it
        }
        flush()
    }

    private fun startLoop() {
        scope.launch {
            while (isActive) {
                reconcileFromCallLog()
                if (prefs.deviceKey.isNotEmpty()) api()?.heartbeat(BuildConfig.VERSION_NAME)
                flush()
                delay(TICK_MS)
            }
        }
    }

    /** Pick up calls that happened while the app/service was down. */
    private fun reconcileFromCallLog() {
        if (!hasCallLog()) return
        val newer = CallLogReader.readNewerThan(contentResolver, prefs.lastCallLogId)
        var maxId = prefs.lastCallLogId
        for (e in newer) {
            queue.enqueue(e.externalId, CallLogReader.toJson(e, 0)) // wait unknown for backfill
            e.externalId.toLongOrNull()?.let { if (it > maxId) maxId = it }
        }
        if (maxId > prefs.lastCallLogId) prefs.lastCallLogId = maxId
    }

    private fun flush() {
        val client = api() ?: return
        while (true) {
            val batch = queue.peekBatch(BATCH)
            if (batch.isEmpty()) return
            val arr = StringBuilder("[")
            batch.forEachIndexed { i, p ->
                if (i > 0) arr.append(',')
                arr.append(p.json)
            }
            arr.append(']')
            val ok = client.postCalls(arr.toString())
            if (!ok) return // offline / server error → keep queue, retry next tick
            queue.deleteIds(batch.map { it.id })
            if (batch.size < BATCH) return
        }
    }

    private fun api(): ApiClient? {
        if (!prefs.isConfigured) return null
        return ApiClient(prefs.serverUrl, prefs.deviceKey)
    }

    private fun hasCallLog(): Boolean =
        ContextCompat.checkSelfPermission(this, android.Manifest.permission.READ_CALL_LOG) ==
            PackageManager.PERMISSION_GRANTED
}
