"""Debt-management DTOs (owner brief 2026-06-20).

Debt is DERIVED from unpaid visit balances + the existing Payment ledger — there
is no separate Debt entity (a stored copy would drift from the real balance). A
debtor = a patient with one or more OPEN visits whose payable exceeds what was
paid; repayment reuses the normal /payments path (partial payments included).
"""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel


class DebtorRow(BaseModel):
    patient_id: UUID
    patient_name: str
    phone: str | None = None
    patient_no: str | None = None
    total_debt: Decimal           # Σ remaining over the patient's open owing visits
    visit_count: int
    oldest_debt_at: datetime      # earliest owing visit (дата возникновения)
    last_payment_at: datetime | None = None


class DebtVisitRow(BaseModel):
    visit_id: UUID
    visit_no: str
    opened_at: datetime
    payable: Decimal
    paid: Decimal
    remaining: Decimal
    services: str                 # billed services snapshot (причина долга)
    flow_status: str


class DebtPaymentRow(BaseModel):
    paid_at: datetime
    amount: Decimal
    method: str
    cashier_name: str | None = None
    note: str | None = None       # комментарий к оплате
    visit_no: str
    status: str                   # completed | refunded


class PatientDebtDetail(BaseModel):
    patient_id: UUID
    patient_name: str
    phone: str | None = None
    total_debt: Decimal
    visits: list[DebtVisitRow]    # owing visits (сумма/дата/причина/остаток)
    payments: list[DebtPaymentRow]  # история оплат (дата/сумма/кассир/комментарий)
