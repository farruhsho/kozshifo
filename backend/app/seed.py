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
from app.models.cabinet import Cabinet
from app.models.catalog import Service, ServiceCategory
from app.models.device import Device
from app.models.diagnosis import Diagnosis
from app.models.finance import ExpenseCategory
from app.models.inventory import InventoryCategory, Product, Supplier
from app.models.operation import OperationType, OperationTypeConsumable
from app.models.rbac import Permission, Role
from app.models.user import User

# (code, name, price, is_diagnostic). Diagnostic services route to a diagnostician
# queue ticket; the consultation goes straight to the doctor track.
_DEMO_SERVICES = [
    ("CONS", "Консультация офтальмолога", 150000, False),
    ("ARM", "Авторефрактометрия", 50000, True),
    ("TONO", "Тонометрия", 40000, True),
    ("BIO", "Биомикроскопия", 60000, True),
    ("OCT", "ОКТ сетчатки", 250000, True),
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


# Roles folded into the single Administrator seat → where their existing users go.
_RETIRED_ROLE_MIGRATION: dict[str, str] = {
    "Reception": "Administrator",
    "Cashier": "Administrator",
    "Warehouse": "Administrator",
}


def _retire_obsolete_roles(db: Session, roles: dict[str, Role]) -> None:
    """Delete seeded system roles no longer in ROLE_TEMPLATES, first moving any
    users holding them onto the replacement role so nobody is left role-less."""
    obsolete = (
        db.execute(
            select(Role).where(
                Role.name.not_in(list(ROLE_TEMPLATES.keys())),
                Role.is_system.is_(True),
            )
        )
        .scalars()
        .all()
    )
    for role in obsolete:
        target = roles.get(_RETIRED_ROLE_MIGRATION.get(role.name, ""))
        for user in list(role.users):
            kept = [r for r in user.roles if r.id != role.id]
            if target is not None and target not in kept:
                kept.append(target)
            user.roles = kept
        db.delete(role)
    db.flush()


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
            # NOT a superuser: the Director sees everything but cannot change
            # system settings — only the Super Admin (owner) is is_superuser.
            is_superuser=False,
            branch_id=branch.id,
        )
        director.roles = [roles["Director"]]
        db.add(director)
        db.flush()
    else:
        # Enforce the policy on every startup: an existing director (incl. one
        # created before this change) must NOT retain owner-tier bypass.
        director.is_superuser = False
        director.roles = [roles["Director"]]
        if settings.seed_demo_staff:
            # Keep the password in sync so the quick-login «Директор» button works.
            director.hashed_password = hash_password(settings.seed_director_password)
        db.flush()


# Demo staff — ONE account per role for trying the system. DEV ONLY: these
# well-known passwords must never exist in production (there the owner creates
# staff through the /admin screen with real passwords).
#
# The front office is ONE seat — the Administrator (reception@) covers ресепшен
# + касса + склад, so there are no separate касса/склад quick-login buttons.
# The Superadmin account is the owner's god-account (is_superuser) for observing
# and managing everything.
_DEMO_STAFF: list[tuple[str, str, str, str, bool]] = [
    # (email, full_name, password, role, is_superuser)
    ("superadmin@kozshifo.uz", "Суперадмин (владелец)", "Superadmin!2026", "Superadmin", True),
    ("vrach@kozshifo.uz", "Доктор Исмоилов А.А.", "Vrach!2026", "Doctor", False),
    ("reception@kozshifo.uz", "Администратор Юлдашева Н.", "Reception!2026", "Administrator", False),
    ("diagnost@kozshifo.uz", "Диагност Рахимова М.", "Diagnost!2026", "Diagnost", False),
    ("treatment@kozshifo.uz", "Процедурная м/с Ким О.", "Treatment!2026", "TreatmentRoom", False),
]


def _seed_demo_staff(db: Session, branch: Branch, roles: dict[str, Role]) -> None:
    # Demo accounts power the one-click quick-login buttons. They are seeded in
    # ANY environment while SEED_DEMO_STAFF is on, and the well-known password is
    # made AUTHORITATIVE (reset on every startup) so the buttons always work even
    # if an account already exists with a different/randomized password.
    if not settings.seed_demo_staff:
        return
    for email, full_name, password, role_name, is_superuser in _DEMO_STAFF:
        user = db.execute(select(User).where(User.email == email)).scalar_one_or_none()
        if user is None:
            user = User(email=email, branch_id=branch.id)
            db.add(user)
        user.full_name = full_name
        user.hashed_password = hash_password(password)
        user.is_superuser = is_superuser
        user.roles = [roles[role_name]]
        if user.branch_id is None:
            user.branch_id = branch.id
    db.flush()


# Default consulting rooms (Кабинеты) for the main branch — the Super Admin can
# add/rename more at runtime. Idempotent by (branch, name).
_DEFAULT_CABINETS: list[tuple[str, str | None]] = [
    ("Кабинет №1", None),
    ("Кабинет №2", None),
    ("Кабинет УЗИ", "УЗИ"),
    ("Кабинет ЭКГ", "ЭКГ"),
    ("Процедурный кабинет", "процедурный"),
    ("Операционная №1", "операционная"),
]


def _seed_cabinets(db: Session, branch: Branch) -> None:
    for name, kind in _DEFAULT_CABINETS:
        exists = db.execute(
            select(Cabinet).where(Cabinet.branch_id == branch.id, Cabinet.name == name)
        ).scalar_one_or_none()
        if exists is None:
            db.add(Cabinet(branch_id=branch.id, name=name, kind=kind))
    db.flush()


