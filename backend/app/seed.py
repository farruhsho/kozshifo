"""Idempotent seed: permissions, starter roles, default branch, director, demo services.

Safe to run repeatedly (on every startup) — it upserts by natural keys and never
duplicates. The director bootstrap account is the system owner.
"""
from __future__ import annotations

from datetime import date
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import SessionLocal
from app.core.permissions import PERMISSIONS, ROLE_TEMPLATES
from app.core.security import hash_password
from app.models.branch import Branch
from app.models.catalog import Service, ServiceCategory
from app.models.device import Device
from app.models.inventory import InventoryCategory, Product, Supplier
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


# The clinic's two real instruments (docs/DOMAIN.md §1) — idempotent by serial_no.
_REAL_DEVICES: list[dict] = [
    {
        "name": "Авторефрактометр Supore RMK-700",
        "device_type": "refractometer",
        "model": "RMK-700",
        "manufacturer": "Shanghai Supore Instruments Co., Ltd",
        "serial_no": "2103540749",
        "asset_code": "CP-RMK-700A00749",
        "connection_type": "manual",
        "status": "active",
        "address": "No.800, Yeji Road, Shanghai, China",
        "useful_life_years": 10,
    },
    {
        "name": "Офтальмологический A/B УЗ-сканер CAS-2000BER",
        "device_type": "ab_ultrasound",
        "model": "CAS-2000BER",
        "manufacturer": "Chongqing Kanghuaruiming S&T Co., Ltd",
        "serial_no": "53789467",  # last digit partly obscured on the plate — verify
        "connection_type": "file",
        "status": "active",
        "manufacture_date": date(2019, 3, 1),
        "eu_rep": "LUXUS LEBENSWELT GMBH — Kochstr. 1, 47877, Willich, Germany",
        "address": "No.5, Road 1, TongJiaXi Industry Park, Beibei, Chongqing, China",
    },
]


def _seed_devices(db: Session, branch: Branch) -> None:
    for spec in _REAL_DEVICES:
        existing = db.execute(
            select(Device).where(Device.serial_no == spec["serial_no"])
        ).scalar_one_or_none()
        if existing is None:
            db.add(Device(branch_id=branch.id, **spec))
    db.flush()


# Warehouse starter data. SKUs are stable contracts — operation templates and
# tests reference them. No stock batches are seeded: stock arrives via receipts.
_INVENTORY_PRODUCTS: list[tuple[str, str, str, str, Decimal, str]] = [
    # (sku, name, product_type, unit, min_stock, category)
    ("VISC-001", "Вискоэластик (метилцеллюлоза) 1 мл", "consumable", "шт", Decimal("10"), "Расходные материалы"),
    ("IOL-001", "ИОЛ моноблочная акриловая", "material", "шт", Decimal("5"), "Расходные материалы"),
    ("KNIFE-275", "Нож офтальмологический 2.75 мм", "instrument", "шт", Decimal("5"), "Инструменты"),
    ("SYR-1", "Шприц 1 мл", "consumable", "шт", Decimal("50"), "Расходные материалы"),
    ("GLOVES-ST", "Перчатки стерильные (пара)", "consumable", "пара", Decimal("50"), "Расходные материалы"),
]


def _seed_inventory(db: Session) -> None:
    categories: dict[str, InventoryCategory] = {}
    for name in ("Расходные материалы", "Лекарства", "Инструменты"):
        category = db.execute(
            select(InventoryCategory).where(InventoryCategory.name == name)
        ).scalar_one_or_none()
        if category is None:
            category = InventoryCategory(name=name)
            db.add(category)
        categories[name] = category
    db.flush()

    supplier_name = "ООО MedSupply Tashkent"
    if db.execute(select(Supplier).where(Supplier.name == supplier_name)).scalar_one_or_none() is None:
        db.add(Supplier(name=supplier_name, phone="+998 71 200 00 00", address="Toshkent"))

    for sku, name, product_type, unit, min_stock, category_name in _INVENTORY_PRODUCTS:
        if db.execute(select(Product).where(Product.sku == sku)).scalar_one_or_none() is None:
            db.add(Product(
                sku=sku, name=name, product_type=product_type, unit=unit,
                min_stock=min_stock, category_id=categories[category_name].id,
            ))
    db.flush()


def run_seed() -> None:
    db = SessionLocal()
    try:
        perms = _seed_permissions(db)
        roles = _seed_roles(db, perms)
        branch = _seed_branch(db)
        _seed_director(db, branch, roles)
        _seed_services(db)
        _seed_devices(db, branch)
        _seed_inventory(db)
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    from app.core.database import create_all

    create_all()
    run_seed()
    print("Seed complete.")
