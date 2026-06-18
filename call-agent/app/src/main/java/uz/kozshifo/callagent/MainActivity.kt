package uz.kozshifo.callagent

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat

/**
 * Setup screen: paste the server URL + device key (from the director's dialog),
 * grant permissions, and start/stop the monitor. No third-party UI deps — plain
 * Activity + framework views.
 */
class MainActivity : Activity() {

    private lateinit var prefs: Prefs
    private lateinit var etServer: EditText
    private lateinit var etKey: EditText
    private lateinit var tvStatus: TextView

    private val requiredPermissions: Array<String>
        get() = buildList {
            add(Manifest.permission.READ_PHONE_STATE)
            add(Manifest.permission.READ_CALL_LOG)
            if (Build.VERSION.SDK_INT >= 33) add(Manifest.permission.POST_NOTIFICATIONS)
        }.toTypedArray()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        prefs = Prefs(this)

        etServer = findViewById(R.id.etServer)
        etKey = findViewById(R.id.etKey)
        tvStatus = findViewById(R.id.tvStatus)
        etServer.setText(prefs.serverUrl)
        etKey.setText(prefs.deviceKey)

        findViewById<Button>(R.id.btnPerms).setOnClickListener { requestPerms() }
        findViewById<Button>(R.id.btnBattery).setOnClickListener { requestIgnoreBattery() }
        findViewById<Button>(R.id.btnStart).setOnClickListener { saveAndStart() }
        findViewById<Button>(R.id.btnStop).setOnClickListener { stop() }
    }

    override fun onResume() {
        super.onResume()
        refreshStatus()
    }

    private fun saveAndStart() {
        val url = etServer.text.toString().trim()
        val key = etKey.text.toString().trim()
        if (url.isEmpty() || key.isEmpty()) {
            toast(getString(R.string.fill_both))
            return
        }
        prefs.serverUrl = url
        prefs.deviceKey = key
        if (!hasAllPermissions()) {
            requestPerms()
            return
        }
        prefs.enabled = true
        CallMonitorService.start(this)
        toast(getString(R.string.started))
        refreshStatus()
    }

    private fun stop() {
        prefs.enabled = false
        CallMonitorService.stop(this)
        toast(getString(R.string.stopped))
        refreshStatus()
    }

    private fun requestPerms() {
        requestPermissions(requiredPermissions, 1)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (hasAllPermissions() && prefs.isConfigured) {
            prefs.enabled = true
            CallMonitorService.start(this)
        }
        refreshStatus()
    }

    @SuppressLint("BatteryLife")
    private fun requestIgnoreBattery() {
        val pm = getSystemService(PowerManager::class.java)
        if (pm.isIgnoringBatteryOptimizations(packageName)) {
            toast(getString(R.string.battery_ok))
            return
        }
        startActivity(
            Intent(
                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:$packageName")
            )
        )
    }

    private fun hasAllPermissions(): Boolean = requiredPermissions.all {
        ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
    }

    private fun refreshStatus() {
        val pm = getSystemService(PowerManager::class.java)
        val battery = pm.isIgnoringBatteryOptimizations(packageName)
        val lines = listOf(
            statusLine(getString(R.string.st_perms), hasAllPermissions()),
            statusLine(getString(R.string.st_battery), battery),
            statusLine(getString(R.string.st_running), prefs.enabled),
        )
        tvStatus.text = lines.joinToString("\n")
    }

    private fun statusLine(label: String, ok: Boolean) = "${if (ok) "✓" else "✗"}  $label"

    private fun toast(msg: String) = Toast.makeText(this, msg, Toast.LENGTH_SHORT).show()
}
