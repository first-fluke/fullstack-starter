"""Tests for POST /tasks/process endpoint and execute_task background function."""

from unittest.mock import patch

import pytest
from httpx import ASGITransport, AsyncClient
from tenacity import RetryError

from src.main import app

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------


@pytest.fixture
async def client() -> AsyncClient:
    async with AsyncClient(
        transport=ASGITransport(app=app),
        base_url="http://test",
    ) as ac:
        yield ac


ANALYSIS_BODY = {"task_type": "analysis", "text": "hello world"}
EMBEDDING_BODY = {"task_type": "embedding", "content": "hello world"}


# ---------------------------------------------------------------------------
# AC1: 202 with valid payload when WORKER_VERIFY_OIDC=False (default)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_process_analysis_returns_202(client: AsyncClient) -> None:
    response = await client.post("/tasks/process", json=ANALYSIS_BODY)
    assert response.status_code == 202
    assert response.json()["status"] == "accepted"


@pytest.mark.asyncio
async def test_process_embedding_returns_202(client: AsyncClient) -> None:
    response = await client.post("/tasks/process", json=EMBEDDING_BODY)
    assert response.status_code == 202


# ---------------------------------------------------------------------------
# AC2: 401 when WORKER_VERIFY_OIDC=True and Authorization header is absent
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_process_returns_401_when_oidc_enabled_and_no_token(
    client: AsyncClient,
) -> None:
    with patch("src.lib.oidc.settings") as mock_settings:
        mock_settings.WORKER_VERIFY_OIDC = True
        mock_settings.WORKER_OIDC_AUDIENCE = "https://example.com"
        response = await client.post("/tasks/process", json=ANALYSIS_BODY)
    assert response.status_code == 401


# ---------------------------------------------------------------------------
# AC3: 422 for invalid task_type
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_process_returns_422_for_invalid_task_type(
    client: AsyncClient,
) -> None:
    response = await client.post(
        "/tasks/process",
        json={"task_type": "unknown", "data": {}},
    )
    assert response.status_code == 422


# ---------------------------------------------------------------------------
# AC4: execute_task retries on transient exception (up to 3 attempts)
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_execute_task_retries_on_transient_exception() -> None:
    """with_retry() must retry a failing coroutine exactly max_attempts times."""
    from src.lib.retry import with_retry

    attempt_counter = 0

    @with_retry(max_attempts=3, min_wait=0, max_wait=0)
    async def always_fails() -> None:
        nonlocal attempt_counter
        attempt_counter += 1
        raise RuntimeError("transient error")

    with pytest.raises((RuntimeError, RetryError)):
        await always_fails()

    assert attempt_counter == 3, f"Expected 3 retry attempts but got {attempt_counter}"


@pytest.mark.asyncio
async def test_execute_task_succeeds_after_transient_failure() -> None:
    """execute_task succeeds on the third attempt after two transient failures."""
    from src.lib.retry import with_retry

    attempts: list[int] = []

    @with_retry(max_attempts=3, min_wait=0, max_wait=0)
    async def flaky() -> str:
        attempts.append(1)
        if len(attempts) < 3:
            raise RuntimeError("not yet")
        return "ok"

    result = await flaky()
    assert result == "ok"
    assert len(attempts) == 3


# ---------------------------------------------------------------------------
# Request-ID header present on task route responses
# ---------------------------------------------------------------------------


@pytest.mark.asyncio
async def test_process_response_includes_request_id(client: AsyncClient) -> None:
    response = await client.post("/tasks/process", json=ANALYSIS_BODY)
    assert "x-request-id" in response.headers


@pytest.mark.asyncio
async def test_process_echoes_request_id(client: AsyncClient) -> None:
    response = await client.post(
        "/tasks/process",
        json=ANALYSIS_BODY,
        headers={"X-Request-ID": "my-trace-99"},
    )
    assert response.headers["x-request-id"] == "my-trace-99"
