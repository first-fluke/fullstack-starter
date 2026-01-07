from collections.abc import Callable
from functools import wraps
from typing import Annotated, Any, Literal

import httpx
from fastapi import Depends, HTTPException, Request, status
from pydantic import BaseModel

from src.lib.config import settings


class SessionUser(BaseModel):
    """User from better-auth session."""

    id: str
    name: str | None = None
    email: str
    email_verified: bool = False
    image: str | None = None
    created_at: str
    updated_at: str


class Session(BaseModel):
    """Session from better-auth."""

    id: str
    user_id: str
    expires_at: str
    token: str
    created_at: str
    updated_at: str
    ip_address: str | None = None
    user_agent: str | None = None


class SessionResponse(BaseModel):
    """Response from better-auth /api/auth/get-session."""

    session: Session
    user: SessionUser


async def get_session(request: Request) -> SessionResponse | None:
    """Validate session with better-auth server.

    This calls the better-auth server to validate the session cookie.
    """
    cookies = request.cookies
    if not cookies:
        return None

    async with httpx.AsyncClient() as client:
        try:
            response = await client.get(
                f"{settings.BETTER_AUTH_URL}/api/auth/get-session",
                cookies=dict(cookies),
                timeout=5.0,
            )
            if response.status_code != 200:
                return None

            data = response.json()
            if not data or not data.get("session"):
                return None

            return SessionResponse(**data)
        except (httpx.RequestError, Exception):
            return None


async def get_optional_session(request: Request) -> SessionResponse | None:
    """Get session if exists, otherwise return None."""
    return await get_session(request)


async def get_required_session(request: Request) -> SessionResponse:
    """Get session or raise 401 if not authenticated."""
    session = await get_session(request)
    if not session:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return session


async def get_current_user(request: Request) -> SessionUser:
    """Get current authenticated user or raise 401."""
    session = await get_required_session(request)
    return session.user


async def get_optional_user(request: Request) -> SessionUser | None:
    """Get current user if authenticated, otherwise None."""
    session = await get_optional_session(request)
    return session.user if session else None


# Type aliases for dependency injection
OptionalSession = Annotated[SessionResponse | None, Depends(get_optional_session)]
RequiredSession = Annotated[SessionResponse, Depends(get_required_session)]
CurrentUser = Annotated[SessionUser, Depends(get_current_user)]
OptionalUser = Annotated[SessionUser | None, Depends(get_optional_user)]


def require_auth(
    func: Callable[..., Any] | None = None,
) -> Callable[..., Any]:
    """Decorator to require authentication on a route.

    Usage:
        @router.get("/protected")
        @require_auth
        async def protected_route(user: CurrentUser):
            return {"user": user}
    """

    def decorator(f: Callable[..., Any]) -> Callable[..., Any]:
        @wraps(f)
        async def wrapper(*args: Any, **kwargs: Any) -> Any:
            return await f(*args, **kwargs)

        return wrapper

    if func is not None:
        return decorator(func)
    return decorator
