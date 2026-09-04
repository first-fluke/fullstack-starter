from datetime import UTC, datetime
from urllib.parse import urlencode
from uuid import UUID

from fastapi import APIRouter, HTTPException, Request, Response, status
from fastapi.responses import RedirectResponse

from src.auth.oauth_service import (
    cancel_oauth_callback,
    complete_oauth_callback,
    consume_exchange_code,
    create_authorization_url,
)
from src.auth.passkey_service import (
    create_authentication_options,
    create_registration_options,
    verify_authentication,
    verify_registration,
)
from src.auth.repository import AuthRepository
from src.auth.schemas import (
    OAuthExchangeRequest,
    OAuthProvider,
    PasskeyAuthenticationOptionsRequest,
    PasskeyAuthenticationVerifyRequest,
    PasskeyRegistrationVerifyRequest,
)
from src.lib.auth import (
    CurrentUser,
    EmailLoginRequest,
    RefreshTokenRequest,
    RegisterRequest,
    TokenResponse,
    decode_token,
    hash_password,
    normalize_email,
    verify_password,
)
from src.lib.dependencies import DBSession
from src.lib.rate_limit import rate_limit
from src.lib.token_store import revoke, revoke_if_not_revoked
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
@rate_limit(requests=5, window=60)
async def register(
    request: Request,
    body: RegisterRequest,
    db: DBSession,
) -> TokenResponse:
    """Register with email/password and issue backend tokens."""
    existing_user = await _get_user_by_email(db, body.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered",
        )

    user = await _create_user(
        db,
        email=body.email,
        name=body.name,
        email_verified=False,
        password_hash=hash_password(body.password),
    )

    return _issue_tokens(user)


@router.post("/login", response_model=TokenResponse)
@rate_limit(requests=5, window=60)
async def login(
    request: Request,
    body: EmailLoginRequest,
    db: DBSession,
) -> TokenResponse:
    """Login with email/password and issue first-party tokens."""
    user = await _get_user_by_email(db, body.email)
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
        )
    return _issue_tokens(user)


@router.get("/oauth/{provider}/authorize")
@rate_limit(requests=5, window=60)
async def oauth_authorize(
    request: Request,
    provider: OAuthProvider,
    redirect_uri: str,
    return_to: str = "/",
    code_challenge: str | None = None,
    code_challenge_method: str | None = None,
) -> RedirectResponse:
    """Start an OAuth Authorization Code + PKCE transaction."""
    authorization_url = await create_authorization_url(
        provider,
        redirect_uri,
        return_to,
        client_code_challenge=code_challenge,
        client_code_challenge_method=code_challenge_method,
    )
    return RedirectResponse(authorization_url, status_code=status.HTTP_302_FOUND)


@router.get("/oauth/{provider}/callback")
async def oauth_callback(
    provider: OAuthProvider,
    db: DBSession,
    state: str,
    code: str | None = None,
    error: str | None = None,
) -> RedirectResponse:
    """Handle the provider callback and redirect with a one-time login code."""
    if error or not code:
        redirect_uri, return_to = await cancel_oauth_callback(
            provider=provider, state=state
        )
        separator = "&" if "?" in redirect_uri else "?"
        query = urlencode({"error": error or "access_denied", "return_to": return_to})
        return RedirectResponse(
            f"{redirect_uri}{separator}{query}", status_code=status.HTTP_302_FOUND
        )

    repository = AuthRepository(db)
    exchange_code, redirect_uri, return_to = await complete_oauth_callback(
        repository, provider=provider, code=code, state=state
    )
    separator = "&" if "?" in redirect_uri else "?"
    query = urlencode({"code": exchange_code, "return_to": return_to})
    return RedirectResponse(
        f"{redirect_uri}{separator}{query}", status_code=status.HTTP_302_FOUND
    )


@router.post("/oauth/exchange", response_model=TokenResponse)
@rate_limit(requests=10, window=60)
async def oauth_exchange(
    request: Request,
    body: OAuthExchangeRequest,
) -> TokenResponse:
    """Exchange a single-use OAuth code for first-party access and refresh tokens."""
    user_id = await consume_exchange_code(body.code, body.code_verifier)
    from src.lib.auth import create_access_token, create_refresh_token

    return TokenResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
    )


