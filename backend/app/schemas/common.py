"""Shared response envelopes."""
from __future__ import annotations

from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")


class Page(BaseModel, Generic[T]):
    """Offset/limit pagination envelope."""

    items: list[T]
    total: int
    offset: int
    limit: int


class Message(BaseModel):
    detail: str
