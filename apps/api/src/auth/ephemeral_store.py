"""One-time, TTL-bound authentication ceremony storage backed by Litestar Store."""

import asyncio
from typing import Any

import msgspec
from litestar.stores.memory import MemoryStore

from src.lib.config import settings


class EphemeralAuthStore:
    """Redis-backed store with a Litestar MemoryStore local development fallback."""

    def __init__(self) -> None:
        self._memory_store = MemoryStore()
        self._lock = asyncio.Lock()
        self._redis: Any = None

    async def put(
        self, namespace: str, key: str, value: dict[str, Any], ttl: int
    ) -> None:
        namespaced_key = f"auth:{namespace}:{key}"
        encoded = msgspec.json.encode(value)
        if settings.REDIS_URL:
            redis = await self._get_redis()
            await redis.setex(namespaced_key, ttl, encoded)
            return
        async with self._lock:
            await self._memory_store.set(namespaced_key, encoded, expires_in=ttl)

    async def take(self, namespace: str, key: str) -> dict[str, Any] | None:
        namespaced_key = f"auth:{namespace}:{key}"
        if settings.REDIS_URL:
            redis = await self._get_redis()
            raw = await redis.getdel(namespaced_key)
            return msgspec.json.decode(raw, type=dict[str, Any]) if raw else None
        async with self._lock:
            raw = await self._memory_store.get(namespaced_key)
            if raw is None:
                return None
            await self._memory_store.delete(namespaced_key)
            return msgspec.json.decode(raw, type=dict[str, Any])

    async def _get_redis(self) -> Any:
        if self._redis is None:
            import redis.asyncio as redis

            self._redis = redis.from_url(settings.REDIS_URL or "")
        return self._redis

    def clear(self) -> None:
        self._memory_store._store.clear()


ephemeral_auth_store = EphemeralAuthStore()
