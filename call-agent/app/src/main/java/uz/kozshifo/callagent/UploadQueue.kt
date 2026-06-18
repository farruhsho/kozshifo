package uz.kozshifo.callagent

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/** A row waiting to be uploaded (its JSON is built once at enqueue time). */
data class PendingCall(val id: Long, val json: String)

/**
 * Durable, idempotent upload queue. Calls are stored as ready-to-send JSON and
 * deleted only after the server acknowledges them — so a crash / dead battery /
 * offline window never loses a call. `external_id` is UNIQUE, so the live
 * listener and the CallLog reconcile pass can both try to enqueue the same call
 * without duplicating it.
 */
class UploadQueue(context: Context) :
    SQLiteOpenHelper(context.applicationContext, "callagent.db", null, 1) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "CREATE TABLE pending (" +
                "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
                "external_id TEXT UNIQUE, " +
                "json TEXT NOT NULL, " +
                "created_at INTEGER NOT NULL)"
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // v1 only — nothing to migrate yet.
    }

    /** Returns true if it was newly inserted (false = already queued). */
    fun enqueue(externalId: String, json: String): Boolean {
        val values = ContentValues().apply {
            put("external_id", externalId)
            put("json", json)
            put("created_at", System.currentTimeMillis())
        }
        val rowId = writableDatabase.insertWithOnConflict(
            "pending", null, values, SQLiteDatabase.CONFLICT_IGNORE
        )
        return rowId != -1L
    }

    fun peekBatch(limit: Int): List<PendingCall> {
        val out = ArrayList<PendingCall>()
        readableDatabase.query(
            "pending", arrayOf("id", "json"), null, null, null, null, "id ASC", limit.toString()
        ).use { c ->
            while (c.moveToNext()) out.add(PendingCall(c.getLong(0), c.getString(1)))
        }
        return out
    }

    fun deleteIds(ids: List<Long>) {
        if (ids.isEmpty()) return
        val placeholders = ids.joinToString(",") { "?" }
        writableDatabase.delete(
            "pending", "id IN ($placeholders)", ids.map { it.toString() }.toTypedArray()
        )
    }

    fun size(): Int {
        readableDatabase.rawQuery("SELECT COUNT(*) FROM pending", null).use { c ->
            return if (c.moveToFirst()) c.getInt(0) else 0
        }
    }
}
