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
from app.schemas.catalog import (
    ServiceCategoryCreate,
    ServiceCategoryOut,
    ServiceCreate,
    ServiceOut,
    ServiceUpdate,
)
from app.schemas.common import Page

router = APIRouter(tags=["Catalog"])


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


@router.post("/services", response_model=ServiceOut, status_code=status.HTTP_201_CREATED)
def create_service(
    payload: ServiceCreate,
    db: Annotated[Session, Depends(get_db)],
    actor: Annotated[CurrentUser, Depends(require_permission("services.create"))],
) -> Service:
    if db.execute(select(Service).where(Service.code == payload.code)).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, "Service code already exists")
    service = Service(**payload.model_dump())
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
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(service, field, value)
    record_audit(db, action="update", entity_type="service", entity_id=service.id, actor_id=actor.id,
                 summary=f"Updated service {service.code}")
    db.commit()
    db.refresh(service)
    return service
