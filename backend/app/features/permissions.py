"""Read-only permission catalog endpoint."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.deps import require_permission
from app.models.rbac import Permission
from app.schemas.rbac import PermissionOut

router = APIRouter(prefix="/permissions", tags=["Identity & Access"])


@router.get("", response_model=list[PermissionOut], dependencies=[Depends(require_permission("permissions.read"))])
def list_permissions(db: Annotated[Session, Depends(get_db)]) -> list[Permission]:
    return list(db.execute(select(Permission).order_by(Permission.module, Permission.code)).scalars().all())
