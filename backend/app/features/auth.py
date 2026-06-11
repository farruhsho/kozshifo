"""Authentication: OAuth2 password login + current-user introspection."""
from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.audit import record_audit
from app.core.config import settings
from app.core.database import get_db
from app.core.deps import CurrentUser
from app.core.security import create_access_token, verify_password
from app.models.user import User
from app.schemas.auth import CurrentUserOut, Token

router = APIRouter(prefix="/auth", tags=["Auth"])


@router.post("/login", response_model=Token)
def login(
    request: Request,
    form: Annotated[OAuth2PasswordRequestForm, Depends()],
    db: Annotated[Session, Depends(get_db)],
) -> Token:
    user = db.execute(select(User).where(User.email == form.username)).scalar_one_or_none()
    if user is None or not user.is_active or not verify_password(form.password, user.hashed_password):
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Incorrect email or password")

    record_audit(
        db, action="login", entity_type="user", entity_id=user.id, actor_id=user.id,
        summary=f"Login: {user.email}",
        ip_address=request.client.host if request.client else None,
    )
    db.commit()
    return Token(
        access_token=create_access_token(str(user.id)),
        expires_in_minutes=settings.access_token_expire_minutes,
    )


@router.get("/me", response_model=CurrentUserOut)
def read_me(user: CurrentUser) -> CurrentUserOut:
    return CurrentUserOut(
        id=user.id,
        email=user.email,
        full_name=user.full_name,
        is_superuser=user.is_superuser,
        branch_id=user.branch_id,
        permissions=sorted(user.effective_permission_codes()),
        roles=[r.name for r in user.roles],
    )
