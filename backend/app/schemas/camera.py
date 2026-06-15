"""IP camera DTOs.

The camera admin ``password`` is write-only: it appears on Create/Update inputs
but on **no** output model — see models/camera.py (mirrors access_control).
"""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class CameraCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    host: str = Field(min_length=1, max_length=255)  # LAN IP or hostname
    port: int = Field(default=80, ge=1, le=65535)
    username: str = Field(min_length=1, max_length=128)
    password: str = Field(min_length=1, max_length=255)
    use_https: bool = False
    vendor: str = Field(default="hikvision", pattern="^(hikvision|generic)$")
    channel_no: int = Field(default=1, ge=1, le=255)
    snapshot_path: str | None = Field(None, max_length=255)
    branch_id: UUID | None = None


class CameraUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    host: str | None = Field(None, min_length=1, max_length=255)
    port: int | None = Field(None, ge=1, le=65535)
    username: str | None = Field(None, min_length=1, max_length=128)
    password: str | None = Field(None, min_length=1, max_length=255)  # omit = unchanged
    use_https: bool | None = None
    vendor: str | None = Field(None, pattern="^(hikvision|generic)$")
    channel_no: int | None = Field(None, ge=1, le=255)
    snapshot_path: str | None = Field(None, max_length=255)
    branch_id: UUID | None = None
    status: str | None = Field(None, pattern="^(active|inactive)$")


class CameraOut(BaseModel):
    """Camera as returned to the UI — never includes the password."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    host: str
    port: int
    username: str
    use_https: bool
    vendor: str
    channel_no: int
    snapshot_path: str | None
    branch_id: UUID | None
    branch_name: str | None = None
    status: str
    online: bool
    last_seen: datetime | None
    device_info: dict | None
    created_at: datetime


class CameraTestResult(BaseModel):
    """Outcome of probing the camera (GET /ISAPI/System/deviceInfo)."""

    online: bool
    model: str | None = None
    firmware: str | None = None
    serial: str | None = None
    device_name: str | None = None
    error: str | None = None  # populated when online is false
