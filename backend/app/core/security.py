"""Password hashing (bcrypt) and JWT access-token issuing/verification."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

import bcrypt
import jwt

from app.core.config import settings

_BCRYPT_MAX_BYTES = 72  # bcrypt truncates silently beyond this; we guard explicitly.


def hash_password(plain: str) -> str:
    pw = plain.encode("utf-8")[:_BCRYPT_MAX_BYTES]
    return bcrypt.hashpw(pw, bcrypt.gensalt()).decode("utf-8")


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode("utf-8")[:_BCRYPT_MAX_BYTES], hashed.encode("utf-8"))
    except (ValueError, TypeError):
        return False


def create_access_token(subject: str, extra_claims: dict | None = None) -> str:
    now = datetime.now(timezone.utc)
    payload: dict = {
        "sub": subject,
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_expire_minutes),
        "type": "access",
    }
    if extra_claims:
        payload.update(extra_claims)
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def decode_access_token(token: str) -> dict:
    """Decode and validate a JWT. Raises jwt.PyJWTError on any problem."""
    return jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
