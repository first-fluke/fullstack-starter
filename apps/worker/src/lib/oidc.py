"""Google OIDC token verification dependency."""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2.id_token import verify_oauth2_token

from src.lib.config import settings

_http_bearer = HTTPBearer(auto_error=False)


async def verify_oidc_token(
    credentials: HTTPAuthorizationCredentials | None = Depends(_http_bearer),
) -> None:
    """Validate a Google-signed OIDC token when WORKER_VERIFY_OIDC is enabled.

    When WORKER_VERIFY_OIDC is False (default / local dev), this dependency is a
    no-op.  When True, the Bearer token in the Authorization header is verified
    against Google's public keys with the expected audience
    ``settings.WORKER_OIDC_AUDIENCE``.

    Fails closed at request time: if verification is enabled but the audience
    is somehow empty (e.g. overridden after startup), a 500 is returned rather
    than silently skipping audience validation.
    """
    if not settings.WORKER_VERIFY_OIDC:
        return

    # Defensive runtime guard — the pydantic validator blocks this at startup,
    # but a runtime settings override (e.g. in tests) could bypass it.
    if not settings.WORKER_OIDC_AUDIENCE:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=(
                "OIDC verification is enabled but WORKER_OIDC_AUDIENCE is not "
                "configured. Set WORKER_OIDC_AUDIENCE in the environment."
            ),
        )

    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing Authorization header",
        )

    token = credentials.credentials
    audience = settings.WORKER_OIDC_AUDIENCE

    try:
        verify_oauth2_token(token, GoogleRequest(), audience=audience)
    except Exception as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired OIDC token",
        ) from exc
