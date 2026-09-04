"""OAuth 2.0 Authorization Code + PKCE orchestration."""

import base64
import hashlib
import re
import secrets
from dataclasses import dataclass
from typing import Any
from urllib.parse import urlencode, urlparse

import httpx
from fastapi import HTTPException, status

from src.auth.ephemeral_store import ephemeral_auth_store
from src.auth.repository import AuthRepository
from src.auth.schemas import OAuthProvider
from src.lib.auth import OAuthUserInfo
from src.lib.config import settings

_OAUTH_STATE_TTL = 600
_OAUTH_CODE_TTL = 60


@dataclass(frozen=True)
class OAuthProviderConfig:
    client_id: str
    client_secret: str
    authorization_url: str
    token_url: str
    userinfo_url: str
    scopes: tuple[str, ...]
    pkce: bool = False


def _provider_config(provider: OAuthProvider) -> OAuthProviderConfig:
    configs: dict[OAuthProvider, OAuthProviderConfig | None] = {
        "google": OAuthProviderConfig(
            client_id=settings.GOOGLE_CLIENT_ID or "",
            client_secret=settings.GOOGLE_CLIENT_SECRET or "",
            authorization_url="https://accounts.google.com/o/oauth2/v2/auth",
            token_url="https://oauth2.googleapis.com/token",  # noqa: S106
            userinfo_url="https://openidconnect.googleapis.com/v1/userinfo",
            scopes=("openid", "email", "profile"),
            pkce=True,
        ),
        "github": OAuthProviderConfig(
            client_id=settings.GITHUB_CLIENT_ID or "",
            client_secret=settings.GITHUB_CLIENT_SECRET or "",
            authorization_url="https://github.com/login/oauth/authorize",
            token_url="https://github.com/login/oauth/access_token",  # noqa: S106
            userinfo_url="https://api.github.com/user",
            scopes=("read:user", "user:email"),
            pkce=True,
        ),
        "facebook": OAuthProviderConfig(
            client_id=settings.FACEBOOK_CLIENT_ID or "",
            client_secret=settings.FACEBOOK_CLIENT_SECRET or "",
            authorization_url="https://www.facebook.com/dialog/oauth",
            token_url="https://graph.facebook.com/oauth/access_token",  # noqa: S106
            userinfo_url=("https://graph.facebook.com/me?fields=id,name,email,picture"),
            scopes=("email", "public_profile"),
        ),
    }
    config = configs[provider]
    if config is None or not config.client_id or not config.client_secret:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"OAuth provider is not configured: {provider}",
        )
    return config


def _callback_url(provider: OAuthProvider) -> str:
    return f"{settings.API_PUBLIC_URL.rstrip('/')}/api/auth/oauth/{provider}/callback"


def _validate_redirect_uri(redirect_uri: str) -> bool:
    parsed = urlparse(redirect_uri)
    origin = f"{parsed.scheme}://{parsed.netloc}"
    path_parts = [part for part in parsed.path.split("/") if part]
    valid_web_path = path_parts == ["auth", "callback"] or (
        len(path_parts) == 3 and path_parts[1:] == ["auth", "callback"]
    )
    valid_web = (
        parsed.scheme in {"http", "https"}
        and origin in settings.OAUTH_ALLOWED_WEB_ORIGINS
        and valid_web_path
        and not parsed.query
        and not parsed.fragment
    )
    valid_mobile = redirect_uri in settings.OAUTH_ALLOWED_MOBILE_REDIRECT_URIS
    if not valid_web and not valid_mobile:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="OAuth redirect URI is not allowed",
        )
    return valid_mobile


def _validate_return_to(return_to: str) -> None:
    if not return_to.startswith("/") or return_to.startswith("//"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="return_to must be an application-relative path",
        )


async def create_authorization_url(
    provider: OAuthProvider,
    redirect_uri: str,
    return_to: str,
    client_code_challenge: str | None = None,
    client_code_challenge_method: str | None = None,
) -> str:
    """Create the provider authorization URL and persist the PKCE transaction."""
    is_mobile = _validate_redirect_uri(redirect_uri)
    _validate_return_to(return_to)
    if is_mobile and (
        client_code_challenge_method != "S256"
        or client_code_challenge is None
        or re.fullmatch(r"[A-Za-z0-9_-]{43}", client_code_challenge) is None
    ):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mobile OAuth requires an S256 client code challenge",
        )
    config = _provider_config(provider)
    state = secrets.token_urlsafe(32)
    verifier = secrets.token_urlsafe(64) if config.pkce else None
    await ephemeral_auth_store.put(
        "oauth-state",
        state,
        {
            "provider": provider,
            "verifier": verifier,
            "redirect_uri": redirect_uri,
            "return_to": return_to,
            "client_code_challenge": client_code_challenge,
        },
        _OAUTH_STATE_TTL,
    )
    params: dict[str, str] = {
        "client_id": config.client_id,
        "redirect_uri": _callback_url(provider),
        "response_type": "code",
        "scope": " ".join(config.scopes),
        "state": state,
    }
    if verifier:
        challenge = (
            base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest())
            .rstrip(b"=")
            .decode()
        )
        params["code_challenge"] = challenge
        params["code_challenge_method"] = "S256"
    return f"{config.authorization_url}?{urlencode(params)}"


