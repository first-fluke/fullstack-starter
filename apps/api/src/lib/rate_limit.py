"""Rate limiting middleware with Redis or in-memory backend."""

import ipaddress
import time
from collections import defaultdict
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from functools import wraps
from typing import TYPE_CHECKING, TypeVar, cast

from fastapi import HTTPException, Request, status
from fastapi.responses import Response

from src.lib.config import settings
from src.lib.logging import get_logger

if TYPE_CHECKING:
    import redis.asyncio as redis_module

logger = get_logger(__name__)

# Return type of the decorated endpoint (e.g. a Pydantic response model),
# preserved so the rate limiter does not narrow handler return types to Response.
R = TypeVar("R")


@dataclass
class RateLimitConfig:
    """Rate limit configuration."""

    requests: int = 100  # Number of requests
    window: int = 60  # Time window in seconds
    key_func: Callable[[Request], str] | None = None  # Custom key function


def _is_trusted_proxy(host: str) -> bool:
    """Return True if host falls within one of the configured trusted proxy CIDRs."""
    try:
        client_addr = ipaddress.ip_address(host)
    except ValueError:
        return False
    for cidr in settings.TRUSTED_PROXY_IPS:
        try:
            if client_addr in ipaddress.ip_network(cidr, strict=False):
                return True
        except ValueError:
            continue
    return False


def default_key_func(request: Request) -> str:
    """Default rate limit key: IP address + path.

    X-Forwarded-For is only honoured when the direct upstream client
    (request.client.host) is within a trusted CIDR (settings.TRUSTED_PROXY_IPS).
    Otherwise the direct connection IP is used to prevent header spoofing.
    """
    client_host = request.client.host if request.client else "unknown"

    if _is_trusted_proxy(client_host):
        forwarded = request.headers.get("X-Forwarded-For")
        ip = forwarded.split(",")[0].strip() if forwarded else client_host
    else:
        ip = client_host

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


# Lua script for atomic sliding-window rate limiting.
# Returns: 1 (allowed) or 0 (denied), followed by remaining count and reset TTL.
# KEYS[1] = rate_limit key
# ARGV[1] = now (unix timestamp as float string)
# ARGV[2] = window_start (unix timestamp as float string)
# ARGV[3] = limit (int)
# ARGV[4] = window (int seconds)
_SLIDING_WINDOW_LUA = """
local key = KEYS[1]
local now = tonumber(ARGV[1])
local window_start = tonumber(ARGV[2])
local limit = tonumber(ARGV[3])
local window = tonumber(ARGV[4])

redis.call('ZREMRANGEBYSCORE', key, 0, window_start)
local count = redis.call('ZCARD', key)

if count >= limit then
    return {0, 0, window}
end

redis.call('ZADD', key, now, tostring(now))
redis.call('EXPIRE', key, window)
local remaining = limit - count - 1
return {1, remaining, window}
"""


class RedisRateLimiter:
    """Redis-based rate limiter using sliding window (atomic Lua script)."""

    def __init__(self, requests: int, window: int):
        self.requests = requests
        self.window = window
        self._redis: redis_module.Redis | None = None
        self._script_sha: str | None = None

    async def _get_redis(self) -> "redis_module.Redis":
        """Lazy Redis connection."""
        if self._redis is None:
            import redis.asyncio as redis

            self._redis = redis.from_url(settings.REDIS_URL or "")
        return self._redis

    async def _get_script_sha(self, redis: "redis_module.Redis") -> str:
        """Load the Lua script via SCRIPT LOAD and cache the SHA."""
        if self._script_sha is None:
            self._script_sha = await redis.script_load(_SLIDING_WINDOW_LUA)
        return self._script_sha

    async def is_allowed(self, key: str) -> tuple[bool, int, int]:
        """
        Check if request is allowed using an atomic Redis Lua sliding window.

        The entire check-and-set is a single EVALSHA call, eliminating TOCTOU races.

        Returns:
            tuple: (allowed, remaining, reset_after)
        """
        redis = await self._get_redis()
        now = time.time()
        window_start = now - self.window
        rate_key = f"rate_limit:{key}"

        sha = await self._get_script_sha(redis)
        result = await redis.evalsha(
            sha,
            1,
            rate_key,
            str(now),
            str(window_start),
            str(self.requests),
            str(self.window),
        )

        allowed_flag = int(result[0])
        remaining = int(result[1])
        reset_after = int(result[2])

        return bool(allowed_flag), remaining, reset_after

    async def close(self) -> None:
        """Close Redis connection."""
        if self._redis:
            await self._redis.aclose()
            self._redis = None


# Registry of limiter instances keyed by (requests, window) so each unique
# config gets its own limiter rather than sharing a single global singleton.
_rate_limiter_registry: dict[
    tuple[int, int], InMemoryRateLimiter | RedisRateLimiter
] = {}


def get_rate_limiter(config: RateLimitConfig) -> InMemoryRateLimiter | RedisRateLimiter:
    """Get or create a rate limiter instance for the given (requests, window) config."""
    key = (config.requests, config.window)
    if key not in _rate_limiter_registry:
        if settings.REDIS_URL:
            logger.info(
                "Using Redis rate limiter",
                requests=config.requests,
                window=config.window,
            )
            _rate_limiter_registry[key] = RedisRateLimiter(
                config.requests, config.window
            )
        else:
            logger.warning(
                "Using in-memory rate limiter — limits are not shared across "
                "replicas. Set REDIS_URL in production.",
                requests=config.requests,
                window=config.window,
            )
            _rate_limiter_registry[key] = InMemoryRateLimiter(
                config.requests, config.window
            )
    return _rate_limiter_registry[key]


def rate_limit(
    requests: int = 100,
    window: int = 60,
    key_func: Callable[[Request], str] | None = None,
) -> Callable[[Callable[..., Awaitable[R]]], Callable[..., Awaitable[R]]]:
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
        func: Callable[..., Awaitable[R]],
    ) -> Callable[..., Awaitable[R]]:
        @wraps(func)
        async def wrapper(*args: object, **kwargs: object) -> R:
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
