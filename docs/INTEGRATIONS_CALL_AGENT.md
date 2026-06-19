# Integration design — Android reception-phone call agent → call monitoring

Technical contract for a small **Android app on each reception phone** that
reports every finished call (incoming / outgoing / missed / rejected), the ring
time before pickup and a liveness heartbeat — so the **director** can watch, in
near-real-time (~1 min), whether the front desk answers patient calls on time.

> **Status: backend + director UI are built; the Android agent is not.**
> This document is the contract the agent must satisfy. The backend side
> (`app/features/calls.py`, `app/models/call.py`, migration `f1ca11d09e10`) and
> the Flutter director screens (`lib/features/calls/`) already implement
> everything described here on the server.

---

## 1. Confirmed decisions

| Decision | Choice | Consequence |
|----------|--------|-------------|
| **Topology** | One agent app per reception Android phone; many phones, several branches | Each phone is a `call_devices` row with its **own** key. |
| **Recording** | **Metrics only, no audio** | Android 10+ blocks call recording reliably; we capture status + timing, not audio. If recording is ever required → migrate to a PBX/SIP (the same `call_records` table accepts the PBX path). |
| **Distribution** | **Sideloaded APK** (not Google Play) | `READ_CALL_LOG` / `READ_PHONE_STATE` are restricted on Play but free for an internally-distributed app. |
| **Auth** | Per-device key in the `X-Device-Key` header | Director issues a key per phone; revoke/rotate without touching others. |
| **Transport** | HTTPS POST, JSON, **batched + idempotent** | Survives flaky mobile data; a resend never double-counts. |
| **Real-time** | Push on call-end + heartbeat ~every 60s; director UI polls every 60s | Meets the "~1 min is fine" requirement without WebSockets. |

---

## 2. Backend endpoints (already implemented)

Base URL: the value shown in the director's "Адрес сервера" field
(`<server>/api/v1`). All agent calls send header `X-Device-Key: <device key>`.

### 2.1 Upload calls — `POST /calls/agent/ingest`

Body is a **JSON array** of finished calls (batch). Idempotent per
`(device, external_id)`.

```jsonc
[
  {
    "external_id": "9912834",          // the phone's own CallLog._ID (string) — idempotency key
    "direction": "in",                  // "in" | "out"
    "status": "answered",               // "answered" | "missed" | "rejected" | "outgoing"
    "phone": "+998 90 222 33 44",
    "started_at": "2026-06-18T08:30:11Z",
    "ended_at":   "2026-06-18T08:31:40Z", // optional
    "wait_seconds": 8,                  // RINGING → OFFHOOK (answered) or RINGING → IDLE (missed)
    "duration_seconds": 89,             // talk time
    "note": null
  }
]
```

Response: `{ "received": N, "ingested": M, "duplicates": K }`. The agent **drops
locally** only the calls confirmed by a 2xx response (received == ingested +
duplicates); duplicates are safe to drop too.

Timestamps: send UTC (`Z`). A naive timestamp is taken as UTC by contract.

### 2.2 Heartbeat — `POST /calls/agent/heartbeat`

```jsonc
{ "app_version": "1.0.0" }   // optional
```

Response: `{ "ok": true, "server_time": "2026-06-18T08:35:00Z" }`. Send ~every
60s. The server bumps `last_seen_at`; if it goes stale beyond
`CALL_DEVICE_OFFLINE_MINUTES` (default 5) **during working hours**, the director
gets an "офлайн" banner on the Звонки screen and a critical dashboard insight
(Telegram if configured).

Auth failures on either endpoint return **401** (missing/invalid/inactive key).

---

## 3. Agent behaviour (what to build, Kotlin)

1. **Foreground service** + request battery-optimization exemption — Android must
   not kill the listener. Show a persistent low-priority notification.
2. **Live capture** via `TelephonyManager` (`TelephonyCallback` on API 31+, else
   `PhoneStateListener`): record the transition timestamps
   `RINGING → OFFHOOK → IDLE` to derive `status` and `wait_seconds`:
   - `RINGING` then `OFFHOOK` then `IDLE` → **answered** (wait = OFFHOOK−RINGING,
     duration = IDLE−OFFHOOK).
   - `RINGING` then `IDLE` (no OFFHOOK) → **missed** (incoming) (wait = IDLE−RINGING).
   - outgoing `OFFHOOK` then `IDLE` → **outgoing**.
   - user-declined → **rejected** (incoming `OFFHOOK` never reached + telephony hint).
3. **Reconcile from `CallLog`** on start/foreground (catches calls missed while
   the app was down). Use `CallLog.Calls._ID` as `external_id`; map
   `CallLog.Calls.TYPE` → status (`MISSED_TYPE`→missed, `REJECTED_TYPE`→rejected,
   `INCOMING_TYPE`→answered, `OUTGOING_TYPE`→outgoing). Note: CallLog gives talk
   `DURATION` but **not** ring-wait — prefer the live-captured `wait_seconds`,
   fall back to 0.
4. **Local queue** (Room/SQLite): enqueue every call; a worker (WorkManager) uploads
   batches; drop only on 2xx. Survives offline → online with one batched POST.
5. **Setup screen**: server URL + device key (paste from the director's dialog).
   Permissions requested: `READ_PHONE_STATE`, `READ_CALL_LOG`,
   `FOREGROUND_SERVICE`, `POST_NOTIFICATIONS`, `INTERNET`.

---

## 4. Director-side (already built)

- **Register phones**: Звонки screen → smartphone icon → "Телефоны ресепшена"
  (`/calls/devices`, permission `calls.manage`). Creating a phone shows the
  server URL + key **once**; "Сменить ключ" rotates it.
- **Monitor**: Звонки screen shows KPI cards (отвечено / пропущено % / среднее
  время ответа / исходящие), an offline-phones banner, and the live journal with
  per-call status, wait time and source phone. Auto-refreshes every 60s.
- **Summary API** for any embedding: `GET /calls/summary?date_from&date_to&branch_id`
  (`calls.read` or `dashboard.view`).

---

## 5. Out of scope (this slice)

Call recording/audio, SIP/softphone, IVR/queue routing, per-operator login on a
shared phone (calls attribute to the **phone**, not a user). All revisitable by
adding the PBX path later — `call_records` already carries both.
