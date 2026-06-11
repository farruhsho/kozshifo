"""Generic typed CRUD repository (Repository Pattern).

Each feature composes this with its ORM model to get consistent data access
without per-entity boilerplate, while keeping a clean seam between the service
layer and the persistence layer.
"""
from __future__ import annotations

from typing import Generic, TypeVar
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.database import Base

ModelT = TypeVar("ModelT", bound=Base)


class CRUDRepository(Generic[ModelT]):
    def __init__(self, model: type[ModelT]):
        self.model = model

    def get(self, db: Session, id: UUID) -> ModelT | None:
        return db.get(self.model, id)

    def list(self, db: Session, *, offset: int = 0, limit: int = 50, order_by=None) -> list[ModelT]:
        stmt = select(self.model)
        if order_by is not None:
            stmt = stmt.order_by(order_by)
        stmt = stmt.offset(offset).limit(limit)
        return list(db.execute(stmt).scalars().all())

    def count(self, db: Session) -> int:
        return db.execute(select(func.count()).select_from(self.model)).scalar_one()

    def add(self, db: Session, obj: ModelT) -> ModelT:
        db.add(obj)
        db.flush()  # populate PK / defaults without committing
        return obj

    def delete(self, db: Session, obj: ModelT) -> None:
        db.delete(obj)
        db.flush()
