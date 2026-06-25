"""Storage provider factory.

Resolves the concrete ``StorageProvider`` from ``settings.STORAGE_BACKEND``.
The provider is cached as a singleton so the underlying SDK client (and its
connection pool) is shared across requests. Backend-specific adapters are
imported lazily so optional extras (e.g. ``storage-azure``) are only required
when that backend is actually selected.
"""

from functools import lru_cache

from src.lib.config import settings
from src.lib.storage.base import StorageProvider


@lru_cache
def get_storage_provider() -> StorageProvider:
    """Return the configured storage provider (cached singleton).

    Raises:
        NotImplementedError: When the configured backend has no adapter yet.
    """
    backend = settings.STORAGE_BACKEND

    if backend == "azure":
        from src.lib.storage.azure import AzureBlobStorageProvider

        return AzureBlobStorageProvider.from_settings(settings)

    raise NotImplementedError(f"Storage backend {backend!r} is not implemented yet")


async def aclose_storage_provider() -> None:
    """Close the cached provider (if any) and reset the cache.

    Safe to call when no provider has been created; it is then a no-op.
    Intended for the application shutdown hook.
    """
    if get_storage_provider.cache_info().currsize == 0:
        return
    provider = get_storage_provider()
    await provider.aclose()
    get_storage_provider.cache_clear()