async def complete_oauth_callback(
    repository: AuthRepository,
    *,
    provider: OAuthProvider,
    code: str,
    state: str,
) -> tuple[str, str, str]:
    """Validate a callback, resolve a local user, and mint a one-time code."""
    transaction = await ephemeral_auth_store.take("oauth-state", state)
    if transaction is None or transaction.get("provider") != provider:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OAuth state",
        )
    config = _provider_config(provider)
    async with httpx.AsyncClient(timeout=10.0) as client:
        token_data = {
            "client_id": config.client_id,
            "client_secret": config.client_secret,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": _callback_url(provider),
        }
        verifier = transaction.get("verifier")
        if verifier:
            token_data["code_verifier"] = verifier
        token_response = await client.post(
            config.token_url,
            data=token_data,
            headers={"Accept": "application/json"},
        )
        if token_response.status_code >= 400:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="OAuth authorization code exchange failed",
            )
        access_token = token_response.json().get("access_token")
        if not access_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="OAuth provider did not return an access token",
            )
        user_info = await _fetch_user_info(client, provider, config, access_token)

    user = await repository.get_oauth_user(provider, user_info.id)
    if user is None:
        if not user_info.email and provider != "facebook":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="OAuth provider did not return an email address",
            )
        email = user_info.email or f"facebook_{user_info.id}@oauth.placeholder"
        user = await repository.get_user_by_email(email)
        if user is not None and not user_info.email_verified:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Sign in first, then link this OAuth account",
            )
        if user is None:
            user = await repository.create_user(
                email=email,
                name=user_info.name,
                image=user_info.image,
                email_verified=user_info.email_verified,
            )
        await repository.link_oauth_identity(
            user_id=user.id, provider=provider, subject=user_info.id
        )

    exchange_code = secrets.token_urlsafe(48)
    await ephemeral_auth_store.put(
        "oauth-code",
        exchange_code,
        {
            "user_id": str(user.id),
            "client_code_challenge": transaction.get("client_code_challenge"),
        },
        _OAUTH_CODE_TTL,
    )
    return (
        exchange_code,
        str(transaction["redirect_uri"]),
        str(transaction["return_to"]),
    )


async def cancel_oauth_callback(
    *, provider: OAuthProvider, state: str
) -> tuple[str, str]:
    """Consume a denied OAuth transaction and recover its safe redirect target."""
    transaction = await ephemeral_auth_store.take("oauth-state", state)
    if transaction is None or transaction.get("provider") != provider:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OAuth state",
        )
    return str(transaction["redirect_uri"]), str(transaction["return_to"])


async def consume_exchange_code(code: str, code_verifier: str | None = None) -> str:
    payload = await ephemeral_auth_store.take("oauth-code", code)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired OAuth exchange code",
        )
    expected_challenge = payload.get("client_code_challenge")
    if expected_challenge:
        if not code_verifier:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="OAuth exchange code verifier is required",
            )
        actual_challenge = (
            base64.urlsafe_b64encode(hashlib.sha256(code_verifier.encode()).digest())
            .rstrip(b"=")
            .decode()
        )
        if not secrets.compare_digest(str(expected_challenge), actual_challenge):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="OAuth exchange code verifier is invalid",
            )
    return str(payload["user_id"])


async def _fetch_user_info(
    client: httpx.AsyncClient,
    provider: OAuthProvider,
    config: OAuthProviderConfig,
    access_token: str,
) -> OAuthUserInfo:
    response = await client.get(
        config.userinfo_url,
        headers={
            "Authorization": f"Bearer {access_token}",
            "Accept": "application/json",
        },
    )
    if response.status_code >= 400:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="OAuth user information request failed",
        )
    data: dict[str, Any] = response.json()
    if provider == "google":
        return OAuthUserInfo(
            id=str(data["sub"]),
            email=data.get("email"),
            name=data.get("name"),
            image=data.get("picture"),
            email_verified=bool(data.get("email_verified")),
        )
    if provider == "github":
        email = data.get("email")
        verified = False
        if not email:
            email_response = await client.get(
                "https://api.github.com/user/emails",
                headers={
                    "Authorization": f"Bearer {access_token}",
                    "Accept": "application/vnd.github+json",
                },
            )
            if email_response.status_code < 400:
                emails = email_response.json()
                selected = next(
                    (
                        item
                        for item in emails
                        if item.get("primary") and item.get("verified")
                    ),
                    None,
                )
                if selected:
                    email = selected.get("email")
                    verified = True
        else:
            verified = True
        return OAuthUserInfo(
            id=str(data["id"]),
            email=email,
            name=data.get("name") or data.get("login"),
            image=data.get("avatar_url"),
            email_verified=verified,
        )
    picture = data.get("picture", {}).get("data", {}).get("url")
    return OAuthUserInfo(
        id=str(data["id"]),
        email=data.get("email"),
        name=data.get("name"),
        image=picture,
        email_verified=False,
    )
