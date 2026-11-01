"""Token revocation store backed by Litestar Stores (MemoryStore / Redis)."""

from typing import TYPE_CHECKING

from litestar.stores.memory import MemoryStore

from src.lib.config import settings
from src.lib.logging import get_logger

if TYPE_CHECKING:
    import redis.asyncio as redis_module

logger = get_logger(__name__)

_REVOKED_KEY_PREFIX = "revoked:"


class InMemoryTokenStore:
    """In-memory token revocation store backed by Litestar MemoryStore."""

    def __init__(self) -> None:
        self._memory_store = MemoryStore()
        self._store: dict[str, float] = {}

    async def revoke(self, jti: str, ttl: int) -> None:
        """Mark a token as revoked for the given TTL (seconds)."""
        import time

        expires_at = time.time() + ttl
        self._store[jti] = expires_at
        if ttl > 0:
            await self._memory_store.set(jti, b"1", expires_in=ttl)

    async def is_revoked(self, jti: str) -> bool:
        """Return True if the token has been revoked and has not expired."""
        import time

        expires_at = self._store.get(jti)
        if expires_at is None:
            return False
        if time.time() > expires_at:
            del self._store[jti]
            await self._memory_store.delete(jti)
            return False
        return True

    async def revoke_if_not_revoked(self, jti: str, ttl: int) -> bool:
        """Atomically claim and revoke a token only if it has not been revoked yet."""
        import time

        # --- begin critical section (no await between check and set) ---
        expires_at = self._store.get(jti)
        if expires_at is not None and time.time() <= expires_at:
            return False
        new_expires_at = time.time() + ttl
        self._store[jti] = new_expires_at
        # --- end critical section ---
        if ttl > 0:
            await self._memory_store.set(jti, b"1", expires_in=ttl)
        return True

    def clear(self) -> None:
        """Remove all entries (useful in tests)."""
        self._store.clear()


class RedisTokenStore:
    """Redis-backed token revocation store."""

    def __init__(self) -> None:
        self._redis: redis_module.Redis | None = None

    async def _get_redis(self) -> redis_module.Redis:
        """Lazy Redis connection."""
        if self._redis is None:
            import redis.asyncio as redis

            self._redis = redis.from_url(settings.REDIS_URL or "")
        return self._redis

    async def revoke(self, jti: str, ttl: int) -> None:
        """Mark a token as revoked in Redis with a TTL."""
        if ttl <= 0:
            return
        redis = await self._get_redis()
        key = f"{_REVOKED_KEY_PREFIX}{jti}"
        await redis.setex(key, ttl, "1")

    async def is_revoked(self, jti: str) -> bool:
        """Return True if the revocation key exists in Redis."""
        redis = await self._get_redis()
        key = f"{_REVOKED_KEY_PREFIX}{jti}"
        result = await redis.exists(key)
        return bool(result)

    async def revoke_if_not_revoked(self, jti: str, ttl: int) -> bool:
        """Atomically claim and revoke a token using Redis SET NX EX."""
        if ttl <= 0:
            return False
        redis = await self._get_redis()
        key = f"{_REVOKED_KEY_PREFIX}{jti}"
        result = await redis.set(key, "1", nx=True, ex=ttl)
        return result is not None

    async def close(self) -> None:
        """Close the Redis connection."""
        if self._redis:
            await self._redis.aclose()
            self._redis = None


# Module-level singleton — initialised once, reused across requests.
_token_store: InMemoryTokenStore | RedisTokenStore | None = None


def get_token_store() -> InMemoryTokenStore | RedisTokenStore:
    """Return the process-wide token store, creating it on first call."""
    global _token_store

    if _token_store is None:
        if settings.REDIS_URL:
            logger.info("Using Redis token store")
            _token_store = RedisTokenStore()
        else:
            logger.warning(
                "Using in-memory token store — revocations are not shared across "
                "replicas. Set REDIS_URL in production."
            )
            _token_store = InMemoryTokenStore()

    return _token_store


async def revoke(jti: str, ttl: int) -> None:
    """Revoke a token by its JTI."""
    store = get_token_store()
    await store.revoke(jti, ttl)


async def is_revoked(jti: str) -> bool:
    """Check whether a token has been revoked."""
    store = get_token_store()
    return await store.is_revoked(jti)


async def revoke_if_not_revoked(jti: str, ttl: int) -> bool:
    """Atomically claim and revoke a token only if it has not already been revoked."""
    store = get_token_store()
    return await store.revoke_if_not_revoked(jti, ttl)
