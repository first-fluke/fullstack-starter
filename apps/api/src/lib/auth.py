import json
from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from functools import wraps
from typing import Any, Literal
from uuid import uuid4

import bcrypt
import msgspec
from jwcrypto import jwe, jwk
from jwcrypto.common import JWException
from litestar import Request
from litestar.connection import ASGIConnection
from litestar.di import NamedDependency
from litestar.exceptions import HTTPException
from litestar.handlers.base import BaseRouteHandler
from litestar.middleware.authentication import (
    AbstractAuthenticationMiddleware,
    AuthenticationResult,
)
from litestar.status_codes import HTTP_400_BAD_REQUEST, HTTP_401_UNAUTHORIZED

from src.lib.config import settings


class TokenPayload(msgspec.Struct):
    """JWT/JWE token payload."""

    user_id: str
    token_type: Literal["access", "refresh"]
    exp: int
    iat: int
    jti: str


class TokenResponse(msgspec.Struct):
    """Token response."""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"  # noqa: S105


class EmailLoginRequest(msgspec.Struct):
    """Email/password login request."""

    email: str
    password: str


class RegisterRequest(msgspec.Struct):
    """Email/password registration request."""

    email: str
    password: str
    name: str | None = None


class RefreshTokenRequest(msgspec.Struct):
    """Refresh token request."""

    refresh_token: str


class OAuthUserInfo(msgspec.Struct):
    """OAuth user information from provider."""

    id: str
    email: str | None = None
    name: str | None = None
    image: str | None = None
    email_verified: bool = False


class CurrentUserInfo(msgspec.Struct):
    """Current authenticated user info."""

    id: str
    email: str | None = None
    name: str | None = None
    image: str | None = None
    email_verified: bool = False


def normalize_email(email: str) -> str:
    """Normalize email for storage and lookup."""
    return email.strip().lower()


def validate_password_strength(password: str) -> None:
    """Validate password minimum requirements."""
    if len(password) < 8:
        raise HTTPException(
            status_code=HTTP_400_BAD_REQUEST,
            detail="Password must be at least 8 characters long",
        )


def hash_password(password: str) -> str:
    """Hash a password with bcrypt."""
    validate_password_strength(password)
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, password_hash: str | None) -> bool:
    """Verify a password against a stored bcrypt hash."""
    if not password_hash:
        return False
    try:
        return bcrypt.checkpw(password.encode("utf-8"), password_hash.encode("utf-8"))
    except ValueError:
        return False


def _get_jwe_key() -> jwk.JWK:
    """Get JWK key for JWE encryption/decryption."""
    key_bytes = settings.JWE_SECRET_KEY.encode("utf-8")
    if len(key_bytes) < 32:
        key_bytes = key_bytes.ljust(32, b"\0")
    elif len(key_bytes) > 32:
        key_bytes = key_bytes[:32]
    return jwk.JWK(kty="oct", k=jwk.base64url_encode(key_bytes))


def create_access_token(user_id: str) -> str:
    """Create JWE access token."""
    now = datetime.now(UTC)
    payload = {
        "user_id": user_id,
        "token_type": "access",
        "exp": int((now + timedelta(hours=1)).timestamp()),
        "iat": int(now.timestamp()),
        "jti": str(uuid4()),
    }

    key = _get_jwe_key()
    jwe_token = jwe.JWE(
        json.dumps(payload).encode("utf-8"),
        recipient=key,
        protected={"alg": "A256KW", "enc": "A256GCM"},
    )
    return str(jwe_token.serialize(compact=True))


def create_refresh_token(user_id: str) -> str:
    """Create JWE refresh token."""
    now = datetime.now(UTC)
    payload = {
        "user_id": user_id,
        "token_type": "refresh",
        "exp": int((now + timedelta(days=7)).timestamp()),
        "iat": int(now.timestamp()),
        "jti": str(uuid4()),
    }

    key = _get_jwe_key()
    jwe_token = jwe.JWE(
        json.dumps(payload).encode("utf-8"),
        recipient=key,
        protected={"alg": "A256KW", "enc": "A256GCM"},
    )
    return str(jwe_token.serialize(compact=True))


