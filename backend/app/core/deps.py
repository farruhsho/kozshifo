"""Auth & authorization dependencies: current user + dynamic permission checks.

Permissions are fully data-driven (no hardcoded roles, per spec). A user's
effective permissions = union of their roles' permissions plus directly granted
user permissions. The director / superuser shortcut bypasses the check.
"""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.security import decode_access_token
from app.models.user import User

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.api_prefix}/auth/login")

_CREDENTIALS_EXC = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials",
    headers={"WWW-Authenticate": "Bearer"},
)


def get_current_user(
    token: Annotated[str, Depends(oauth2_scheme)],
    db: Annotated[Session, Depends(get_db)],
) -> User:
    try:
        payload = decode_access_token(token)
        subject = payload.get("sub")
        if not subject:
            raise _CREDENTIALS_EXC
        user_id = UUID(str(subject))
    except (jwt.PyJWTError, ValueError):
        raise _CREDENTIALS_EXC from None

    user = db.get(User, user_id)
    if user is None or not user.is_active:
        raise _CREDENTIALS_EXC
    # Revocation: token minted before the last password reset is stale → 401.
    if payload.get("ver", 0) != user.token_version:
        raise _CREDENTIALS_EXC
    # «Online now» tracking — O(1) in-memory touch, no DB write on the hot path.
    from app.core import monitoring
    monitoring.touch_user(user.id)
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


def require_permission(*codes: str):
    """Dependency factory: require ALL of the given permission codes.

    Usage:  dependencies=[Depends(require_permission("patients.create"))]
    """

    def _checker(user: CurrentUser) -> User:
        effective = user.effective_permission_codes()
        missing = [c for c in codes if c not in effective]
        if missing and not user.is_superuser:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing permission(s): {', '.join(missing)}",
            )
        return user

    return _checker


def require_any_permission(*codes: str):
    """Dependency factory: require AT LEAST ONE of the given permission codes.

    Usage:  Depends(require_any_permission("operations.prescribe", "operations.schedule"))
    """

    def _checker(user: CurrentUser) -> User:
        effective = user.effective_permission_codes()
        if not user.is_superuser and not any(c in effective for c in codes):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing permission(s): one of {', '.join(codes)}",
            )
        return user

    return _checker
