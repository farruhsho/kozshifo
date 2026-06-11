"""Auth DTOs."""
from __future__ import annotations

from uuid import UUID

from pydantic import BaseModel, ConfigDict, EmailStr


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in_minutes: int


class CurrentUserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    email: EmailStr
    full_name: str
    is_superuser: bool
    branch_id: UUID | None
    permissions: list[str]
    roles: list[str]
