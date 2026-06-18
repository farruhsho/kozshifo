"""DTOs for the diagnosis / conclusion catalog (справочник заключений)."""
from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class DiagnosisCreate(BaseModel):
    code: str = Field(min_length=1, max_length=32)
    name: str = Field(min_length=1, max_length=255)
    category: str | None = None
    icd10: str | None = None
    is_active: bool = True


class DiagnosisUpdate(BaseModel):
    name: str | None = None
    category: str | None = None
    icd10: str | None = None
    is_active: bool | None = None


class DiagnosisOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    code: str
    name: str
    category: str | None = None
    icd10: str | None = None
    is_active: bool
