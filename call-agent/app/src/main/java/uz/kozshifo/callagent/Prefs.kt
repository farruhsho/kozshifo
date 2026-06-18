package uz.kozshifo.callagent

import android.content.Context

/** Persisted config + the CallLog reconcile cursor. */
class Prefs(context: Context) {
    private val sp = context.getSharedPreferences("callagent", Context.MODE_PRIVATE)

    /** Server base, already including `/api/v1` (the URL the director copies). */
    var serverUrl: String
        get() = sp.getString("server_url", "") ?: ""
        set(v) = sp.edit().putString("server_url", v.trim()).apply()

    /** Per-device key (X-Device-Key). */
    var deviceKey: String
        get() = sp.getString("device_key", "") ?: ""
        set(v) = sp.edit().putString("device_key", v.trim()).apply()

    /** Whether the user enabled monitoring (so BootReceiver can auto-restart). */
    var enabled: Boolean
        get() = sp.getBoolean("enabled", false)
        set(v) = sp.edit().putBoolean("enabled", v).apply()

    /** Highest CallLog._ID already enqueued — reconcile only scans newer rows. */
    var lastCallLogId: Long
        get() = sp.getLong("last_call_log_id", -1L)
        set(v) = sp.edit().putLong("last_call_log_id", v).apply()

    val isConfigured: Boolean
        get() = serverUrl.isNotEmpty() && deviceKey.isNotEmpty()
}
