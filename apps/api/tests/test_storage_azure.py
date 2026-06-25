"""Tests for the Azure Blob Storage adapter.

Skipped automatically when the optional ``storage-azure`` extra is not
installed (``uv sync --extra storage-azure``).
"""

import base64
from unittest.mock import AsyncMock, MagicMock
from urllib.parse import parse_qs, urlsplit

import pytest

pytest.importorskip("azure.storage.blob")

from azure.core.exceptions import ResourceNotFoundError

from src.lib.config import Settings
from src.lib.storage.azure import (
    AzureBlobStorageProvider,
    StorageConfigurationError,
    _parse_connection_string,
)

# A syntactically valid base64 account key so generate_blob_sas can HMAC-sign.
FAKE_ACCOUNT_KEY = base64.b64encode(b"0" * 32).decode()
ACCOUNT_URL = "https://acct.blob.core.windows.net"


def _blob_client_mock(url: str) -> MagicMock:
    blob_client = MagicMock()
    blob_client.url = url
    blob_client.upload_blob = AsyncMock()
    blob_client.delete_blob = AsyncMock()
    return blob_client


def _provider_with(blob_client: MagicMock) -> AzureBlobStorageProvider:
    service_client = MagicMock()
    service_client.get_blob_client.return_value = blob_client
    return AzureBlobStorageProvider(
        service_client, account_name="acct", account_key=FAKE_ACCOUNT_KEY
    )


def test_parse_connection_string() -> None:
    conn = (
        "DefaultEndpointsProtocol=https;AccountName=acct;"
        f"AccountKey={FAKE_ACCOUNT_KEY};EndpointSuffix=core.windows.net"
    )
    parsed = _parse_connection_string(conn)
    assert parsed["AccountName"] == "acct"
    assert parsed["AccountKey"] == FAKE_ACCOUNT_KEY


def test_from_settings_requires_credentials() -> None:
    config = Settings(
        AZURE_STORAGE_CONNECTION_STRING=None, AZURE_STORAGE_ACCOUNT_NAME=None
    )
    with pytest.raises(StorageConfigurationError):
        AzureBlobStorageProvider.from_settings(config)


def test_from_settings_shared_key() -> None:
    config = Settings(
        STORAGE_BACKEND="azure",
        AZURE_STORAGE_ACCOUNT_NAME="acct",
        AZURE_STORAGE_ACCOUNT_KEY=FAKE_ACCOUNT_KEY,
    )
    provider = AzureBlobStorageProvider.from_settings(config)
    assert provider._account_name == "acct"
    assert provider._account_key == FAKE_ACCOUNT_KEY


async def test_upload_returns_blob_url() -> None:
    blob_client = _blob_client_mock(f"{ACCOUNT_URL}/bucket/key.txt")
    provider = _provider_with(blob_client)

    url = await provider.upload(
        "bucket", "key.txt", b"hello", content_type="text/plain"
    )

    assert url == f"{ACCOUNT_URL}/bucket/key.txt"
    blob_client.upload_blob.assert_awaited_once()
    _, kwargs = blob_client.upload_blob.call_args
    assert kwargs["overwrite"] is True
    assert kwargs["content_settings"].content_type == "text/plain"


async def test_download_reads_all_bytes() -> None:
    blob_client = _blob_client_mock(f"{ACCOUNT_URL}/bucket/key.txt")
    stream = MagicMock()
    stream.readall = AsyncMock(return_value=b"hello")
    blob_client.download_blob = AsyncMock(return_value=stream)
    provider = _provider_with(blob_client)

    data = await provider.download("bucket", "key.txt")

    assert data == b"hello"


async def test_download_missing_raises_file_not_found() -> None:
    blob_client = _blob_client_mock(f"{ACCOUNT_URL}/bucket/missing.txt")
    blob_client.download_blob = AsyncMock(side_effect=ResourceNotFoundError("nope"))
    provider = _provider_with(blob_client)

    with pytest.raises(FileNotFoundError):
        await provider.download("bucket", "missing.txt")


async def test_delete_is_idempotent() -> None:
    blob_client = _blob_client_mock(f"{ACCOUNT_URL}/bucket/key.txt")
    blob_client.delete_blob = AsyncMock(side_effect=ResourceNotFoundError("nope"))
    provider = _provider_with(blob_client)

    # Must not raise when the blob is already gone.
    await provider.delete("bucket", "key.txt")
    blob_client.delete_blob.assert_awaited_once()


async def test_signed_url_contains_sas_token() -> None:
    blob_client = _blob_client_mock(f"{ACCOUNT_URL}/bucket/key.txt")
    provider = _provider_with(blob_client)

    url = await provider.get_signed_url("bucket", "key.txt", expires_in=600)

    split = urlsplit(url)
    assert split.path == "/bucket/key.txt"
    query = parse_qs(split.query)
    assert "sig" in query  # signature present
    assert query["sp"] == ["r"]  # read-only permission
