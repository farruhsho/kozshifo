"""Access control / Face ID DTOs.

The terminal admin ``password`` is write-only: it appears on Create/Update
inputs but on **no** output model — see models/face_terminal.py.
"""
from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class TerminalCreate(BaseModel):
    name: str = Field(min_length=1, max_length=255)
    host: str = Field(min_length=1, max_length=255)  # LAN IP or hostname
    port: int = Field(default=80, ge=1, le=65535)
    username: str = Field(min_length=1, max_length=128)
    password: str = Field(min_length=1, max_length=255)
    door_no: int = Field(default=1, ge=1, le=255)
    use_https: bool = False
    branch_id: UUID | None = None


class TerminalUpdate(BaseModel):
    name: str | None = Field(None, min_length=1, max_length=255)
    host: str | None = Field(None, min_length=1, max_length=255)
    port: int | None = Field(None, ge=1, le=65535)
    username: str | None = Field(None, min_length=1, max_length=128)
    password: str | None = Field(None, min_length=1, max_length=255)  # omit = unchanged
    door_no: int | None = Field(None, ge=1, le=255)
    use_https: bool | None = None
    branch_id: UUID | None = None
    status: str | None = Field(None, pattern="^(active|inactive)$")


class TerminalOut(BaseModel):
    """Terminal as returned to the UI — never includes the password."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    name: str
    host: str
    port: int
    username: str
    door_no: int
    use_https: bool
    branch_id: UUID | None
    branch_name: str | None = None
    status: str
    online: bool
    last_seen: datetime | None
    device_info: dict | None
    created_at: datetime


class TerminalTestResult(BaseModel):
    """Outcome of probing the terminal (GET /ISAPI/System/deviceInfo)."""

    online: bool
    model: str | None = None
    firmware: str | None = None
    serial: str | None = None
    device_name: str | None = None
    error: str | None = None  # populated when online is false


class PushConfigIn(BaseModel):
    """Where the terminal should POST its events. Both optional — the server
    auto-detects its own LAN IP and defaults the port to 8000 when omitted.
    The web client passes the origin host/port it was served from."""

    server_host: str | None = Field(None, max_length=255)
    server_port: int | None = Field(None, ge=1, le=65535)


class PushConfigResult(BaseModel):
    configured: bool
    url: str  # the push URL set on the device (token masked)
    error: str | None = None


class EnrollmentRow(BaseModel):
    """One staff member's Face ID enrollment status."""

    user_id: UUID
    full_name: str
    email: str
    branch_id: UUID | None = None
    faceid_employee_no: str | None = None
    enrolled: bool  # has a faceid_employee_no assigned


class EnrollResult(BaseModel):
    user_id: UUID
    faceid_employee_no: str
    pushed_to_device: bool  # UserInfo/Record succeeded
    face_uploaded: bool = False
    error: str | None = None  # device-side problem (mapping still saved locally)


class AccessEventOut(BaseModel):
    """A recognition/attendance event surfaced in the Face ID screen."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    user_id: UUID
    user_full_name: str | None = None
    direction: str
    occurred_at: datetime
    source: str
