"""Tests for OIDC token verification — C-2 findings."""

from collections.abc import AsyncIterator
from unittest.mock import ANY, AsyncMock, patch

import pytest
from httpx import ASGITransport, AsyncClient
from pydantic import ValidationError

from src.lib.config import Settings

# ---------------------------------------------------------------------------
# C-2a: Settings validator raises when WORKER_VERIFY_OIDC=True and audience empty
# ---------------------------------------------------------------------------


def test_settings_raises_when_verify_oidc_true_and_no_audience() -> None:
    """Settings must reject WORKER_VERIFY_OIDC=True without WORKER_OIDC_AUDIENCE."""
    from src.lib.config import Settings

    with pytest.raises(ValidationError, match="WORKER_OIDC_AUDIENCE must be set"):
        Settings(WORKER_VERIFY_OIDC=True, WORKER_OIDC_AUDIENCE=None)


def test_settings_ok_when_verify_oidc_true_with_audience() -> None:
    """Settings must accept WORKER_VERIFY_OIDC=True when audience is provided."""
    from src.lib.config import Settings

    s = Settings(WORKER_VERIFY_OIDC=True, WORKER_OIDC_AUDIENCE="https://example.com/")
    assert s.WORKER_VERIFY_OIDC is True
    assert s.WORKER_OIDC_AUDIENCE == "https://example.com/"


def test_settings_ok_when_verify_oidc_false_and_no_audience() -> None:
    """Settings must accept WORKER_VERIFY_OIDC=False regardless of audience."""
    from src.lib.config import Settings

    s = Settings(WORKER_VERIFY_OIDC=False, WORKER_OIDC_AUDIENCE=None)
    assert s.WORKER_VERIFY_OIDC is False


# ---------------------------------------------------------------------------
# C-2b: Dependency returns 500 when verify is on but audience is missing at
#        request time (runtime override path, e.g. test patching).
# ---------------------------------------------------------------------------


@pytest.fixture
def worker_settings() -> Settings:
    return Settings(
        WORKER_VERIFY_OIDC=True, WORKER_OIDC_AUDIENCE="https://example.com/"
    )


@pytest.fixture
async def client(worker_settings: Settings) -> AsyncIterator[AsyncClient]:
    from src.main import create_app

    async with AsyncClient(
        transport=ASGITransport(app=create_app(worker_settings)),
        base_url="http://test",
    ) as ac:
        yield ac


ANALYSIS_BODY = {"task_type": "analysis", "text": "hello world"}


@pytest.mark.asyncio
async def test_oidc_dependency_returns_500_when_verify_on_but_audience_missing(
    client: AsyncClient,
    worker_settings: Settings,
) -> None:
    """If WORKER_VERIFY_OIDC is True at runtime but WORKER_OIDC_AUDIENCE is empty,
    the dependency must return 500 rather than silently skipping audience check."""
    worker_settings.WORKER_OIDC_AUDIENCE = None  # misconfigured at runtime
    response = await client.post(
        "/tasks/process",
        json=ANALYSIS_BODY,
        headers={"Authorization": "Bearer fake-token"},
    )
    assert response.status_code == 500
    assert "WORKER_OIDC_AUDIENCE" in response.json()["detail"]


@pytest.mark.asyncio
async def test_oidc_dependency_returns_401_when_verify_on_and_no_token(
    client: AsyncClient,
) -> None:
    """When WORKER_VERIFY_OIDC=True and audience is set, missing token → 401."""
    response = await client.post("/tasks/process", json=ANALYSIS_BODY)
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_oidc_settings_are_isolated_between_apps() -> None:
    from src.lib.config import Settings
    from src.main import create_app

    unprotected_app = create_app(Settings(WORKER_VERIFY_OIDC=False))
    protected_app = create_app(
        Settings(
            WORKER_VERIFY_OIDC=True,
            WORKER_OIDC_AUDIENCE="https://protected-worker.example",
        )
    )
    async with (
        AsyncClient(
            transport=ASGITransport(app=unprotected_app), base_url="http://test"
        ) as unprotected,
        AsyncClient(
            transport=ASGITransport(app=protected_app), base_url="http://test"
        ) as protected,
    ):
        accepted = await unprotected.post("/tasks/process", json=ANALYSIS_BODY)
        rejected = await protected.post("/tasks/process", json=ANALYSIS_BODY)
        accepted_again = await unprotected.post("/tasks/process", json=ANALYSIS_BODY)
    assert accepted.status_code == 202
    assert rejected.status_code == 401
    assert accepted_again.status_code == 202


@pytest.mark.asyncio
async def test_valid_oidc_token_is_verified_once_before_background_work(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    from src.lib.config import get_settings
    from src.main import create_app

    config = get_settings()
    audience = "https://protected-worker.example"
    monkeypatch.setattr(config, "WORKER_VERIFY_OIDC", True)
    monkeypatch.setattr(config, "WORKER_OIDC_AUDIENCE", audience)
    app = create_app(config)
    with (
        patch("src.lib.oidc.verify_oauth2_token") as verify,
        patch("src.routers.tasks.execute_task", new_callable=AsyncMock) as execute,
    ):
        async with AsyncClient(
            transport=ASGITransport(app=app), base_url="http://test"
        ) as client:
            response = await client.post(
                "/tasks/process",
                json=ANALYSIS_BODY,
                headers={"Authorization": "Bearer verified-token"},
            )
            rejected = await client.post("/tasks/process", json=ANALYSIS_BODY)
        assert response.status_code == 202
        assert rejected.status_code == 401
        verify.assert_called_once_with("verified-token", ANY, audience=audience)
        execute.assert_awaited_once()
