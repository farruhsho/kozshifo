"""Service catalog: categories and priced services."""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.database import get_db
from app.core.deps import CurrentUser, require_permission
from app.models.catalog import Service, ServiceCategory
from app.models.user import User
from app.schemas.catalog import (
    AssignableDoctorOut,
    ServiceCategoryCreate,
    ServiceCategoryOut,
    ServiceCreate,
    ServiceOut,
    ServiceUpdate,
)
from app.schemas.common import Page

router = APIRouter(tags=["Catalog"])


def _resolve_doctors(db: Session, ids: list[UUID]) -> list[User]:
    """Resolve a service's eligible-doctor ids (validated)."""
    if not ids:
        return []
    found = list(db.execute(select(User).where(User.id.in_(ids))).scalars().all())
    missing = set(ids) - {u.id for u in found}
    if missing:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY,
                            f"Unknown doctor ids: {sorted(map(str, missing))}")
    return found


# ── Categories ────────────────────────────────────────────────────────────────
@router.get("/service-categories", response_model=list[ServiceCategoryOut],
            dependencies=[Depends(require_permission("services.read"))])
def list_categories(db: Annotated[Session, Depends(get_db)]) -> list[ServiceCategory]:
    return list(db.execute(select(ServiceCategory).order_by(ServiceCategory.name)).scalars().all())


@router.post("/service-categories", response_model=ServiceCategoryOut, status_code=status.HTTP_201_CREATED)
def create_category(
    payload: ServiceCategoryCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("services.create"))],
) -> ServiceCategory:
    if db.execute(select(ServiceCategory).where(ServiceCategory.name == payload.name)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Category already exists")
    category = ServiceCategory(**payload.model_dump())
    db.add(category)
    db.flush()
    record_audit(db, action="create", entity_type="service_category", entity_id=category.id, actor_id=actor.id,
                 summary=f"Created category {category.name}")
    db.commit()
    db.refresh(category)
    return category


# ── Services ──────────────────────────────────────────────────────────────────
@router.get("/services", response_model=Page[ServiceOut],
            dependencies=[Depends(require_permission("services.read"))])
def list_services(
    db: Annotated[Session, Depends(get_db)],
    q: str | None = Query(None),
    offset: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
) -> Page[ServiceOut]:
    stmt = select(Service)
    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(Service.name.ilike(like) | Service.code.ilike(like))
    total = db.execute(select(func.count()).select_from(stmt.subquery())).scalar_one()
    rows = db.execute(stmt.order_by(Service.name).offset(offset).limit(limit)).scalars().all()
    return Page(items=[ServiceOut.model_validate(s) for s in rows], total=total, offset=offset, limit=limit)


@router.get(
    "/services/assignable-doctors",
    response_model=list[AssignableDoctorOut],
    dependencies=[Depends(require_permission("services.read"))],
)
def assignable_doctors(
    db: Annotated[Session, Depends(get_db)],
) -> list[AssignableDoctorOut]:
    """Staff selectable as a service's eligible doctors — for the service-form
    picker. Guarded by services.read (NOT users.read) so reception, who owns
    service CRUD, can list them without identity-module access. Inactive staff
    are included so an already-linked-but-deactivated doctor stays removable."""
    rows = db.execute(select(User).order_by(User.full_name)).scalars().all()
    return [
        AssignableDoctorOut(
            id=u.id,
            full_name=u.full_name,
            cabinet=u.cabinet,
            is_active=u.is_active,
            roles=[r.name for r in u.roles],
        )
        for u in rows
    ]


@router.post("/services", response_model=ServiceOut, status_code=status.HTTP_201_CREATED)
def create_service(
    payload: ServiceCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("services.create"))],
) -> Service:
    if db.execute(select(Service).where(Service.code == payload.code)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Service code already exists")
    data = payload.model_dump()
    doctor_ids = data.pop("doctor_ids", [])
    service = Service(**data)
    service.doctors = _resolve_doctors(db, doctor_ids)
    db.add(service)
    db.flush()
    record_audit(db, action="create", entity_type="service", entity_id=service.id, actor_id=actor.id,
                 summary=f"Created service {service.code} — {service.name}")
    db.commit()
    db.refresh(service)
    return service


@router.patch("/services/{service_id}", response_model=ServiceOut)
def update_service(
    service_id: UUID,
    payload: ServiceUpdate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("services.update"))],
) -> Service:
    service = db.get(Service, service_id)
    if service is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Service not found")
    data = payload.model_dump(exclude_unset=True)
    if "doctor_ids" in data:
        service.doctors = _resolve_doctors(db, data.pop("doctor_ids") or [])
    for field, value in data.items():
        setattr(service, field, value)
    record_audit(db, action="update", entity_type="service", entity_id=service.id, actor_id=actor.id,
                 summary=f"Updated service {service.code}")
    db.commit()
    db.refresh(service)
    return service
