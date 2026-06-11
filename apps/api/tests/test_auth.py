"""Auth endpoint tests covering rate limiting, token revocation, refresh rotation,
and logout."""

import asyncio

import httpx
from fastapi.testclient import TestClient

import src.lib.rate_limit as rate_limit_module
import src.lib.token_store as token_store_module


def _reset_rate_limiter() -> None:
    """Reset the process-global rate-limiter registry.

    Call at the start of any test that exercises rate limiting so that counts
    from previous tests do not bleed in.
    """
    rate_limit_module._rate_limiter_registry.clear()


def _reset_token_store() -> None:
    """Reset the process-global token-store singleton.

    Call at the start of any test that exercises token revocation so that
    revocations from previous tests do not bleed in.
    """
    token_store_module._token_store = None


def _reset_all() -> None:
    """Reset both singletons."""
    _reset_rate_limiter()
    _reset_token_store()


# ---------------------------------------------------------------------------
# Existing tests (preserved)
# ---------------------------------------------------------------------------


def test_register_returns_backend_tokens(client: TestClient) -> None:
    _reset_all()
    response = client.post(
        "/api/auth/register",
        json={
            "email": "grace@example.com",
            "password": "supersecret123",
            "name": "Grace",
        },
    )

    assert response.status_code == 201
    data = response.json()
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["token_type"] == "bearer"  # noqa: S105


def test_email_login_and_me_flow(client: TestClient) -> None:
    _reset_all()
    register_response = client.post(
        "/api/auth/register",
        json={
            "email": "grace@example.com",
            "password": "supersecret123",
            "name": "Grace",
        },
    )
    access_token = register_response.json()["access_token"]

    me_response = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_response.status_code == 200
    assert me_response.json()["email"] == "grace@example.com"

    login_response = client.post(
        "/api/auth/login",
        json={
            "email": "grace@example.com",
            "password": "supersecret123",
        },
    )

    assert login_response.status_code == 200
    assert login_response.json()["access_token"]
    assert login_response.json()["refresh_token"]


def test_duplicate_email_registration_is_rejected(client: TestClient) -> None:
    _reset_all()
    payload = {
        "email": "grace@example.com",
        "password": "supersecret123",
        "name": "Grace",
    }

    first_response = client.post("/api/auth/register", json=payload)
    second_response = client.post("/api/auth/register", json=payload)

    assert first_response.status_code == 201
    assert second_response.status_code == 409
    assert second_response.json()["detail"] == "Email already registered"


# ---------------------------------------------------------------------------
# Rate-limit tests
# ---------------------------------------------------------------------------


def test_rate_limit_rejects_sixth_attempt(client: TestClient) -> None:
    """The 6th request to the same endpoint within the window receives 429."""
    _reset_all()

    # Use /register exclusively so all 6 calls share the same IP:path key.
    for i in range(5):
        resp = client.post(
            "/api/auth/register",
            json={
                "email": f"rl-sixth-{i}@example.com",
                "password": "supersecret123",
            },
        )
        # All five must succeed (201 for new email, 409 for duplicate — both are
        # non-429 responses that the limiter counts).
        assert resp.status_code != 429, f"request {i + 1} unexpectedly rate-limited"

    sixth = client.post(
        "/api/auth/register",
        json={"email": "rl-sixth-5@example.com", "password": "supersecret123"},
    )
    assert sixth.status_code == 429


def test_rate_limit_rejects_sixth_login_attempt(client: TestClient) -> None:
    """6th POST /login from the same IP is rejected with 429."""
    _reset_all()

    # Pre-create a user so the first login succeeds; subsequent ones will also
    # succeed or fail with 401, but the rate-limit counter still increments.
    client.post(
        "/api/auth/register",
        json={"email": "rl-login@example.com", "password": "supersecret123"},
    )
    # Reset after register so the login counter starts clean.
    _reset_rate_limiter()

    login_payload = {"email": "rl-login@example.com", "password": "supersecret123"}
    for _ in range(5):
        resp = client.post("/api/auth/login", json=login_payload)
        assert resp.status_code != 429

    sixth = client.post("/api/auth/login", json=login_payload)
    assert sixth.status_code == 429


# ---------------------------------------------------------------------------
# Token revocation / refresh-rotation tests
# ---------------------------------------------------------------------------


def _register_and_get_tokens(client: TestClient, email: str) -> dict[str, str]:
    """Register a new user and return their tokens.

    Resets both singletons so each test starts with a clean slate.
    """
    _reset_all()
    resp = client.post(
        "/api/auth/register",
        json={"email": email, "password": "supersecret123"},
    )
    assert resp.status_code == 201
    return resp.json()