@router.post("/passkeys/register/options")
@rate_limit(requests=10, window=60)
async def passkey_registration_options(
    current_user: CurrentUser,
    request: Request,
    db: DBSession,
) -> dict[str, object]:
    """Create options for registering a passkey to the signed-in account."""
    return await create_registration_options(AuthRepository(db), current_user.id)


@router.post("/passkeys/register/verify", status_code=status.HTTP_204_NO_CONTENT)
@rate_limit(requests=10, window=60)
async def passkey_registration_verify(
    current_user: CurrentUser,
    request: Request,
    body: PasskeyRegistrationVerifyRequest,
    db: DBSession,
) -> Response:
    """Verify and store a new passkey."""
    await verify_registration(
        AuthRepository(db),
        user_id=current_user.id,
        ceremony_id=body.ceremony_id,
        credential=body.credential,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/passkeys/authenticate/options")
@rate_limit(requests=10, window=60)
async def passkey_authentication_options(
    request: Request,
    body: PasskeyAuthenticationOptionsRequest,
    db: DBSession,
) -> dict[str, object]:
    """Create options for signing in with a passkey."""
    return await create_authentication_options(AuthRepository(db), body.email)


@router.post("/passkeys/authenticate/verify", response_model=TokenResponse)
@rate_limit(requests=10, window=60)
async def passkey_authentication_verify(
    request: Request,
    body: PasskeyAuthenticationVerifyRequest,
    db: DBSession,
) -> TokenResponse:
    """Verify a passkey assertion and issue first-party tokens."""
    return await verify_authentication(
        AuthRepository(db),
        ceremony_id=body.ceremony_id,
        credential=body.credential,
    )


@router.post("/refresh", response_model=TokenResponse)
@rate_limit(requests=5, window=60)
async def refresh_token(
    request: Request,
    body: RefreshTokenRequest,
    db: DBSession,
) -> TokenResponse:
    """Refresh access token using refresh token (with rotation)."""
    payload = decode_token(body.refresh_token)

    if payload.token_type != "refresh":  # noqa: S105
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
        )

    # Atomically claim the refresh token — first caller wins, replays are rejected.
    now_ts = int(datetime.now(UTC).timestamp())
    remaining_ttl = max(0, payload.exp - now_ts)
    claimed = await revoke_if_not_revoked(payload.jti, remaining_ttl)
    if not claimed:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked",
            headers={"WWW-Authenticate": "Bearer"},
        )

    from sqlalchemy import select

    result = await db.execute(select(User).where(User.id == UUID(payload.user_id)))
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )

    # Issue brand-new access + refresh tokens (rotation)
    from src.lib.auth import create_access_token, create_refresh_token

    new_access_token = create_access_token(str(user.id))
    new_refresh_token = create_refresh_token(str(user.id))

    return TokenResponse(
        access_token=new_access_token,
        refresh_token=new_refresh_token,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    current_user: CurrentUser,
    request: Request,
    body: RefreshTokenRequest,
) -> None:
    """Logout: revoke both the access token and the refresh token."""
    # Revoke access token — extract jti from the Bearer header
    auth_header = request.headers.get("Authorization", "")
    if auth_header.startswith("Bearer "):
        access_token_str = auth_header.removeprefix("Bearer ")
        try:
            access_payload = decode_token(access_token_str)
            now_ts = int(datetime.now(UTC).timestamp())
            access_ttl = max(0, access_payload.exp - now_ts)
            await revoke(access_payload.jti, access_ttl)
        except HTTPException:
            pass  # Token already invalid — nothing to revoke

    # Revoke refresh token from body
    try:
        refresh_payload = decode_token(body.refresh_token)
        now_ts = int(datetime.now(UTC).timestamp())
        refresh_ttl = max(0, refresh_payload.exp - now_ts)
        await revoke(refresh_payload.jti, refresh_ttl)
    except HTTPException:
        pass  # Token already invalid — nothing to revoke

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
