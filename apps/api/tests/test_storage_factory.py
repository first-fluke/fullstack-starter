"""Tests for the storage provider factory."""

import base64

import pytest

from src.lib.config import settings
from src.lib.storage.factory import aclose_storage_provider, get_storage_provider

FAKE_ACCOUNT_KEY = base64.b64encode(b"0" * 32).decode()


@pytest.fixture(autouse=True)
def _clear_cache() -> None:
    """Reset the singleton cache around every test."""
    get_storage_provider.cache_clear()
    yield
    get_storage_provider.cache_clear()


def test_unimplemented_backend_raises(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(settings, "STORAGE_BACKEND", "minio")
    with pytest.raises(NotImplementedError):
        get_storage_provider()


def test_azure_backend_returns_adapter(monkeypatch: pytest.MonkeyPatch) -> None:
    pytest.importorskip("azure.storage.blob")
    from src.lib.storage.azure import AzureBlobStorageProvider

    monkeypatch.setattr(settings, "STORAGE_BACKEND", "azure")
    monkeypatch.setattr(settings, "AZURE_STORAGE_CONNECTION_STRING", None)
    monkeypatch.setattr(settings, "AZURE_STORAGE_ACCOUNT_NAME", "acct")
    monkeypatch.setattr(settings, "AZURE_STORAGE_ACCOUNT_KEY", FAKE_ACCOUNT_KEY)

    provider = get_storage_provider()
    assert isinstance(provider, AzureBlobStorageProvider)
    # Cached singleton: same instance on subsequent calls.
    assert get_storage_provider() is provider


async def test_aclose_is_noop_when_uninitialized() -> None:
    # No provider created yet → must not construct one or raise.
    await aclose_storage_provider()
    assert get_storage_provider.cache_info().currsize == 0