def test_refresh_returns_new_refresh_token(client: TestClient) -> None:
    """POST /refresh must return a refresh_token different from the one submitted."""
    tokens = _register_and_get_tokens(client, "rotation@example.com")
    original_refresh = tokens["refresh_token"]

    # Reset only the rate-limiter — the token store must keep its state so
    # revocations from this call are remembered.
    _reset_rate_limiter()

    resp = client.post(
        "/api/auth/refresh",
        json={"refresh_token": original_refresh},
    )
    assert resp.status_code == 200
    new_tokens = resp.json()
    assert new_tokens["refresh_token"] != original_refresh
    assert new_tokens["access_token"]


def test_used_refresh_token_is_rejected(client: TestClient) -> None:
    """A refresh token that has already been used must be rejected with 401."""
    tokens = _register_and_get_tokens(client, "revoke@example.com")
    original_refresh = tokens["refresh_token"]

    # First use — succeeds and revokes the token in the store.
    _reset_rate_limiter()
    first = client.post(
        "/api/auth/refresh",
        json={"refresh_token": original_refresh},
    )
    assert first.status_code == 200

    # Second use of the *same* token — the store still holds the revocation, so
    # only the rate-limiter is reset here.
    _reset_rate_limiter()
    second = client.post(
        "/api/auth/refresh",
        json={"refresh_token": original_refresh},
    )
    assert second.status_code == 401


def test_logout_then_refresh_fails(client: TestClient) -> None:
    """After /logout, using the old refresh token returns 401."""
    tokens = _register_and_get_tokens(client, "logout@example.com")
    access_token = tokens["access_token"]
    refresh_token = tokens["refresh_token"]

    # Logout — revokes both tokens in the store.
    _reset_rate_limiter()
    logout_resp = client.post(
        "/api/auth/logout",
        json={"refresh_token": refresh_token},
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert logout_resp.status_code == 204

    # Attempt to use the revoked refresh token — only the rate-limiter is reset.
    _reset_rate_limiter()
    refresh_resp = client.post(
        "/api/auth/refresh",
        json={"refresh_token": refresh_token},
    )
    assert refresh_resp.status_code == 401


def test_logout_requires_authentication(client: TestClient) -> None:
    """POST /logout without a Bearer token returns 401."""
    _reset_all()
    resp = client.post(
        "/api/auth/logout",
        json={"refresh_token": "not-a-real-token"},
    )
    assert resp.status_code == 401


# ---------------------------------------------------------------------------
# C-1: Revoked access token rejected on /me after logout
# ---------------------------------------------------------------------------


def test_revoked_access_token_rejected_on_me(client: TestClient) -> None:
    """Access token revoked via /logout must be rejected by /me with 401 (C-1)."""
    tokens = _register_and_get_tokens(client, "c1-access-revoke@example.com")
    access_token = tokens["access_token"]
    refresh_token = tokens["refresh_token"]

    # Verify /me works before logout.
    _reset_rate_limiter()
    me_before = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_before.status_code == 200

    # Logout — revokes the access token in the store.
    logout_resp = client.post(
        "/api/auth/logout",
        json={"refresh_token": refresh_token},
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert logout_resp.status_code == 204

    # /me with the revoked access token must now return 401.
    me_after = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_after.status_code == 401
    assert me_after.json()["detail"] == "Token has been revoked"


# ---------------------------------------------------------------------------
# L-2: Concurrent refresh replay — exactly one succeeds
# ---------------------------------------------------------------------------


def test_concurrent_refresh_replay_exactly_one_succeeds(client: TestClient) -> None:
    """Two concurrent refresh requests with the same token: exactly one 200, one 401.

    Uses asyncio.gather to simulate true concurrency against the in-memory store.
    The atomic revoke_if_not_revoked claim ensures the second caller is rejected.
    """
    tokens = _register_and_get_tokens(client, "l2-concurrent@example.com")
    original_refresh = tokens["refresh_token"]
    _reset_rate_limiter()

    from src.main import app

    async def _do_refresh() -> int:
        async with httpx.AsyncClient(
            transport=httpx.ASGITransport(app=app), base_url="http://test"
        ) as ac:
            resp = await ac.post(
                "/api/auth/refresh",
                json={"refresh_token": original_refresh},
            )
            return resp.status_code

    async def _run() -> list[int]:
        return list(await asyncio.gather(_do_refresh(), _do_refresh()))

    results = asyncio.run(_run())
    successes = results.count(200)
    failures = results.count(401)

    assert successes == 1, f"Expected exactly 1 success, got {successes}: {results}"
    assert failures == 1, f"Expected exactly 1 failure, got {failures}: {results}"
