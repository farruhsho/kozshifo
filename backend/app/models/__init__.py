"""Import all models so they register on Base.metadata (order-independent)."""
from app.models.attachment import Attachment
from app.models.attendance import AttendanceEvent
from app.models.audit import AuditLog
from app.models.branch import Branch
from app.models.cabinet import Cabinet
from app.models.call import CallDevice, CallRecord
from app.models.catalog import Service, ServiceCategory, service_doctors
from app.models.finance import Expense, ExpenseCategory, RecurringExpense
from app.models.device import Device, DeviceResult
from app.models.diagnosis import Diagnosis, VisitDiagnosis, user_diagnoses
from app.models.exam import EyeExam
from app.models.exam_template import ExamTemplate
from app.models.face_terminal import FaceTerminal
from app.models.inventory import InventoryCategory, Product, StockBatch, StockMovement, Supplier
from app.models.notification import Notification
from app.models.operation import Operation, OperationType, OperationTypeConsumable, Treatment
from app.models.patient import Patient
from app.models.payment import Payment
from app.models.queue import QueueTicket
from app.models.rbac import Permission, Role, role_permissions, user_permissions, user_roles
from app.models.user import User
from app.models.user_session import UserSession
from app.models.visit import Visit, VisitItem

__all__ = [
    "Attachment",
    "AttendanceEvent",
    "AuditLog",
    "Branch",
    "Cabinet",
    "CallDevice",
    "CallRecord",
    "Device",
    "DeviceResult",
    "Diagnosis",
    "Expense",
    "ExpenseCategory",
    "RecurringExpense",
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
    "service_doctors",
    "StockBatch",
    "StockMovement",
    "Supplier",
    "Treatment",
    "User",
    "UserSession",
    "Visit",
    "VisitDiagnosis",
    "VisitItem",
    "role_permissions",
    "user_diagnoses",
    "user_permissions",
    "user_roles",
]
