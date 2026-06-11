"""Idempotent seed: permissions, starter roles, default branch, director, demo services.

Safe to run repeatedly (on every startup) — it upserts by natural keys and never
duplicates. The director bootstrap account is the system owner.
"""
from __future__ import annotations

from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import SessionLocal
from app.core.permissions import PERMISSIONS, ROLE_TEMPLATES
from app.core.security import hash_password
from app.models.branch import Branch
from app.models.catalog import Service, ServiceCategory
from app.models.rbac import Permission, Role
from app.models.user import User

_DEMO_SERVICES = [
    ("CONS", "Консультация офтальмолога", 150000),
    ("ARM", "Авторефрактометрия", 50000),
    ("TONO", "Тонометрия", 40000),
    ("BIO", "Биомикроскопия", 60000),
    ("OCT", "ОКТ сетчатки", 250000),
]


def _seed_permissions(db: Session) -> dict[str, Permission]:
    existing = {p.code: p for p in db.execute(select(Permission)).scalars().all()}
    for code, module, desc in PERMISSIONS:
        perm = existing.get(code)
        if perm is None:
            perm = Permission(code=code, module=module, description=desc)
            db.add(perm)
            existing[code] = perm
        else:
            perm.module, perm.description = module, desc
    db.flush()
    return existing


def _seed_roles(db: Session, perms: dict[str, Permission]) -> dict[str, Role]:
    roles: dict[str, Role] = {}
    for name, codes in ROLE_TEMPLATES.items():
        role = db.execute(select(Role).where(Role.name == name)).scalar_one_or_none()
        if role is None:
            role = Role(name=name, description=f"{name} (seeded)", is_system=True)
            db.add(role)
        role.permissions = [perms[c] for c in codes]
        roles[name] = role
    db.flush()
    return roles


def _seed_branch(db: Session) -> Branch:
    branch = db.execute(select(Branch).where(Branch.code == "MAIN")).scalar_one_or_none()
    if branch is None:
        branch = Branch(name="Главный филиал", code="MAIN", address="Toshkent", phone="+998 71 000 00 00")
        db.add(branch)
        db.flush()
    return branch


def _seed_director(db: Session, branch: Branch, roles: dict[str, Role]) -> None:
    director = db.execute(
        select(User).where(User.email == settings.seed_director_email)
    ).scalar_one_or_none()
    if director is None:
        director = User(
            email=settings.seed_director_email,
            full_name="Директор клиники",
            hashed_password=hash_password(settings.seed_director_password),
            is_superuser=True,
            branch_id=branch.id,
        )
        director.roles = [roles["Director"]]
        db.add(director)
        db.flush()


def _seed_services(db: Session) -> None:
    category = db.execute(
        select(ServiceCategory).where(ServiceCategory.name == "Диагностика")
    ).scalar_one_or_none()
    if category is None:
        category = ServiceCategory(name="Диагностика", description="Диагностические услуги")
        db.add(category)
        db.flush()
    for code, name, price in _DEMO_SERVICES:
        if db.execute(select(Service).where(Service.code == code)).scalar_one_or_none() is None:
            db.add(Service(code=code, name=name, price=Decimal(price), category_id=category.id))
    db.flush()


def run_seed() -> None:
    db = SessionLocal()
    try:
        perms = _seed_permissions(db)
        roles = _seed_roles(db, perms)
        branch = _seed_branch(db)
        _seed_director(db, branch, roles)
        _seed_services(db)
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    from app.core.database import create_all

    create_all()
    run_seed()
    print("Seed complete.")
