"""Audit trail helper — records who did what, to which entity, when.

Per the platform spec, every meaningful mutation (create / update / delete /
payment / refund / permission change / login …) is logged. Services call
`record_audit(...)` inside the same transaction so the audit row commits
atomically with the change it describes.
"""
from __future__ import annotations

import contextvars
from typing import Any
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.audit import AuditLog

# Per-request client context (ip + user-agent), set by the audit middleware so
# EVERY mutation's audit row records «с какого устройства» — not just login.
# A ContextVar is request-scoped and is copied into the threadpool that runs
# sync endpoints, so record_audit (called deep in sync services) still sees it.
_request_ctx: contextvars.ContextVar[dict] = contextvars.ContextVar(
    "audit_request_ctx", default={}
)


def set_request_context(*, ip: str | None, user_agent: str | None) -> None:
    """Called once per HTTP request by the audit middleware (main.py)."""
    _request_ctx.set({"ip": ip, "user_agent": user_agent})


def record_audit(
    db: Session,
    *,
    action: str,
    entity_type: str,
    entity_id: UUID | str | None = None,
    actor_id: UUID | None = None,
    branch_id: UUID | None = None,
    summary: str | None = None,
    changes: dict[str, Any] | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
) -> AuditLog:
    ctx = _request_ctx.get()
    log = AuditLog(
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else None,
        actor_id=actor_id,
        branch_id=branch_id,
        summary=summary,
        changes=changes,
        # Explicit args win; otherwise fall back to the request context so the
        # device/IP is captured uniformly across all call sites.
        ip_address=ip_address or ctx.get("ip"),
        user_agent=user_agent or ctx.get("user_agent"),
    )
    db.add(log)
    return log
