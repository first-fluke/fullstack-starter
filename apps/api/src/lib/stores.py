"""Unified Litestar StoreRegistry configuration (RedisStore / MemoryStore)."""

from litestar.stores.base import Store
from litestar.stores.memory import MemoryStore
from litestar.stores.redis import RedisStore
from litestar.stores.registry import StoreRegistry

from src.lib.config import settings
from src.lib.logging import get_logger

logger = get_logger(__name__)


def create_default_store(namespace: str | None = None) -> Store:
    """Create a RedisStore when REDIS_URL is configured, otherwise MemoryStore."""
    if settings.REDIS_URL:
        logger.info("Initializing Litestar RedisStore", namespace=namespace)
        return RedisStore.with_client(
            url=settings.REDIS_URL,
            namespace=namespace,
        )
    return MemoryStore()


def create_store_registry() -> StoreRegistry:
    """Create the application-wide Litestar StoreRegistry."""
    return StoreRegistry(
        stores={
            "token_revocation": create_default_store("revoked"),
            "ephemeral_auth": create_default_store("auth"),
            "rate_limit": create_default_store("rate_limit"),
        },
        default_factory=create_default_store,
    )
