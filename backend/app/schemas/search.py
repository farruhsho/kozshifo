"""Smart Search DTOs: one global search box, sections gated by module RBAC.

Lean projections on purpose — the search dropdown needs just enough to render
a row and navigate; the full record is fetched by the target screen.
"""
from __future__ import annotations

from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict


class SearchPatient(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    mrn: str
    patient_no: str | None
    full_name: str
    phone: str | None


class SearchVisit(BaseModel):
    id: UUID
    visit_no: str
    patient_id: UUID
    patient_name: str
    flow_status: str
    status: str


class SearchReceipt(BaseModel):
    payment_id: UUID
    receipt_no: str
    amount: Decimal  # serialized as a decimal string (platform-wide money rule)
    visit_id: UUID
    patient_id: UUID


class SearchOut(BaseModel):
    patients: list[SearchPatient]
    visits: list[SearchVisit]
    receipts: list[SearchReceipt]


class FrequentDiagnosis(BaseModel):
    """One row of a doctor's personal most-used diagnoses (one-click reuse)."""

    diagnosis: str
    count: int
