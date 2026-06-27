"""Lightweight in-process monitoring (Super Admin → системный мониторинг).

Single-process, in-memory: «online now» last-seen, recent slow requests and
recent server errors, plus process uptime. It resets on restart and is NOT
shared across worker processes — fine for a single clinic-server deployment; for
multi-process scale move these to Redis. Login HISTORY is persisted separately
(models.UserSession), not here, so it survives restarts.
"""
from __future__ import annotations

import time
from collections import deque
from datetime import datetime, timezone
from uuid import UUID

# Process start → uptime.
_STARTED_AT = datetime.now(timezone.utc)

# user_id -> last-seen epoch seconds, written on every authenticated request
# (O(1) dict assignment, no I/O — safe on the hot path).
_LAST_SEEN: dict[UUID, float] = {}

# Recent slow requests / server errors (bounded ring buffers).
_SLOW: deque[dict] = deque(maxlen=50)
_ERRORS: deque[dict] = deque(maxlen=50)

ONLINE_WINDOW_S = 5 * 60   # a user is "online" if seen within this window
SLOW_MS = 1000.0           # a request slower than this is "slow"


def touch_user(user_id: UUID) -> None:
    """Mark a user active now (called from the auth dependency)."""
    _LAST_SEEN[user_id] = time.time()


def online_user_ids(window_s: int = ONLINE_WINDOW_S) -> set[UUID]:
    cutoff = time.time() - window_s
    return {uid for uid, ts in _LAST_SEEN.items() if ts >= cutoff}


def record_request(method: str, path: str, status_code: int, duration_ms: float) -> None:
    """Called by the monitoring middleware for every request."""
    if duration_ms >= SLOW_MS:
        _SLOW.append({
            "at": datetime.now(timezone.utc).isoformat(),
            "method": method, "path": path,
            "duration_ms": round(duration_ms, 1), "status": status_code,
        })
    if status_code >= 500:
        _ERRORS.append({
            "at": datetime.now(timezone.utc).isoformat(),
            "method": method, "path": path, "status": status_code,
        })


def recent_slow() -> list[dict]:
    return list(_SLOW)[::-1]   # newest first


def recent_errors() -> list[dict]:
    return list(_ERRORS)[::-1]


def uptime_seconds() -> float:
    return (datetime.now(timezone.utc) - _STARTED_AT).total_seconds()
