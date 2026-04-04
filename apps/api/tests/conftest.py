import asyncio
import os
from collections.abc import Iterator
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

TEST_DB_PATH = Path(__file__).parent / "test.db"
os.environ["PROJECT_ENV"] = "staging"
os.environ["DATABASE_URL"] = f"sqlite+aiosqlite:///{TEST_DB_PATH}"
os.environ["DATABASE_URL_SYNC"] = f"sqlite:///{TEST_DB_PATH}"

from src.lib.database import Base, engine  # noqa: E402
from src.main import app  # noqa: E402


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
