"""Import all models so they register on Base.metadata (order-independent)."""
from app.models.attendance import AttendanceEvent
from app.models.audit import AuditLog
from app.models.branch import Branch
from app.models.call import CallRecord
from app.models.catalog import Service, ServiceCategory
from app.models.finance import Expense
from app.models.device import Device, DeviceResult
from app.models.exam import EyeExam
from app.models.face_terminal import FaceTerminal
from app.models.inventory import InventoryCategory, Product, StockBatch, StockMovement, Supplier
from app.models.notification import Notification
from app.models.operation import Operation, OperationType, OperationTypeConsumable, Treatment
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.queue import QueueTicket
from app.models.rbac import Permission, Role, role_permissions, user_permissions, user_roles
from app.models.user import User
from app.models.visit import Visit, VisitItem

__all__ = [
    "AttendanceEvent",
    "AuditLog",
    "Branch",
    "CallRecord",
    "Device",
    "DeviceResult",
    "Expense",
    "EyeExam",
    "FaceTerminal",
    "InventoryCategory",
    "Notification",
    "Operation",
    "OperationType",
    "OperationTypeConsumable",
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
    "Treatment",
    "User",
    "Visit",
    "VisitItem",
    "role_permissions",
    "user_permissions",
    "user_roles",
]
