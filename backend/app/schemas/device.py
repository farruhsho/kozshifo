"""Device & DeviceResult DTOs."""
from __future__ import annotations

from datetime import date, datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, computed_field

DeviceType = Literal["ab_ultrasound", "refractometer", "other"]
ConnectionType = Literal["manual", "file", "serial", "usb", "hl7", "dicom"]
DeviceStatus = Literal["active", "inactive", "maintenance"]
ResultType = Literal["refraction", "biometry", "bscan_image", "file"]
ResultSource = Literal["manual", "import"]


class DeviceCreate(BaseModel):
    name: str
    device_type: DeviceType = "other"
    model: str | None = None
    manufacturer: str | None = None
    serial_no: str
    asset_code: str | None = None
    connection_type: ConnectionType = "manual"
    branch_id: UUID | None = None
    status: DeviceStatus = "active"
    manufacture_date: date | None = None
    settings: dict | None = None
    eu_rep: str | None = None
    address: str | None = None
    useful_life_years: int | None = Field(None, ge=1, le=100)


class DeviceUpdate(BaseModel):
    name: str | None = None
    device_type: DeviceType | None = None
    model: str | None = None
    manufacturer: str | None = None
    asset_code: str | None = None
    connection_type: ConnectionType | None = None
    branch_id: UUID | None = None
    status: DeviceStatus | None = None
    manufacture_date: date | None = None
    settings: dict | None = None
    eu_rep: str | None = None
    address: str | None = None
    useful_life_years: int | None = Field(None, ge=1, le=100)


class DeviceOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    device_type: str
    model: str | None
    manufacturer: str | None
    serial_no: str
    asset_code: str | None
    connection_type: str
    branch_id: UUID | None
    branch_name: str | None
    status: str
    manufacture_date: date | None
    settings: dict | None
    eu_rep: str | None
    address: str | None
    useful_life_years: int | None
    created_at: datetime
    updated_at: datetime


class DeviceResultCreate(BaseModel):
    result_type: ResultType
    payload: dict | None = None
    file_path: str | None = None  # file/watched-folder import (binary upload: later epic)
    patient_id: UUID | None = None
    visit_id: UUID | None = None
    measured_at: datetime | None = None
    source: ResultSource = "manual"


class DeviceResultLink(BaseModel):
    """Attach an orphan (visit-less) device result to a visit."""
    visit_id: UUID


class DeviceResultOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    device_id: UUID
    patient_id: UUID | None
    visit_id: UUID | None
    result_type: str
    payload: dict | None
    file_path: str | None
    measured_at: datetime
    source: str
    created_at: datetime

    @computed_field  # type: ignore[prop-decorator]
    @property
    def original_name(self) -> str | None:
        """Original filename of an uploaded result (from payload metadata) — lets
        staff see WHAT a file result is before linking, instead of the stored UUID."""
        if isinstance(self.payload, dict):
            name = self.payload.get("original_name")
            if isinstance(name, str) and name:
                return name
        return None
