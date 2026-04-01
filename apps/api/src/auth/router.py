from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from src.lib.auth import (
    OAuthLoginRequest,
    RefreshTokenRequest,
    SessionExchangeRequest,
    TokenResponse,
    decode_token,
    verify_oauth_token,
    verify_session_token,
)
from src.lib.dependencies import DBSession
from src.users.model import User

router = APIRouter()


@router.post("/login", response_model=TokenResponse)
async def login(
    request: OAuthLoginRequest,
    db: DBSession,
) -> TokenResponse:
    """OAuth login endpoint.

    Verify OAuth token, create/update user, and issue JWE tokens.
    """
    user_info = await verify_oauth_token(request.provider, request.access_token)

    from sqlalchemy import select

    result = await db.execute(select(User).where(User.email == user_info.email))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            email=user_info.email,
            name=user_info.name,
            image=user_info.image,
            email_verified=user_info.email_verified,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    from src.lib.auth import create_access_token, create_refresh_token

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/session-exchange", response_model=TokenResponse)
async def session_exchange(
    request: SessionExchangeRequest,
    db: DBSession,
) -> TokenResponse:
    """Exchange better-auth session token for backend JWE tokens.

    Used by email/password auth users who have no OAuth provider token.
    Verifies session with better-auth server, then issues backend tokens.
    """
    user_info = await verify_session_token(request.session_token)

    from sqlalchemy import select

    result = await db.execute(select(User).where(User.email == user_info.email))
    user = result.scalar_one_or_none()

    if not user:
        user = User(
            email=user_info.email,
            name=user_info.name,
            image=user_info.image,
            email_verified=user_info.email_verified,
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

    from src.lib.auth import create_access_token, create_refresh_token

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(
    request: RefreshTokenRequest,
    db: DBSession,
) -> TokenResponse:
    """Refresh access token using refresh token."""
    payload = decode_token(request.refresh_token)

    if payload.token_type != "refresh":  # noqa: S105
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
        )

    from sqlalchemy import select

    result = await db.execute(select(User).where(User.id == UUID(payload.user_id)))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    from src.lib.auth import create_access_token

    access_token = create_access_token(str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=request.refresh_token,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout() -> None:
    """Logout endpoint.

    Client should remove tokens from localStorage.
    """
    return None
