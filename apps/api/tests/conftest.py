import asyncio
import os
import tempfile
from collections.abc import Iterator
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

TEST_DB_PATH = (
    Path(tempfile.gettempdir()) / f"fullstack-starter-api-tests-{os.getpid()}.db"
)
os.environ["PROJECT_ENV"] = "staging"
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{TEST_DB_PATH}"
os.environ["DATABASE_URL_SYNC"] = f"sqlite:///{TEST_DB_PATH}"

from src.lib.database import Base, engine  # noqa: E402
from src.main import app  # noqa: E402

if TEST_DB_PATH.exists():
    TEST_DB_PATH.unlink()


@pytest.fixture(autouse=True)
def reset_database() -> Iterator[None]:
    """Reset the SQLite test database for each test."""

    async def _reset() -> None:
        async with engine.begin() as connection:
            await connection.run_sync(Base.metadata.drop_all)
            await connection.run_sync(Base.metadata.create_all)

    asyncio.run(_reset())
    yield


@pytest.fixture
def client() -> Iterator[TestClient]:
    """Test client fixture."""
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture(scope="session", autouse=True)
def cleanup_test_database() -> Iterator[None]:
    """Remove the process-local SQLite file after the test session."""
    yield
    asyncio.run(engine.dispose())
    if TEST_DB_PATH.exists():
        TEST_DB_PATH.unlink()