def _seed_services(db: Session) -> None:
    category = db.execute(
        select(ServiceCategory).where(ServiceCategory.name == "Диагностика")
    ).scalar_one_or_none()
    if category is None:
        category = ServiceCategory(name="Диагностика", description="Диагностические услуги")
        db.add(category)
        db.flush()
    for code, name, price, is_diagnostic in _DEMO_SERVICES:
        if db.execute(select(Service).where(Service.code == code)).scalar_one_or_none() is None:
            db.add(Service(code=code, name=name, price=Decimal(price),
                           category_id=category.id, is_diagnostic=is_diagnostic))
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


# Surgery catalog. Operation prices live on the linked Service (single pricing
# source); consumable templates reference warehouse products by stable SKU.
_OPERATION_SERVICES = [
    ("PHACO", "Факоэмульсификация катаракты с ИОЛ", 5000000),
    ("IVI", "Интравитреальная инъекция", 1500000),
]

# (code, name, service_code, duration_minutes, [(sku, qty), ...])
_OPERATION_TYPES: list[tuple[str, str, str, int, list[tuple[str, int]]]] = [
    ("PHACO", "Факоэмульсификация катаракты с ИОЛ", "PHACO", 40,
     [("IOL-001", 1), ("VISC-001", 1), ("KNIFE-275", 1), ("SYR-1", 2), ("GLOVES-ST", 3)]),
    ("IVI", "Интравитреальная инъекция", "IVI", 15,
     [("SYR-1", 1), ("GLOVES-ST", 2)]),
]


def _seed_operations(db: Session) -> None:
    """Idempotent by code. Must run AFTER _seed_inventory (SKU lookups)."""
    category = db.execute(
        select(ServiceCategory).where(ServiceCategory.name == "Операции")
    ).scalar_one_or_none()
    if category is None:
        category = ServiceCategory(name="Операции", description="Хирургические операции")
        db.add(category)
        db.flush()
    for code, name, price in _OPERATION_SERVICES:
        if db.execute(select(Service).where(Service.code == code)).scalar_one_or_none() is None:
            db.add(Service(code=code, name=name, price=Decimal(price), category_id=category.id))
    db.flush()

    for code, name, service_code, duration, consumables in _OPERATION_TYPES:
        if db.execute(select(OperationType).where(OperationType.code == code)).scalar_one_or_none():
            continue
        service = db.execute(select(Service).where(Service.code == service_code)).scalar_one()
        op_type = OperationType(
            code=code, name=name, service_id=service.id, duration_minutes=duration,
        )
        for sku, qty in consumables:
            product = db.execute(select(Product).where(Product.sku == sku)).scalar_one()
            op_type.consumables.append(
                OperationTypeConsumable(product_id=product.id, quantity=Decimal(qty))
            )
        db.add(op_type)
    db.flush()


# Starter diagnosis / conclusion catalog (справочник заключений). Idempotent by
# code. (code, name, category, icd10) — heavy on УЗИ conclusions so a УЗИ-диагност
# has a ready picker.
_DEMO_DIAGNOSES: list[tuple[str, str, str, str | None]] = [
    ("UZI-NORM", "УЗИ: без патологии", "УЗИ", None),
    ("UZI-PVD", "УЗИ: задняя отслойка стекловидного тела", "УЗИ", None),
    ("UZI-RD", "УЗИ: отслойка сетчатки", "УЗИ", "H33.0"),
    ("UZI-VH", "УЗИ: гемофтальм", "УЗИ", "H43.1"),
    ("CATARACT", "Катаракта", "Диагноз", "H25"),
    ("GLAUCOMA", "Глаукома", "Диагноз", "H40"),
    ("DR", "Диабетическая ретинопатия", "Диагноз", "H36.0"),
]


def _seed_diagnoses(db: Session) -> None:
    for code, name, category, icd10 in _DEMO_DIAGNOSES:
        if db.execute(select(Diagnosis).where(Diagnosis.code == code)).scalar_one_or_none() is None:
            db.add(Diagnosis(code=code, name=name, category=category, icd10=icd10))
    db.flush()


# Default expense types (rasxod turlari). «Зарплата» is a system type — payroll
# payouts book against it — so it can be deactivated but never deleted.
_DEFAULT_EXPENSE_CATEGORIES = [
    ("Аренда", False),
    ("Зарплата", True),
    ("Коммунальные", False),
    ("Расходники", False),
    ("Реклама", False),
    ("Налоги", False),
    ("Прочее", False),
]


def _seed_expense_categories(db: Session) -> None:
    for order, (name, is_system) in enumerate(_DEFAULT_EXPENSE_CATEGORIES):
        if db.execute(
            select(ExpenseCategory).where(ExpenseCategory.name == name)
        ).scalar_one_or_none() is None:
            db.add(ExpenseCategory(name=name, is_system=is_system, sort_order=order))
    db.flush()


def run_seed() -> None:
    db = SessionLocal()
    try:
        perms = _seed_permissions(db)
        roles = _seed_roles(db, perms)
        _retire_obsolete_roles(db, roles)
        branch = _seed_branch(db)
        _seed_director(db, branch, roles)
        _seed_demo_staff(db, branch, roles)
        _seed_cabinets(db, branch)
        _seed_services(db)
        _seed_devices(db, branch)
        _seed_inventory(db)
        _seed_operations(db)
        _seed_diagnoses(db)
        _seed_expense_categories(db)
        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    from app.core.database import create_all

    create_all()
    run_seed()
    print("Seed complete.")
