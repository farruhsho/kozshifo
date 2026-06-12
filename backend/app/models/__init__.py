"""Import all models so they register on Base.metadata (order-independent)."""
from app.models.audit import AuditLog
from app.models.branch import Branch
from app.models.catalog import Service, ServiceCategory
from app.models.device import Device, DeviceResult
from app.models.exam import EyeExam
from app.models.inventory import InventoryCategory, Product, StockBatch, StockMovement, Supplier
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.queue import QueueTicket
from app.models.rbac import Permission, Role, role_permissions, user_permissions, user_roles
from app.models.user import User
from app.models.visit import Visit, VisitItem

__all__ = [
    "AuditLog",
    "Branch",
    "Device",
    "DeviceResult",
    "EyeExam",
    "InventoryCategory",
    "Permission",
    "Product",
    "Role",
    "Patient",
    "Payment",
    "QueueTicket",
    "Service",
    "ServiceCategory",
    "StockBatch",
    "StockMovement",
    "Supplier",
    "User",
    "Visit",
    "VisitItem",
    "role_permissions",
    "user_permissions",
    "user_roles",
]
