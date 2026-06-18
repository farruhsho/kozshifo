package uz.kozshifo.callagent

import java.io.BufferedReader
import java.net.HttpURLConnection
import java.net.URL

/**
 * Tiny HTTP client (no third-party deps) for the two agent endpoints. Both send
 * the per-device key in `X-Device-Key`. The base URL already ends in `/api/v1`
 * (the value the director copies from the "Адрес сервера" field).
 */
class ApiClient(private val baseUrl: String, private val deviceKey: String) {

    private fun endpoint(path: String): URL {
        val base = baseUrl.trimEnd('/')
        return URL("$base$path")
    }

    /** POST a JSON array of finished calls. Returns true on a 2xx. */
    fun postCalls(jsonArray: String): Boolean =
        post("/calls/agent/ingest", jsonArray)

    /** Liveness ping. Returns true on a 2xx. */
    fun heartbeat(appVersion: String): Boolean =
        post("/calls/agent/heartbeat", "{\"app_version\":\"$appVersion\"}")

    private fun post(path: String, body: String): Boolean {
        var conn: HttpURLConnection? = null
        return try {
            conn = (endpoint(path).openConnection() as HttpURLConnection).apply {
                requestMethod = "POST"
                connectTimeout = 10_000
                readTimeout = 15_000
                doOutput = true
                setRequestProperty("Content-Type", "application/json; charset=utf-8")
                setRequestProperty("Accept", "application/json")
                setRequestProperty("X-Device-Key", deviceKey)
            }
            conn.outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
            val code = conn.responseCode
            // Drain the body so the connection can be reused / closed cleanly.
            (if (code in 200..299) conn.inputStream else conn.errorStream)
                ?.bufferedReader()?.use(BufferedReader::readText)
            code in 200..299
        } catch (_: Exception) {
            false // network error — keep the queue, retry on the next tick
        } finally {
            conn?.disconnect()
        }
    }
}
