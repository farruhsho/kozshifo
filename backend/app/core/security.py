"""Password hashing (bcrypt) and JWT access/refresh-token issuing/verification."""
from __future__ import annotations

import uuid
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


def create_refresh_token(subject: str) -> str:
    """Long-lived JWT used solely to mint new token pairs at /auth/refresh.

    Carries a `jti` so every refresh token is unique (rotation-friendly, and a
    future revocation list can key on it).
    """
    now = datetime.now(timezone.utc)
    payload: dict = {
        "sub": subject,
        "iat": now,
        "exp": now + timedelta(days=settings.refresh_token_expire_days),
        "type": "refresh",
        "jti": uuid.uuid4().hex,
    }
    return jwt.encode(payload, settings.secret_key, algorithm=settings.algorithm)


def decode_token(token: str, expected_type: str = "access") -> dict:
    """Shared decode helper: validate signature/expiry AND the `type` claim.

    Tokens minted before the `type` claim existed are treated as access tokens
    (backward compatibility). Raises jwt.PyJWTError on any problem, including
    a type mismatch — so a refresh token can never be used as an access token
    and vice versa.
    """
    payload = jwt.decode(token, settings.secret_key, algorithms=[settings.algorithm])
    token_type = payload.get("type", "access")
    if token_type != expected_type:
        raise jwt.InvalidTokenError(f"Expected a(n) {expected_type} token, got {token_type}")
    return payload


def decode_access_token(token: str) -> dict:
    """Decode and validate an access JWT. Raises jwt.PyJWTError on any problem."""
    return decode_token(token, expected_type="access")
