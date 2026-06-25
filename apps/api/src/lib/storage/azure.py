"""Azure Blob Storage adapter implementing the StorageProvider contract.

The StorageProvider interface is bucket/key oriented; in Azure terms the
``bucket`` argument maps to a *container* and ``key`` maps to a *blob name*.

Authentication resolves in this order (first match wins):

1. ``AZURE_STORAGE_CONNECTION_STRING``
2. ``AZURE_STORAGE_ACCOUNT_NAME`` + ``AZURE_STORAGE_ACCOUNT_KEY`` (shared key)
3. ``AZURE_STORAGE_ACCOUNT_NAME`` + ``DefaultAzureCredential``
   (managed identity / workload identity — recommended in production)

Signed URLs are issued as SAS tokens. Shared-key auth signs with the account
key directly; identity-based auth requests a short-lived *user delegation key*
from Azure AD and signs with that instead.

This adapter requires the optional ``storage-azure`` extra::

    uv sync --extra storage-azure
"""

from datetime import UTC, datetime, timedelta

from azure.core.exceptions import ResourceNotFoundError
from azure.storage.blob import (
    BlobSasPermissions,
    ContentSettings,
    generate_blob_sas,
)
from azure.storage.blob.aio import BlobServiceClient

from src.lib.config import Settings, settings
from src.lib.storage.base import StorageProvider


class StorageConfigurationError(RuntimeError):
    """Raised when Azure Blob Storage credentials are not configured."""


def _parse_connection_string(connection_string: str) -> dict[str, str]:
    """Parse a ``key=value;...`` Azure connection string into a dict."""
    parts: dict[str, str] = {}
    for segment in connection_string.split(";"):
        segment = segment.strip()
        if not segment:
            continue
        key, sep, value = segment.partition("=")
        if sep:
            parts[key.strip()] = value.strip()
    return parts


class AzureBlobStorageProvider(StorageProvider):
    """StorageProvider backed by Azure Blob Storage (async SDK)."""

    def __init__(
        self,
        client: BlobServiceClient,
        account_name: str,
        account_key: str | None = None,
    ) -> None:
        """Wrap an already-configured async ``BlobServiceClient``.

        Args:
            client: Async Azure ``BlobServiceClient``.
            account_name: Storage account name (used for SAS generation).
            account_key: Shared key. When ``None``, signed URLs are issued via
                a user delegation key (managed/workload identity).
        """
        self._client = client
        self._account_name = account_name
        self._account_key = account_key

    @classmethod
    def from_settings(
        cls, config: Settings | None = None
    ) -> "AzureBlobStorageProvider":
        """Build an adapter from application settings.

        Raises:
            StorageConfigurationError: When no usable credentials are found.
        """
        config = config or settings

        if config.AZURE_STORAGE_CONNECTION_STRING:
            parsed = _parse_connection_string(config.AZURE_STORAGE_CONNECTION_STRING)
            account_name = parsed.get("AccountName")
            if not account_name:
                msg = "AZURE_STORAGE_CONNECTION_STRING is missing AccountName"
                raise StorageConfigurationError(msg)
            client = BlobServiceClient.from_connection_string(
                config.AZURE_STORAGE_CONNECTION_STRING
            )
            return cls(client, account_name, account_key=parsed.get("AccountKey"))

        account_name = config.AZURE_STORAGE_ACCOUNT_NAME
        if not account_name:
            msg = (
                "Azure storage requires AZURE_STORAGE_CONNECTION_STRING or "
                "AZURE_STORAGE_ACCOUNT_NAME"
            )
            raise StorageConfigurationError(msg)

        account_url = (
            f"https://{account_name}.blob.{config.AZURE_STORAGE_ENDPOINT_SUFFIX}"
        )

        if config.AZURE_STORAGE_ACCOUNT_KEY:
            client = BlobServiceClient(
                account_url, credential=config.AZURE_STORAGE_ACCOUNT_KEY
            )
            return cls(
                client, account_name, account_key=config.AZURE_STORAGE_ACCOUNT_KEY
            )

        # Fall back to managed/workload identity. azure-identity is imported
        # lazily so connection-string / shared-key deployments don't need it.
        try:
            from azure.identity.aio import DefaultAzureCredential
        except ImportError as exc:  # pragma: no cover - optional dependency
            msg = (
                "Managed-identity Azure auth requires azure-identity; install "
                "the storage-azure extra or set AZURE_STORAGE_ACCOUNT_KEY"
            )
            raise StorageConfigurationError(msg) from exc

        client = BlobServiceClient(account_url, credential=DefaultAzureCredential())
        return cls(client, account_name, account_key=None)

    async def upload(
        self,
        bucket: str,
        key: str,
        data: bytes,
        content_type: str | None = None,
    ) -> str:
        blob_client = self._client.get_blob_client(container=bucket, blob=key)
        content_settings = (
            ContentSettings(content_type=content_type) if content_type else None
        )
        await blob_client.upload_blob(
            data, overwrite=True, content_settings=content_settings
        )
        return blob_client.url

    async def download(self, bucket: str, key: str) -> bytes:
        blob_client = self._client.get_blob_client(container=bucket, blob=key)
        try:
            stream = await blob_client.download_blob()
        except ResourceNotFoundError as exc:
            raise FileNotFoundError(f"{bucket}/{key}") from exc
        return await stream.readall()

    async def delete(self, bucket: str, key: str) -> None:
        blob_client = self._client.get_blob_client(container=bucket, blob=key)
        try:
            await blob_client.delete_blob()
        except ResourceNotFoundError:
            # Idempotent: deleting a missing blob is a no-op.
            return

    async def get_signed_url(
        self, bucket: str, key: str, expires_in: int = 3600
    ) -> str:
        start = datetime.now(UTC)
        expiry = start + timedelta(seconds=expires_in)
        permission = BlobSasPermissions(read=True)

        if self._account_key:
            sas_token = generate_blob_sas(
                account_name=self._account_name,
                container_name=bucket,
                blob_name=key,
                account_key=self._account_key,
                permission=permission,
                expiry=expiry,
                start=start,
            )
        else:
            user_delegation_key = await self._client.get_user_delegation_key(
                key_start_time=start, key_expiry_time=expiry
            )
            sas_token = generate_blob_sas(
                account_name=self._account_name,
                container_name=bucket,
                blob_name=key,
                user_delegation_key=user_delegation_key,
                permission=permission,
                expiry=expiry,
                start=start,
            )

        blob_client = self._client.get_blob_client(container=bucket, blob=key)
        return f"{blob_client.url}?{sas_token}"

    async def aclose(self) -> None:
        """Close the underlying client and its transport."""
        await self._client.close()

    async def __aenter__(self) -> "AzureBlobStorageProvider":
        return self

    async def __aexit__(self, *_exc: object) -> None:
        await self.aclose()
