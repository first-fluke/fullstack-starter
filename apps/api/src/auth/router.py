from datetime import UTC, datetime
from typing import Annotated, Any
from urllib.parse import urlencode
from uuid import UUID

from litestar import Controller, Request, Router, get, post
from litestar.exceptions import HTTPException
from litestar.params import FromPath, FromQuery, JSONBody, QueryParameter
from litestar.response import Redirect
from litestar.status_codes import (
    HTTP_200_OK,
    HTTP_201_CREATED,
    HTTP_204_NO_CONTENT,
    HTTP_302_FOUND,
    HTTP_401_UNAUTHORIZED,
    HTTP_409_CONFLICT,
)

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
    require_auth_guard,
    verify_password,
)
from src.lib.dependencies import DBSession
from src.lib.rate_limit import rate_limit
from src.lib.token_store import revoke, revoke_if_not_revoked
from src.users.model import User, UserResponse


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


class AuthController(Controller):
    """Email/password authentication, token lifecycle, and profile endpoints."""

    path = "/"

    @post(
        "/register",
        status_code=HTTP_201_CREATED,
        operation_id="register_api_auth_register_post",
    )
    @rate_limit(requests=5, window=60)
    async def register(
        self,
        request: Request[Any, Any, Any],
        data: JSONBody[RegisterRequest],
        db: DBSession,
    ) -> TokenResponse:
        """Register with email/password and issue backend tokens."""
        existing_user = await _get_user_by_email(db, data.email)
        if existing_user:
            raise HTTPException(
                status_code=HTTP_409_CONFLICT,
                detail="Email already registered",
            )

        user = await _create_user(
            db,
            email=data.email,
            name=data.name,
            email_verified=False,
            password_hash=hash_password(data.password),
        )

        return _issue_tokens(user)

    @post(
        "/login",
        status_code=HTTP_200_OK,
        operation_id="login_api_auth_login_post",
    )
    @rate_limit(requests=5, window=60)
    async def login(
        self,
        request: Request[Any, Any, Any],
        data: JSONBody[EmailLoginRequest],
        db: DBSession,
    ) -> TokenResponse:
        """Login with email/password and issue first-party tokens."""
        user = await _get_user_by_email(db, data.email)
        if not user or not verify_password(data.password, user.password_hash):
            raise HTTPException(
                status_code=HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )
        return _issue_tokens(user)

    @post(
        "/refresh",
        status_code=HTTP_200_OK,
        operation_id="refresh_token_api_auth_refresh_post",
    )
    @rate_limit(requests=5, window=60)
    async def refresh_token(
        self,
        request: Request[Any, Any, Any],
        data: JSONBody[RefreshTokenRequest],
        db: DBSession,
    ) -> TokenResponse:
        """Refresh access token using refresh token (with rotation)."""
        payload = decode_token(data.refresh_token)

        if payload.token_type != "refresh":  # noqa: S105
            raise HTTPException(
                status_code=HTTP_401_UNAUTHORIZED,
                detail="Invalid token type",
            )

        # Atomically claim the refresh token — first caller wins, replays are rejected.
        now_ts = int(datetime.now(UTC).timestamp())
        remaining_ttl = max(0, payload.exp - now_ts)
        claimed = await revoke_if_not_revoked(payload.jti, remaining_ttl)
        if not claimed:
            raise HTTPException(
                status_code=HTTP_401_UNAUTHORIZED,
                detail="Token has been revoked",
                headers={"WWW-Authenticate": "Bearer"},
            )

        from sqlalchemy import select

        result = await db.execute(select(User).where(User.id == UUID(payload.user_id)))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(
                status_code=HTTP_401_UNAUTHORIZED,
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

    @post(
        "/logout",
        status_code=HTTP_204_NO_CONTENT,
        guards=[require_auth_guard],
        operation_id="logout_api_auth_logout_post",
    )
    async def logout(
        self,
        current_user: CurrentUser,
        request: Request[Any, Any, Any],
        data: JSONBody[RefreshTokenRequest],
    ) -> None:
        """Logout: revoke both the access token and the refresh token."""
        _ = current_user
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

        try:
            refresh_payload = decode_token(data.refresh_token)
            now_ts = int(datetime.now(UTC).timestamp())
            refresh_ttl = max(0, refresh_payload.exp - now_ts)
            await revoke(refresh_payload.jti, refresh_ttl)
        except HTTPException:
            pass  # Token already invalid — nothing to revoke

        return None

    @get(
        "/me",
        status_code=HTTP_200_OK,
        guards=[require_auth_guard],
        operation_id="get_me_api_auth_me_get",
    )
    async def get_me(
        self,
        current_user: CurrentUser,
        db: DBSession,
    ) -> UserResponse:
        """Return the current authenticated user."""
        from sqlalchemy import select

        result = await db.execute(select(User).where(User.id == UUID(current_user.id)))
        user = result.scalar_one_or_none()

        if not user:
            raise HTTPException(
                status_code=HTTP_401_UNAUTHORIZED,
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


class OAuthController(Controller):
    """OAuth 2.0 Authorization Code + PKCE endpoints."""

    path = "/oauth"

    @get(
        "/{provider:str}/authorize",
        status_code=HTTP_302_FOUND,
        operation_id="oauth_authorize_api_auth_oauth__provider__authorize_get",
    )
    @rate_limit(requests=5, window=60)
    async def oauth_authorize(
        self,
        request: Request[Any, Any, Any],
        provider: FromPath[OAuthProvider],
        redirect_uri: FromQuery[str],
        return_to: FromQuery[str] = "/",
        code_challenge: FromQuery[str | None] = None,
        code_challenge_method: FromQuery[str | None] = None,
    ) -> Redirect:
        """Start an OAuth Authorization Code + PKCE transaction."""
        authorization_url = await create_authorization_url(
            provider,
            redirect_uri,
            return_to,
            client_code_challenge=code_challenge,
            client_code_challenge_method=code_challenge_method,
        )
        return Redirect(path=authorization_url, status_code=HTTP_302_FOUND)

    @get(
        "/{provider:str}/callback",
        status_code=HTTP_302_FOUND,
        operation_id="oauth_callback_api_auth_oauth__provider__callback_get",
    )
    async def oauth_callback(
        self,
        provider: FromPath[OAuthProvider],
        db: DBSession,
        oauth_state: Annotated[str, QueryParameter(name="state")],
        code: FromQuery[str | None] = None,
        error: FromQuery[str | None] = None,
    ) -> Redirect:
        """Handle the provider callback and redirect with a one-time login code."""
        if error or not code:
            redirect_uri, return_to = await cancel_oauth_callback(
                provider=provider, state=oauth_state
            )
            separator = "&" if "?" in redirect_uri else "?"
            query = urlencode(
                {"error": error or "access_denied", "return_to": return_to}
            )
            return Redirect(
                path=f"{redirect_uri}{separator}{query}", status_code=HTTP_302_FOUND
            )

        repository = AuthRepository(db)
        exchange_code, redirect_uri, return_to = await complete_oauth_callback(
            repository, provider=provider, code=code, state=oauth_state
        )
        separator = "&" if "?" in redirect_uri else "?"
        query = urlencode({"code": exchange_code, "return_to": return_to})
        return Redirect(
            path=f"{redirect_uri}{separator}{query}", status_code=HTTP_302_FOUND
        )

    @post(
        "/exchange",
        status_code=HTTP_200_OK,
        operation_id="oauth_exchange_api_auth_oauth_exchange_post",
    )
    @rate_limit(requests=10, window=60)
    async def oauth_exchange(
        self,
        request: Request[Any, Any, Any],
        data: JSONBody[OAuthExchangeRequest],
    ) -> TokenResponse:
        """Exchange a single-use OAuth code for access and refresh tokens."""
        user_id = await consume_exchange_code(data.code, data.code_verifier)
        from src.lib.auth import create_access_token, create_refresh_token

        return TokenResponse(
            access_token=create_access_token(user_id),
            refresh_token=create_refresh_token(user_id),
        )


class PasskeyController(Controller):
    """WebAuthn passkey registration and authentication endpoints."""

    path = "/passkeys"

    @post(
        "/register/options",
        status_code=HTTP_200_OK,
        guards=[require_auth_guard],
        operation_id="passkey_registration_options_api_auth_passkeys_register_options_post",
    )
    @rate_limit(requests=10, window=60)
    async def passkey_registration_options(
        self,
        current_user: CurrentUser,
        request: Request[Any, Any, Any],
        db: DBSession,
    ) -> dict[str, object]:
        """Create options for registering a passkey to the signed-in account."""
        return await create_registration_options(AuthRepository(db), current_user.id)

    @post(
        "/register/verify",
        status_code=HTTP_204_NO_CONTENT,
        guards=[require_auth_guard],
        operation_id="passkey_registration_verify_api_auth_passkeys_register_verify_post",
    )
    @rate_limit(requests=10, window=60)
    async def passkey_registration_verify(
        self,
        current_user: CurrentUser,
        request: Request[Any, Any, Any],
        data: JSONBody[PasskeyRegistrationVerifyRequest],
        db: DBSession,
    ) -> None:
        """Verify and store a new passkey."""
        await verify_registration(
            AuthRepository(db),
            user_id=current_user.id,
            ceremony_id=data.ceremony_id,
            credential=data.credential,
        )
        return None

    @post(
        "/authenticate/options",
        status_code=HTTP_200_OK,
        operation_id="passkey_authentication_options_api_auth_passkeys_authenticate_options_post",
    )
    @rate_limit(requests=10, window=60)
    async def passkey_authentication_options(
        self,
        request: Request[Any, Any, Any],
        data: JSONBody[PasskeyAuthenticationOptionsRequest],
        db: DBSession,
    ) -> dict[str, object]:
        """Create options for signing in with a passkey."""
        return await create_authentication_options(AuthRepository(db), data.email)

    @post(
        "/authenticate/verify",
        status_code=HTTP_200_OK,
        operation_id="passkey_authentication_verify_api_auth_passkeys_authenticate_verify_post",
    )
    @rate_limit(requests=10, window=60)
    async def passkey_authentication_verify(
        self,
        request: Request[Any, Any, Any],
        data: JSONBody[PasskeyAuthenticationVerifyRequest],
        db: DBSession,
    ) -> TokenResponse:
        """Verify a passkey assertion and issue first-party tokens."""
        return await verify_authentication(
            AuthRepository(db),
            ceremony_id=data.ceremony_id,
            credential=data.credential,
        )


router = Router(
    path="/api/auth",
    tags=["authentication"],
    route_handlers=[
        AuthController,
        OAuthController,
        PasskeyController,
    ],
)
