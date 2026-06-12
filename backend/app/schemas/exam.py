"""Eye exam DTOs (Form 025-8 «ОКУЛИСТ КУРИГИ»).

Clinical ranges enforced here → invalid input is a 422 before touching the DB:
axis ∈ [0, 180]; sph/cyl ∈ [-30, +30] D; IOP ∈ [0, 99.9] mmHg.
Decimals serialize to the client as strings (platform-wide rule).
"""
from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class EyeExamUpsert(BaseModel):
    exam_date: date | None = None  # defaults to today on create
    complaints: str | None = None
    anamnesis: str | None = None

    od_va: str | None = Field(None, max_length=32)
    os_va: str | None = Field(None, max_length=32)
    od_sph: Decimal | None = Field(None, ge=Decimal("-30"), le=Decimal("30"))
    os_sph: Decimal | None = Field(None, ge=Decimal("-30"), le=Decimal("30"))
    od_cyl: Decimal | None = Field(None, ge=Decimal("-30"), le=Decimal("30"))
    os_cyl: Decimal | None = Field(None, ge=Decimal("-30"), le=Decimal("30"))
    od_axis: int | None = Field(None, ge=0, le=180)
    os_axis: int | None = Field(None, ge=0, le=180)
    od_va_cc: str | None = Field(None, max_length=32)
    os_va_cc: str | None = Field(None, max_length=32)

    iop_od: Decimal | None = Field(None, ge=Decimal("0"), le=Decimal("99.9"))
    iop_os: Decimal | None = Field(None, ge=Decimal("0"), le=Decimal("99.9"))

    orbit: str | None = None
    eyeball: str | None = None
    eyelids: str | None = None
    conjunctiva: str | None = None
    lacrimal: str | None = None
    cornea: str | None = None
    anterior_chamber: str | None = None
    iris: str | None = None
    pupil: str | None = None
    lens: str | None = None
    vitreous: str | None = None
    fundus: str | None = None

    ab_scan_note: str | None = None

    diagnosis: str | None = None
    icd10: str | None = Field(None, max_length=16)
    recommendations: str | None = None

    doctor_id: UUID | None = None  # defaults to the current user on create


class EyeExamOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    visit_id: UUID
    patient_id: UUID
    doctor_id: UUID | None
    exam_date: date

    complaints: str | None
    anamnesis: str | None

    od_va: str | None
    os_va: str | None
    od_sph: Decimal | None
    os_sph: Decimal | None
    od_cyl: Decimal | None
    os_cyl: Decimal | None
    od_axis: int | None
    os_axis: int | None
    od_va_cc: str | None
    os_va_cc: str | None

    iop_od: Decimal | None
    iop_os: Decimal | None

    orbit: str | None
    eyeball: str | None
    eyelids: str | None
    conjunctiva: str | None
    lacrimal: str | None
    cornea: str | None
    anterior_chamber: str | None
    iris: str | None
    pupil: str | None
    lens: str | None
    vitreous: str | None
    fundus: str | None

    ab_scan_note: str | None

    diagnosis: str | None
    icd10: str | None
    recommendations: str | None

    created_at: datetime
    updated_at: datetime