def decode_token(token: str) -> TokenPayload:
    """Decode and validate JWE token."""
    try:
        key = _get_jwe_key()
        jwe_token = jwe.JWE()
        jwe_token.deserialize(token)
        jwe_token.decrypt(key)
        return msgspec.json.decode(jwe_token.payload, type=TokenPayload)
    except JWException:
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None
    except Exception:
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
            headers={"WWW-Authenticate": "Bearer"},
        ) from None


async def _authenticate_connection(
    connection: ASGIConnection[Any, Any, Any, Any],
) -> tuple[CurrentUserInfo, TokenPayload]:
    """Validate the Authorization Bearer token on an ASGIConnection."""
    auth_header = connection.headers.get("Authorization")
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )

    token = auth_header.replace("Bearer ", "")
    payload = decode_token(token)

    if payload.token_type != "access":  # noqa: S105
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
        )

    if datetime.now(UTC).timestamp() > payload.exp:
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Token expired",
            headers={"WWW-Authenticate": "Bearer"},
        )

    from src.lib.token_store import is_revoked

    if await is_revoked(payload.jti):
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return CurrentUserInfo(id=payload.user_id), payload


class JWEAuthenticationMiddleware(AbstractAuthenticationMiddleware):
    """Litestar middleware that populates ``request.user`` and ``request.auth``.

    When a valid Bearer JWE access token is present, ``scope['user']`` is set to
    ``CurrentUserInfo`` and ``scope['auth']`` is set to ``TokenPayload``.
    Unauthenticated requests set both to ``None`` so public routes remain accessible
    while protected routes enforce auth via ``require_auth_guard`` or ``CurrentUser``.
    """

    async def authenticate_request(
        self, connection: ASGIConnection[Any, Any, Any, Any]
    ) -> AuthenticationResult:
        auth_header = connection.headers.get("Authorization")
        if not auth_header or not auth_header.startswith("Bearer "):
            return AuthenticationResult(user=None, auth=None)
        try:
            user, payload = await _authenticate_connection(connection)
            return AuthenticationResult(user=user, auth=payload)
        except HTTPException:
            return AuthenticationResult(user=None, auth=None)


async def require_auth_guard(
    connection: ASGIConnection[Any, Any, Any, Any],
    _: BaseRouteHandler,
) -> None:
    """Litestar Guard that enforces a valid Bearer access token on a route."""
    user = connection.scope.get("user")
    if isinstance(user, CurrentUserInfo):
        return
    user, payload = await _authenticate_connection(connection)
    connection.scope["user"] = user
    connection.scope["auth"] = payload


async def get_current_user(request: Request[Any, Any, Any]) -> CurrentUserInfo:
    """Get current authenticated user from request scope or Authorization header."""
    user = request.scope.get("user")
    if isinstance(user, CurrentUserInfo):
        return user
    user, payload = await _authenticate_connection(request)
    request.scope["user"] = user
    request.scope["auth"] = payload
    return user


async def get_optional_user(
    request: Request[Any, Any, Any],
) -> CurrentUserInfo | None:
    """Get current user if authenticated, otherwise None."""
    user = request.scope.get("user")
    if isinstance(user, CurrentUserInfo):
        return user
    try:
        return await get_current_user(request)
    except HTTPException:
        return None


CurrentUser = NamedDependency[CurrentUserInfo]
OptionalUser = NamedDependency[CurrentUserInfo | None]


def require_auth(
    func: Callable[..., Any] | None = None,
) -> Callable[..., Any]:
    """Decorator to require authentication on a route."""

    def decorator(f: Callable[..., Any]) -> Callable[..., Any]:
        @wraps(f)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            return await f(*args, **kwargs)

        wrapper.__annotations__ = dict(f.__annotations__)
        return wrapper

    if func is not None:
        return decorator(func)
    return decorator
