"""Tests for OIDC token verification — C-2 findings."""

from unittest.mock import patch

import pytest
from httpx import ASGITransport, AsyncClient
from pydantic import ValidationError

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
async def client() -> AsyncClient:
    from src.main import app

    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac


ANALYSIS_BODY = {"task_type": "analysis", "text": "hello world"}


@pytest.mark.asyncio
async def test_oidc_dependency_returns_500_when_verify_on_but_audience_missing(
    client: AsyncClient,
) -> None:
    """If WORKER_VERIFY_OIDC is True at runtime but WORKER_OIDC_AUDIENCE is empty,
    the dependency must return 500 rather than silently skipping audience check."""
    with patch("src.lib.oidc.settings") as mock_settings:
        mock_settings.WORKER_VERIFY_OIDC = True
        mock_settings.WORKER_OIDC_AUDIENCE = None  # misconfigured at runtime
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
    with patch("src.lib.oidc.settings") as mock_settings:
        mock_settings.WORKER_VERIFY_OIDC = True
        mock_settings.WORKER_OIDC_AUDIENCE = "https://example.com/"
        response = await client.post("/tasks/process", json=ANALYSIS_BODY)
    assert response.status_code == 401
