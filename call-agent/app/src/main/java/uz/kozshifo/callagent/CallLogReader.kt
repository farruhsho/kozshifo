package uz.kozshifo.callagent

import android.content.ContentResolver
import android.provider.CallLog
import org.json.JSONObject
import java.time.Instant

/** A finished call as read from the system CallLog. */
data class CallEntry(
    val externalId: String,   // CallLog._ID — the idempotency key
    val phone: String,
    val status: String,       // answered | missed | rejected | outgoing
    val direction: String,    // in | out
    val startedAtMs: Long,
    val durationSec: Int,
)

object CallLogReader {

    private val COLUMNS = arrayOf(
        CallLog.Calls._ID,
        CallLog.Calls.NUMBER,
        CallLog.Calls.TYPE,
        CallLog.Calls.DATE,
        CallLog.Calls.DURATION,
    )

    /** The most recent call (used right after a call ends). */
    fun readNewest(resolver: ContentResolver): CallEntry? {
        resolver.query(
            CallLog.Calls.CONTENT_URI, COLUMNS, null, null,
            "${CallLog.Calls.DATE} DESC"
        )?.use { c -> if (c.moveToFirst()) return parse(c) }
        return null
    }

    /** Calls with _ID greater than [lastId], oldest first (reconcile pass). */
    fun readNewerThan(resolver: ContentResolver, lastId: Long): List<CallEntry> {
        val out = ArrayList<CallEntry>()
        resolver.query(
            CallLog.Calls.CONTENT_URI, COLUMNS,
            "${CallLog.Calls._ID} > ?", arrayOf(lastId.toString()),
            "${CallLog.Calls._ID} ASC"
        )?.use { c -> while (c.moveToNext()) out.add(parse(c)) }
        return out
    }

    /** The current max _ID — used to start fresh on first run (no backfill). */
    fun maxId(resolver: ContentResolver): Long {
        resolver.query(
            CallLog.Calls.CONTENT_URI, arrayOf(CallLog.Calls._ID), null, null,
            "${CallLog.Calls._ID} DESC"
        )?.use { c -> if (c.moveToFirst()) return c.getLong(0) }
        return -1L
    }

    private fun parse(c: android.database.Cursor): CallEntry {
        val id = c.getLong(c.getColumnIndexOrThrow(CallLog.Calls._ID))
        val number = c.getString(c.getColumnIndexOrThrow(CallLog.Calls.NUMBER)) ?: ""
        val type = c.getInt(c.getColumnIndexOrThrow(CallLog.Calls.TYPE))
        val date = c.getLong(c.getColumnIndexOrThrow(CallLog.Calls.DATE))
        val duration = c.getInt(c.getColumnIndexOrThrow(CallLog.Calls.DURATION))
        return CallEntry(
            externalId = id.toString(),
            phone = number,
            status = statusFor(type),
            direction = if (type == CallLog.Calls.OUTGOING_TYPE) "out" else "in",
            startedAtMs = date,
            durationSec = duration,
        )
    }

    private fun statusFor(type: Int): String = when (type) {
        CallLog.Calls.INCOMING_TYPE -> "answered"
        CallLog.Calls.OUTGOING_TYPE -> "outgoing"
        CallLog.Calls.MISSED_TYPE -> "missed"
        CallLog.Calls.REJECTED_TYPE -> "rejected"
        else -> "missed" // VOICEMAIL / BLOCKED / unknown → treat as unanswered
    }

    /** Build the `/calls/agent/ingest` item, attaching the live-measured wait. */
    fun toJson(entry: CallEntry, waitSeconds: Int): String {
        val startIso = Instant.ofEpochMilli(entry.startedAtMs).toString()
        val endIso = Instant.ofEpochMilli(
            entry.startedAtMs + entry.durationSec * 1000L
        ).toString()
        return JSONObject().apply {
            put("external_id", entry.externalId)
            put("direction", entry.direction)
            put("status", entry.status)
            put("phone", if (entry.phone.isNotEmpty()) entry.phone else "unknown")
            put("started_at", startIso)
            put("ended_at", endIso)
            put("wait_seconds", waitSeconds.coerceAtLeast(0))
            put("duration_seconds", entry.durationSec.coerceAtLeast(0))
        }.toString()
    }
}
