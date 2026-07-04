"""Authentication: OAuth2 password login, token refresh + current-user introspection."""
from __future__ import annotations

from typing import Annotated
from uuid import UUID

import jwt
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.config import settings
from app.core.database import get_db
from app.core.deps import CurrentUser
from app.core.security import create_access_token, create_refresh_token, decode_token, verify_password
from app.models.user import User
from app.models.user_session import UserSession
from app.schemas.auth import CurrentUserOut, RefreshRequest, Token

router = APIRouter(prefix="/auth", tags=["Auth"])


def _issue_token_pair(user: User) -> Token:
    return Token(
        access_token=create_access_token(str(user.id), version=user.token_version),
        refresh_token=create_refresh_token(str(user.id), version=user.token_version),
        expires_in_minutes=settings.access_token_expire_minutes,
    )


@router.post("/login", response_model=Token)
def login(
    request: Request,
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Annotated[Session, Depends(get_db)],
) -> Token:
    user = db.execute(select(User).where(User.email == form.username)).scalar_one_or_none()
    if user is None or not user.is_active or not verify_password(form.password, user.hashed_password):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email or password")

    client_ip = request.client.host if request.client else None
    user_agent = request.headers.get("user-agent")
    record_audit(
        db, action="login", entity_type="user", entity_id=user.id, actor_id=user.id,
        summary=f"Login: {user.email}",
        ip_address=client_ip,
    )
    # Persist the login session (Super Admin monitoring → login history).
    db.add(UserSession(user_id=user.id, ip_address=client_ip, user_agent=user_agent))
    db.commit()
    return _issue_token_pair(user)


@router.post("/refresh", response_model=Token)
def refresh(body: RefreshRequest, db: Annotated[Session, Depends(get_db)]) -> Token:
    """Exchange a valid refresh token for a fresh access+refresh pair (rotation).

    Unauthenticated by design — the refresh token itself is the credential.
    Any problem (bad signature, expired, wrong type, unknown/inactive user)
    yields a uniform 401 so the endpoint leaks nothing.
    """
    invalid = HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired refresh token")
    try:
        payload = decode_token(body.refresh_token, expected_type="refresh")
        user_id = UUID(str(payload.get("sub") or ""))
    except (jwt.PyJWTError, ValueError):
        raise invalid from None

    user = db.get(User, user_id)
    if user is None or not user.is_active:
        raise invalid
    # Revocation: a token minted before the last password reset is stale.
    if payload.get("ver", 0) != user.token_version:
        raise invalid
    return _issue_token_pair(user)


@router.get("/me", response_model=CurrentUserOut)
def read_me(user: CurrentUser) -> CurrentUserOut:
    return CurrentUserOut(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        is_superuser=user.is_superuser,
        branch_id=user.branch_id,
        cabinet=user.cabinet,
        permissions=sorted(user.effective_permission_codes()),
        roles=[r.name for r in user.roles],
    )
