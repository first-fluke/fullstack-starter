from uuid import UUID

from fastapi import APIRouter, HTTPException, status

from src.lib.auth import (
    CurrentUser,
    EmailLoginRequest,
    OAuthLoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    SessionExchangeRequest,
    TokenResponse,
    decode_token,
    hash_password,
    normalize_email,
    verify_oauth_token,
    verify_password,
    verify_session_token,
)
from src.lib.dependencies import DBSession
from src.users.model import User, UserResponse

router = APIRouter()


async def _get_user_by_email(db: DBSession, email: str) -> User | None:
    """Load a user by normalized email."""
    from sqlalchemy import select

    result = await db.execute(select(User).where(User.email == normalize_email(email)))
    return result.scalar_one_or_none()


async def _create_user(
    db: DBSession,
    email: str,
    name: str | None = None,
    image: str | None = None,
    email_verified: bool = False,
    password_hash: str | None = None,
) -> User:
    """Create and hydrate a user."""
    user = User(
        email=normalize_email(email),
        name=name,
        image=image,
        email_verified=email_verified,
        password_hash=password_hash,
    )
    db.add(user)
    await db.flush()
    await db.refresh(user)
    return user


def _issue_tokens(user: User) -> TokenResponse:
    """Issue backend tokens for a user."""
    from src.lib.auth import create_access_token, create_refresh_token

    access_token = create_access_token(str(user.id))
    refresh_token = create_refresh_token(str(user.id))

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
    )


@router.post(
    "/register",
    response_model=TokenResponse,
    status_code=status.HTTP_201_CREATED,
)
async def register(
    request: RegisterRequest,
    db: DBSession,
) -> TokenResponse:
    """Register with email/password and issue backend tokens."""
    existing_user = await _get_user_by_email(db, request.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    user = await _create_user(
        db,
        email=request.email,
        name=request.name,
        email_verified=False,
        password_hash=hash_password(request.password),
    )

    return _issue_tokens(user)


@router.post("/login", response_model=TokenResponse)
async def login(
    request: OAuthLoginRequest | EmailLoginRequest,
    db: DBSession,
) -> TokenResponse:
    """Login with OAuth or email/password and issue backend tokens.

    Verify OAuth token, create/update user, and issue JWE tokens.
    """
    if isinstance(request, EmailLoginRequest):
        user = await _get_user_by_email(db, request.email)
        if not user or not verify_password(request.password, user.password_hash):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )
        return _issue_tokens(user)

    user_info = await verify_oauth_token(request.provider, request.access_token)
    user = await _get_user_by_email(db, user_info.email or request.email)

    if not user:
        user = await _create_user(
            db,
            email=user_info.email or request.email,
            name=user_info.name,
            image=user_info.image,
            email_verified=user_info.email_verified,
        )

    return _issue_tokens(user)


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
    user = await _get_user_by_email(db, user_info.email or "")

    if not user:
        user = await _create_user(
            db,
            email=user_info.email or "",
            name=user_info.name,
            image=user_info.image,
            email_verified=user_info.email_verified,
        )

    return _issue_tokens(user)


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


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: CurrentUser,
    db: DBSession,
) -> UserResponse:
    """Return the current authenticated user."""
    from sqlalchemy import select

    result = await db.execute(select(User).where(User.id == UUID(current_user.id)))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    return UserResponse(
        id=str(user.id),
        email=user.email,
        name=user.name,
        image=user.image,
        email_verified=user.email_verified,
        created_at=user.created_at,
        updated_at=user.updated_at,
    )
