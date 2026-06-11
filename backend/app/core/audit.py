"""Audit trail helper — records who did what, to which entity, when.

Per the platform spec, every meaningful mutation (create / update / delete /
payment / refund / permission change / login …) is logged. Services call
`record_audit(...)` inside the same transaction so the audit row commits
atomically with the change it describes.
"""
from __future__ import annotations

from typing import Any
from uuid import UUID

from sqlalchemy.orm import Session

from app.models.audit import AuditLog


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
) -> AuditLog:
    log = AuditLog(
        action=action,
        entity_type=entity_type,
        entity_id=str(entity_id) if entity_id is not None else None,
        actor_id=actor_id,
        branch_id=branch_id,
        summary=summary,
        changes=changes,
        ip_address=ip_address,
    )
    db.add(log)
    return log
