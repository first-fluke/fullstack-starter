"""One-time, TTL-bound authentication ceremony storage."""

import asyncio
import json
import time
from typing import Any

from src.lib.config import settings


class EphemeralAuthStore:
    """Redis-backed store with a deterministic local development fallback."""

    def __init__(self) -> None:
        self._memory: dict[str, tuple[float, dict[str, Any]]] = {}
        self._lock = asyncio.Lock()
        self._redis: Any = None

    async def put(
        self, namespace: str, key: str, value: dict[str, Any], ttl: int
    ) -> None:
        namespaced_key = f"auth:{namespace}:{key}"
        if settings.REDIS_URL:
            redis = await self._get_redis()
            await redis.setex(namespaced_key, ttl, json.dumps(value))
            return
        async with self._lock:
            self._memory[namespaced_key] = (time.time() + ttl, value)

    async def take(self, namespace: str, key: str) -> dict[str, Any] | None:
        namespaced_key = f"auth:{namespace}:{key}"
        if settings.REDIS_URL:
            redis = await self._get_redis()
            raw = await redis.getdel(namespaced_key)
            return json.loads(raw) if raw else None
        async with self._lock:
            entry = self._memory.pop(namespaced_key, None)
            if entry is None or entry[0] < time.time():
                return None
            return entry[1]

    async def _get_redis(self) -> Any:
        if self._redis is None:
            import redis.asyncio as redis

            self._redis = redis.from_url(settings.REDIS_URL or "")
        return self._redis

    def clear(self) -> None:
        self._memory.clear()


ephemeral_auth_store = EphemeralAuthStore()
