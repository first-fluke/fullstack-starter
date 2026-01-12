"""Rate limiting middleware with Redis or in-memory backend."""

import time
from collections import defaultdict
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import TYPE_CHECKING, cast

from fastapi import HTTPException, Request, status
from fastapi.responses import Response

from src.lib.config import settings
from src.lib.logging import get_logger

if TYPE_CHECKING:
    import redis.asyncio as redis_module

logger = get_logger(__name__)


@dataclass
class RateLimitConfig:
    """Rate limit configuration."""

    requests: int = 100  # Number of requests
    window: int = 60  # Time window in seconds
    key_func: Callable[[Request], str] | None = None  # Custom key function


def default_key_func(request: Request) -> str:
    """Default rate limit key: IP address + path."""
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        ip = forwarded.split(",")[0].strip()
    else:
        ip = request.client.host if request.client else "unknown"
    return f"{ip}:{request.url.path}"


@dataclass
class InMemoryRateLimiter:
    """Simple in-memory rate limiter using sliding window."""

    requests: int
    window: int
    _storage: dict[str, list[float]] = field(default_factory=lambda: defaultdict(list))

    def is_allowed(self, key: str) -> tuple[bool, int, int]:
        """
        Check if request is allowed.

        Returns:
            tuple: (allowed, remaining, reset_after)
        """
        now = time.time()
        window_start = now - self.window

        # Clean old entries
        self._storage[key] = [ts for ts in self._storage[key] if ts > window_start]

        current_count = len(self._storage[key])
        remaining = max(0, self.requests - current_count - 1)
        reset_after = (
            int(self.window - (now - self._storage[key][0]))
            if self._storage[key]
            else self.window
        )

        if current_count >= self.requests:
            return False, 0, reset_after

        self._storage[key].append(now)
        return True, remaining, reset_after


class RedisRateLimiter:
    """Redis-based rate limiter using sliding window."""

    def __init__(self, requests: int, window: int):
        self.requests = requests
        self.window = window
        self._redis: "redis_module.Redis | None" = None

    async def _get_redis(self) -> "redis_module.Redis":
        """Lazy Redis connection."""
        if self._redis is None:
            import redis.asyncio as redis

            self._redis = cast(
                redis_module.Redis,
                redis.from_url(settings.REDIS_URL),  # type: ignore[no-untyped-call]
            )
        return self._redis

    async def is_allowed(self, key: str) -> tuple[bool, int, int]:
        """
        Check if request is allowed using Redis sorted sets.

        Returns:
            tuple: (allowed, remaining, reset_after)
        """
        redis = await self._get_redis()
        now = time.time()
        window_start = now - self.window
        rate_key = f"rate_limit:{key}"

        pipe = redis.pipeline()
        pipe.zremrangebyscore(rate_key, 0, window_start)
        pipe.zcard(rate_key)
        pipe.zadd(rate_key, {str(now): now})
        pipe.expire(rate_key, self.window)
        results = await pipe.execute()

        current_count = results[1]
        remaining = max(0, self.requests - current_count - 1)
        reset_after = self.window

        if current_count >= self.requests:
            # Remove the just-added entry
            await redis.zrem(rate_key, str(now))
            return False, 0, reset_after

        return True, remaining, reset_after

    async def close(self) -> None:
        """Close Redis connection."""
        if self._redis:
            await self._redis.aclose()
            self._redis = None


# Global rate limiter instance
_rate_limiter: InMemoryRateLimiter | RedisRateLimiter | None = None


def get_rate_limiter(config: RateLimitConfig) -> InMemoryRateLimiter | RedisRateLimiter:
    """Get or create rate limiter instance."""
    global _rate_limiter

    if _rate_limiter is None:
        if settings.REDIS_URL:
            logger.info("Using Redis rate limiter")
            _rate_limiter = RedisRateLimiter(config.requests, config.window)
        else:
            logger.info("Using in-memory rate limiter")
            _rate_limiter = InMemoryRateLimiter(config.requests, config.window)

    return _rate_limiter


def rate_limit(
    requests: int = 100,
    window: int = 60,
    key_func: Callable[[Request], str] | None = None,
) -> Callable[[Callable[..., Awaitable[Response]]], Callable[..., Awaitable[Response]]]:
    """
    Rate limit decorator for FastAPI endpoints.

    Args:
        requests: Maximum requests allowed in the window
        window: Time window in seconds
        key_func: Custom function to generate rate limit key

    Usage:
        @app.get("/api/resource")
        @rate_limit(requests=10, window=60)
        async def get_resource():
            ...
    """
    config = RateLimitConfig(requests=requests, window=window, key_func=key_func)
    actual_key_func = key_func or default_key_func

    def decorator(
        func: Callable[..., Awaitable[Response]],
    ) -> Callable[..., Awaitable[Response]]:
        async def wrapper(*args: object, **kwargs: object) -> Response:
            # Find request in args/kwargs
            request: Request | None = None
            for arg in args:
                if isinstance(arg, Request):
                    request = arg
                    break
            if request is None:
                request = cast(Request | None, kwargs.get("request"))

            if request is None:
                return await func(*args, **kwargs)

            limiter = get_rate_limiter(config)
            key = actual_key_func(request)

            if isinstance(limiter, RedisRateLimiter):
                allowed, _remaining, reset_after = await limiter.is_allowed(key)
            else:
                allowed, _remaining, reset_after = limiter.is_allowed(key)

            if not allowed:
                logger.warning("Rate limit exceeded", key=key)
                raise HTTPException(
                    status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                    detail="Rate limit exceeded",
                    headers={
                        "X-RateLimit-Limit": str(config.requests),
                        "X-RateLimit-Remaining": "0",
                        "X-RateLimit-Reset": str(reset_after),
                        "Retry-After": str(reset_after),
                    },
                )

            response = await func(*args, **kwargs)
            return response

        wrapper.__name__ = func.__name__
        wrapper.__doc__ = func.__doc__
        return wrapper

    return decorator


async def rate_limit_middleware(
    request: Request,
    call_next: Callable[[Request], Awaitable[Response]],
    config: RateLimitConfig | None = None,
) -> Response:
    """
    Rate limit middleware for global application.

    Usage in main.py:
        @app.middleware("http")
        async def rate_limit_mw(request: Request, call_next):
            return await rate_limit_middleware(request, call_next)
    """
    if config is None:
        config = RateLimitConfig()

    # Skip rate limiting for health endpoints
    if request.url.path.startswith("/health"):
        return await call_next(request)

    key_func = config.key_func or default_key_func
    limiter = get_rate_limiter(config)
    key = key_func(request)

    if isinstance(limiter, RedisRateLimiter):
        allowed, remaining, reset_after = await limiter.is_allowed(key)
    else:
        allowed, remaining, reset_after = limiter.is_allowed(key)

    if not allowed:
        logger.warning("Rate limit exceeded", key=key, path=request.url.path)
        from fastapi.responses import JSONResponse

        return JSONResponse(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            content={"detail": "Rate limit exceeded"},
            headers={
                "X-RateLimit-Limit": str(config.requests),
                "X-RateLimit-Remaining": "0",
                "X-RateLimit-Reset": str(reset_after),
                "Retry-After": str(reset_after),
            },
        )

    response = await call_next(request)
    response.headers["X-RateLimit-Limit"] = str(config.requests)
    response.headers["X-RateLimit-Remaining"] = str(remaining)
    response.headers["X-RateLimit-Reset"] = str(reset_after)
    return response
