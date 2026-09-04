"""OAuth PKCE and passkey endpoint integration tests."""

import base64
import hashlib
from urllib.parse import parse_qs, urlparse

import httpx
import pytest
from fastapi.testclient import TestClient

import src.lib.rate_limit as rate_limit_module
from src.auth.ephemeral_store import ephemeral_auth_store
from src.lib.config import settings


class _FakeOAuthClient:
    async def __aenter__(self) -> "_FakeOAuthClient":
        return self

    async def __aexit__(self, *_args: object) -> None:
        return None

    async def post(self, url: str, **_kwargs: object) -> httpx.Response:
        assert url == "https://oauth2.googleapis.com/token"
        return httpx.Response(200, json={"access_token": "provider-access-token"})

    async def get(self, url: str, **_kwargs: object) -> httpx.Response:
        assert url == "https://openidconnect.googleapis.com/v1/userinfo"
        return httpx.Response(
            200,
            json={
                "sub": "google-subject-1",
                "email": "oauth@example.com",
                "name": "OAuth User",
                "email_verified": True,
            },
        )


class _FakeFacebookClient:
    async def __aenter__(self) -> "_FakeFacebookClient":
        return self

    async def __aexit__(self, *_args: object) -> None:
        return None

    async def post(self, url: str, **kwargs: object) -> httpx.Response:
        assert url == "https://graph.facebook.com/oauth/access_token"
        data = kwargs["data"]
        assert isinstance(data, dict)
        assert "code_verifier" not in data
        return httpx.Response(200, json={"access_token": "facebook-access-token"})

    async def get(self, url: str, **_kwargs: object) -> httpx.Response:
        assert url == "https://graph.facebook.com/me?fields=id,name,email,picture"
        return httpx.Response(
            200,
            json={
                "id": "facebook-subject-no-email",
                "name": "Facebook User",
                "picture": {"data": {"url": "https://example.com/avatar.png"}},
            },
        )


def _configure_google(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "GOOGLE_CLIENT_ID", "google-client-id")
    monkeypatch.setattr(settings, "GOOGLE_CLIENT_SECRET", "google-client-secret")
    ephemeral_auth_store.clear()
    rate_limit_module._rate_limiter_registry.clear()


def _configure_facebook(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "FACEBOOK_CLIENT_ID", "facebook-client-id")
    monkeypatch.setattr(settings, "FACEBOOK_CLIENT_SECRET", "facebook-client-secret")
    ephemeral_auth_store.clear()
    rate_limit_module._rate_limiter_registry.clear()


def _configure_github(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "GITHUB_CLIENT_ID", "github-client-id")
    monkeypatch.setattr(settings, "GITHUB_CLIENT_SECRET", "github-client-secret")
    ephemeral_auth_store.clear()
    rate_limit_module._rate_limiter_registry.clear()


