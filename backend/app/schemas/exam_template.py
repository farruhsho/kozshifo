"""Exam-conclusion template DTOs (reusable doctor назначения)."""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator


class ExamTemplateCreate(BaseModel):
    name: str = Field(min_length=1, max_length=128)
    diagnosis: str | None = None
    icd10: str | None = Field(None, max_length=16)
    recommendations: str | None = None

    @model_validator(mode="after")
    def _not_empty(self) -> "ExamTemplateCreate":
        # A template with no content is useless — require at least one field.
        if not (self.diagnosis or self.recommendations or self.icd10):
            raise ValueError("Template must include a diagnosis, ICD-10 or recommendations")
        self.name = self.name.strip()
        return self


class ExamTemplateOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    doctor_id: UUID
    name: str
    diagnosis: str | None
    icd10: str | None
    recommendations: str | None
    created_at: datetime
