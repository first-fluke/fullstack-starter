"""Google OIDC token verification guard and dependency."""

from typing import Any

from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2.id_token import verify_oauth2_token
from litestar import Request
from litestar.connection import ASGIConnection
from litestar.exceptions import HTTPException
from litestar.handlers.base import BaseRouteHandler
from litestar.status_codes import (
    HTTP_401_UNAUTHORIZED,
    HTTP_500_INTERNAL_SERVER_ERROR,
)

from src.lib.config import settings


async def _verify_connection_oidc(
    connection: ASGIConnection[Any, Any, Any, Any],
) -> None:
    if not settings.WORKER_VERIFY_OIDC:
        return

    # Defensive runtime guard — the pydantic validator blocks this at startup,
    # but a runtime settings override (e.g. in tests) could bypass it.
    if not settings.WORKER_OIDC_AUDIENCE:
        raise HTTPException(
            status_code=HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "OIDC verification is enabled but WORKER_OIDC_AUDIENCE is not "
                "configured. Set WORKER_OIDC_AUDIENCE in the environment."
            ),
        )

    auth_header = connection.headers.get("Authorization", "")
    if not auth_header.startswith("Bearer "):
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    token = auth_header.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    audience = settings.WORKER_OIDC_AUDIENCE

    try:
        verify_oauth2_token(token, GoogleRequest(), audience=audience)
    except Exception as exc:
        raise HTTPException(
            status_code=HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired OIDC token",
        ) from exc


async def verify_oidc_guard(
    connection: ASGIConnection[Any, Any, Any, Any],
    _: BaseRouteHandler,
) -> None:
    """Validate a Google-signed OIDC token when WORKER_VERIFY_OIDC is enabled."""
    await _verify_connection_oidc(connection)


async def verify_oidc_token(
    request: Request[Any, Any, Any],
) -> None:
    """Validate a Google-signed OIDC token when WORKER_VERIFY_OIDC is enabled."""
    await _verify_connection_oidc(request)
