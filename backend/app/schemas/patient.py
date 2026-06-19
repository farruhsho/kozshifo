"""Patient DTOs."""
from __future__ import annotations

from datetime import date
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict

# CRM lead source (where the patient came from) — canonical wire vocabulary.
# UI labels (RU): Instagram / Telegram / Google / Рекомендация / Баннер /
# Проходил мимо / Другое.
LeadSource = Literal[
    "instagram", "telegram", "google", "referral", "banner", "walk_in", "other"
]
Gender = Literal["male", "female", "other"]


class PatientCreate(BaseModel):
    first_name: str
    last_name: str
    middle_name: str | None = None
    birth_date: date | None = None
    gender: Gender | None = None
    phone: str | None = None
    phone2: str | None = None
    email: str | None = None
    address: str | None = None
    region: str | None = None
    district: str | None = None
    passport: str | None = None
    pinfl: str | None = None
    lead_source: LeadSource | None = None
    workplace: str | None = None
    study_place: str | None = None
    profession: str | None = None
    dispensary_here: str | None = None
    dispensary_other: str | None = None
    notes: str | None = None
    branch_id: UUID | None = None
    primary_doctor_id: UUID | None = None  # лечащий врач
    mrn: str | None = None  # auto-generated if omitted


class PatientUpdate(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    middle_name: str | None = None
    birth_date: date | None = None
    gender: Gender | None = None
    phone: str | None = None
    phone2: str | None = None
    email: str | None = None
    address: str | None = None
    region: str | None = None
    district: str | None = None
    passport: str | None = None
    pinfl: str | None = None
    lead_source: LeadSource | None = None
    workplace: str | None = None
    study_place: str | None = None
    profession: str | None = None
    dispensary_here: str | None = None
    dispensary_other: str | None = None
    notes: str | None = None
    primary_doctor_id: UUID | None = None


class PatientOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    mrn: str
    patient_no: str | None
    first_name: str
    last_name: str
    middle_name: str | None
    full_name: str
    birth_date: date | None
    gender: str | None
    phone: str | None
    phone2: str | None
    email: str | None
    address: str | None
    region: str | None = None
    district: str | None = None
    passport: str | None
    pinfl: str | None
    lead_source: str | None
    workplace: str | None
    study_place: str | None
    profession: str | None
    dispensary_here: str | None
    dispensary_other: str | None
    notes: str | None
    branch_id: UUID | None
    primary_doctor_id: UUID | None = None
    primary_doctor_name: str | None = None


class DuplicateCandidate(BaseModel):
    """A possible existing match shown before creating a new patient."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    patient_no: str | None
    mrn: str
    full_name: str
    birth_date: date | None
    phone: str | None
    reason: str  # why it matched: «телефон» / «ФИО+дата» / «ФИО»


class PatientSummary(BaseModel):
    """Reception history panel: at-a-glance facts about a patient."""

    patient_id: UUID
    visit_count: int
    last_visit_at: date | None = None
    last_diagnosis: str | None = None
    last_operation: str | None = None
    last_payment_amount: str | None = None
    last_payment_at: date | None = None
    total_debt: str  # decimal string across open visits
    last_discount_reason: str | None = None
    is_repeat: bool
    # Doctor-of-patient (Phase 2): the persistent лечащий врач, plus the doctor on
    # the most recent visit as a fallback so reception can pre-fill the picker.
    primary_doctor_id: UUID | None = None
    primary_doctor_name: str | None = None
    last_visit_doctor_id: UUID | None = None
    last_visit_doctor_name: str | None = None
