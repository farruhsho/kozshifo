package uz.kozshifo.callagent

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Restart the monitor after a reboot or an app update, if the user enabled it. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val prefs = Prefs(context)
        if (prefs.enabled && prefs.isConfigured) {
            CallMonitorService.start(context)
        }
    }
}