def test_oauth_pkce_callback_and_single_use_exchange(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    _configure_google(monkeypatch)
    monkeypatch.setattr(httpx, "AsyncClient", lambda **_kwargs: _FakeOAuthClient())

    start = client.get(
        "/api/auth/oauth/google/authorize",
        params={
            "redirect_uri": "http://localhost:3000/ko/auth/callback",
            "return_to": "/dashboard",
        },
        follow_redirects=False,
    )
    assert start.status_code == 302
    provider_query = parse_qs(urlparse(start.headers["location"]).query)
    assert provider_query["code_challenge_method"] == ["S256"]
    assert len(provider_query["code_challenge"][0]) == 43

    callback = client.get(
        "/api/auth/oauth/google/callback",
        params={"code": "provider-code", "state": provider_query["state"][0]},
        follow_redirects=False,
    )
    assert callback.status_code == 302
    callback_query = parse_qs(urlparse(callback.headers["location"]).query)
    assert callback_query["return_to"] == ["/dashboard"]

    exchange = client.post(
        "/api/auth/oauth/exchange", json={"code": callback_query["code"][0]}
    )
    assert exchange.status_code == 200
    assert exchange.json()["access_token"]

    replay = client.post(
        "/api/auth/oauth/exchange", json={"code": callback_query["code"][0]}
    )
    assert replay.status_code == 401


def test_github_authorization_uses_pkce(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    _configure_github(monkeypatch)
    response = client.get(
        "/api/auth/oauth/github/authorize",
        params={"redirect_uri": "http://localhost:3000/ko/auth/callback"},
        follow_redirects=False,
    )

    assert response.status_code == 302
    provider_query = parse_qs(urlparse(response.headers["location"]).query)
    assert provider_query["code_challenge_method"] == ["S256"]
    assert len(provider_query["code_challenge"][0]) == 43


def test_oauth_rejects_untrusted_redirect(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    _configure_google(monkeypatch)
    response = client.get(
        "/api/auth/oauth/google/authorize",
        params={"redirect_uri": "https://attacker.example/auth/callback"},
        follow_redirects=False,
    )
    assert response.status_code == 400


def test_mobile_oauth_requires_client_pkce(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    _configure_google(monkeypatch)
    missing = client.get(
        "/api/auth/oauth/google/authorize",
        params={"redirect_uri": "fullstackstarter://auth/callback"},
        follow_redirects=False,
    )
    assert missing.status_code == 400

    verifier = "mobile-verifier-abcdefghijklmnopqrstuvwxyz-0123456789"
    challenge = (
        base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest())
        .rstrip(b"=")
        .decode()
    )
    accepted = client.get(
        "/api/auth/oauth/google/authorize",
        params={
            "redirect_uri": "fullstackstarter://auth/callback",
            "code_challenge": challenge,
            "code_challenge_method": "S256",
        },
        follow_redirects=False,
    )
    assert accepted.status_code == 302


@pytest.mark.anyio
async def test_mobile_exchange_code_is_bound_to_verifier(client: TestClient) -> None:
    ephemeral_auth_store.clear()
    verifier = "mobile-verifier-abcdefghijklmnopqrstuvwxyz-0123456789"
    challenge = (
        base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest())
        .rstrip(b"=")
        .decode()
    )
    exchange_code = "mobile-exchange-code-abcdefghijklmnopqrstuvwxyz"
    await ephemeral_auth_store.put(
        "oauth-code",
        exchange_code,
        {
            "user_id": "00000000-0000-0000-0000-000000000001",
            "client_code_challenge": challenge,
        },
        60,
    )

    response = client.post(
        "/api/auth/oauth/exchange",
        json={"code": exchange_code, "code_verifier": verifier},
    )
    assert response.status_code == 200


def test_facebook_uses_versioned_flow_without_pkce(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    _configure_facebook(monkeypatch)
    response = client.get(
        "/api/auth/oauth/facebook/authorize",
        params={"redirect_uri": "http://localhost:3000/ko/auth/callback"},
        follow_redirects=False,
    )

    assert response.status_code == 302
    provider_url = urlparse(response.headers["location"])
    provider_query = parse_qs(provider_url.query)
    assert provider_url.netloc == "www.facebook.com"
    assert provider_url.path == "/dialog/oauth"
    assert "code_challenge" not in provider_query
    assert "code_challenge_method" not in provider_query


def test_facebook_callback_accepts_profile_without_email(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    _configure_facebook(monkeypatch)
    monkeypatch.setattr(httpx, "AsyncClient", lambda **_kwargs: _FakeFacebookClient())
    start = client.get(
        "/api/auth/oauth/facebook/authorize",
        params={"redirect_uri": "http://localhost:3000/ko/auth/callback"},
        follow_redirects=False,
    )
    provider_query = parse_qs(urlparse(start.headers["location"]).query)

    callback = client.get(
        "/api/auth/oauth/facebook/callback",
        params={"code": "facebook-provider-code", "state": provider_query["state"][0]},
        follow_redirects=False,
    )
    callback_query = parse_qs(urlparse(callback.headers["location"]).query)
    exchange = client.post(
        "/api/auth/oauth/exchange", json={"code": callback_query["code"][0]}
    )
    me = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {exchange.json()['access_token']}"},
    )

    assert callback.status_code == 302
    assert exchange.status_code == 200
    assert me.status_code == 200
    assert me.json()["email"] == (
        "facebook_facebook-subject-no-email@oauth.placeholder"
    )


def test_oauth_denial_returns_to_client_and_consumes_state(
    client: TestClient, monkeypatch: pytest.MonkeyPatch
) -> None:
    _configure_facebook(monkeypatch)
    start = client.get(
        "/api/auth/oauth/facebook/authorize",
        params={
            "redirect_uri": "http://localhost:3000/ko/auth/callback",
            "return_to": "/settings",
        },
        follow_redirects=False,
    )
    state = parse_qs(urlparse(start.headers["location"]).query)["state"][0]

    denied = client.get(
        "/api/auth/oauth/facebook/callback",
        params={"error": "access_denied", "state": state},
        follow_redirects=False,
    )
    assert denied.status_code == 302
    denied_query = parse_qs(urlparse(denied.headers["location"]).query)
    assert denied_query == {
        "error": ["access_denied"],
        "return_to": ["/settings"],
    }

    replay = client.get(
        "/api/auth/oauth/facebook/callback",
        params={"error": "access_denied", "state": state},
        follow_redirects=False,
    )
    assert replay.status_code == 400


def test_authenticated_user_can_start_passkey_registration(
    client: TestClient,
) -> None:
    rate_limit_module._rate_limiter_registry.clear()
    register = client.post(
        "/api/auth/register",
        json={"email": "passkey@example.com", "password": "supersecret123"},
    )
    response = client.post(
        "/api/auth/passkeys/register/options",
        headers={"Authorization": f"Bearer {register.json()['access_token']}"},
    )
    assert response.status_code == 200
    assert response.json()["ceremony_id"]
    assert response.json()["public_key"]["challenge"]
    assert response.json()["public_key"]["rp"]["id"] == "localhost"
