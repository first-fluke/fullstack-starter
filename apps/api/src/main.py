from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any, Literal
from uuid import uuid4

import msgspec
import structlog
from litestar import Controller, Litestar, Request, Response, get
from litestar.config.compression import CompressionConfig
from litestar.config.cors import CORSConfig
from litestar.di import Provide
from litestar.exceptions import HTTPException, ValidationException
from litestar.middleware import DefineMiddleware
from litestar.openapi.config import OpenAPIConfig
from litestar.openapi.spec import Components, SecurityScheme
from litestar.status_codes import (
    HTTP_422_UNPROCESSABLE_ENTITY,
    HTTP_500_INTERNAL_SERVER_ERROR,
    HTTP_503_SERVICE_UNAVAILABLE,
)
from litestar.types import ASGIApp, Message, Receive, Scope, Send
from opentelemetry import trace
from sqlalchemy import text

from src.auth.router import router as auth_router
from src.lib.auth import JWEAuthenticationMiddleware
from src.lib.body_limit import BodySizeLimitMiddleware
from src.lib.config import settings
from src.lib.database import async_session_factory
from src.lib.dependencies import (
    get_current_user,
    get_db,
    get_optional_user,
    get_storage_provider,
)
from src.lib.logging import configure_logging, get_logger, get_structlog_plugin
from src.lib.storage import aclose_storage_provider
from src.lib.stores import create_store_registry
from src.lib.telemetry import (
    configure_telemetry,
    get_opentelemetry_plugin,
    instrument_app,
)

# Configure logging first
configure_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: Litestar) -> AsyncIterator[None]:
    """Application lifespan handler for startup/shutdown events."""
    # Startup
    logger.info("Starting application", env=settings.PROJECT_ENV)
    configure_telemetry()
    instrument_app(app)
    yield
    # Shutdown
    logger.info("Shutting down application")
    await aclose_storage_provider()


class RequestIDMiddleware:
    """Add request ID to each request for tracing."""

    def __init__(self, app: ASGIApp) -> None:
        self.app = app

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        request_id: str | None = None
        for name, value in scope.get("headers", []):
            if name.lower() == b"x-request-id":
                request_id = value.decode("latin-1")
                break
        if not request_id:
            request_id = str(uuid4())

        # Bind request ID to structlog context
        structlog.contextvars.clear_contextvars()
        structlog.contextvars.bind_contextvars(request_id=request_id)

        # Add to current span
        span = trace.get_current_span()
        if span.is_recording():
            span.set_attribute("request.id", request_id)

        req_id_bytes = request_id.encode("latin-1")

        async def wrapped_send(message: Message) -> None:
            if message["type"] == "http.response.start":
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", req_id_bytes))
                message["headers"] = headers
            await send(message)

        await self.app(scope, receive, wrapped_send)


# Error response model
class ErrorResponse(msgspec.Struct):
    """Standard error response format."""

    error: str
    message: str
    request_id: str | None = None
    trace_id: str | None = None


def http_exception_handler(
    _request: Request[Any, Any, Any], exc: HTTPException
) -> Response[dict[str, Any]]:
    """Handle Litestar HTTPExceptions with a consistent JSON body."""
    if isinstance(exc, ValidationException):
        return Response(
            status_code=HTTP_422_UNPROCESSABLE_ENTITY,
            content={"detail": exc.detail, "extra": exc.extra},
            headers=exc.headers,
        )
    return Response(
        status_code=exc.status_code,
        content={"detail": exc.detail},
        headers=exc.headers,
    )


def global_exception_handler(
    request: Request[Any, Any, Any], exc: Exception
) -> Response[Any]:
    """Handle all unhandled exceptions with consistent format."""
    if isinstance(exc, HTTPException):
        return http_exception_handler(request, exc)

    request_id = request.headers.get("X-Request-ID")

    # Get trace context
    span = trace.get_current_span()
    trace_id = None
    if span.is_recording():
        ctx = span.get_span_context()
        trace_id = format(ctx.trace_id, "032x")
        span.record_exception(exc)
        span.set_status(trace.StatusCode.ERROR, str(exc))

    # Log the exception
    logger.exception(
        "Unhandled exception",
        exc_info=exc,
        request_id=request_id,
        path=request.url.path,
        method=request.method,
    )

    # Return consistent error response
    return Response(
        status_code=HTTP_500_INTERNAL_SERVER_ERROR,
        content=msgspec.to_builtins(
            ErrorResponse(
                error="internal_server_error",
                message="An unexpected error occurred"
                if settings.PROJECT_ENV == "prod"
                else str(exc),
                request_id=request_id,
                trace_id=trace_id,
            )
        ),
    )


class ServiceStatus(msgspec.Struct):
    """Individual service health status."""

    status: Literal["healthy", "unhealthy"]
    latency_ms: float | None = None
    error: str | None = None


class HealthResponse(msgspec.Struct):
    """Health check response with detailed service statuses."""

    status: Literal["healthy", "degraded", "unhealthy"]
    services: dict[str, ServiceStatus]
    version: str = "0.1.0"


async def check_database() -> ServiceStatus:
    """Check database connectivity."""
    import time

    start = time.perf_counter()
    try:
        async with async_session_factory() as session:
            await session.execute(text("SELECT 1"))
        latency = (time.perf_counter() - start) * 1000
        return ServiceStatus(status="healthy", latency_ms=round(latency, 2))
    except Exception as e:
        latency = (time.perf_counter() - start) * 1000
        return ServiceStatus(
            status="unhealthy", latency_ms=round(latency, 2), error=str(e)
        )


async def check_redis() -> ServiceStatus | None:
    """Check Redis connectivity if configured."""
    import time

    if not settings.REDIS_URL:
        return None

    start = time.perf_counter()
    try:
        import redis.asyncio as redis

        client = redis.from_url(settings.REDIS_URL)
        await client.ping()
        await client.aclose()
        latency = (time.perf_counter() - start) * 1000
        return ServiceStatus(status="healthy", latency_ms=round(latency, 2))
    except ImportError:
        return ServiceStatus(status="unhealthy", error="redis package not installed")
    except Exception as e:
        latency = (time.perf_counter() - start) * 1000
        return ServiceStatus(
            status="unhealthy", latency_ms=round(latency, 2), error=str(e)
        )


class HealthController(Controller):
    """Health, liveness, and readiness probes."""

    path = "/health"

    @get("/", operation_id="health_check_health_get")
    async def health_check(self) -> HealthResponse:
        """Detailed health check endpoint with service statuses."""
        services: dict[str, ServiceStatus] = {}

        # Check database
        services["database"] = await check_database()

        # Check Redis (if configured)
        redis_status = await check_redis()
        if redis_status:
            services["redis"] = redis_status

        # Determine overall status
        statuses = [s.status for s in services.values()]
        if all(s == "healthy" for s in statuses):
            overall_status: Literal["healthy", "degraded", "unhealthy"] = "healthy"
        elif all(s == "unhealthy" for s in statuses):
            overall_status = "unhealthy"
        else:
            overall_status = "degraded"

        return HealthResponse(
            status=overall_status,
            version="0.1.0",
            services=services,
        )

    @get("/live", operation_id="liveness_check_health_live_get")
    async def liveness_check(self) -> dict[str, str]:
        """Simple liveness probe for Kubernetes."""
        return {"status": "ok"}

    @get("/ready", operation_id="readiness_check_health_ready_get")
    async def readiness_check(self) -> dict[str, str]:
        """Readiness probe - checks if app can serve traffic."""
        db_status = await check_database()
        if db_status.status == "unhealthy":
            raise HTTPException(
                status_code=HTTP_503_SERVICE_UNAVAILABLE,
                detail="Database not ready",
            )
        return {"status": "ready"}


cors_config = CORSConfig(
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

compression_config = CompressionConfig(backend="gzip", gzip_compress_level=6)

openapi_config = (
    OpenAPIConfig(
        title=settings.PROJECT_NAME,
        version="0.1.0",
        path="/docs",
        components=Components(
            security_schemes={
                "BearerToken": SecurityScheme(
                    type="http",
                    scheme="bearer",
                    bearer_format="JWE",
                    description="First-party JWE access token",
                )
            }
        ),
    )
    if settings.PROJECT_ENV != "prod"
    else None
)

app = Litestar(
    route_handlers=[
        HealthController,
        auth_router,
    ],
    dependencies={
        "db": Provide(get_db),
        "storage": Provide(get_storage_provider, sync_to_thread=False),
        "current_user": Provide(get_current_user),
        "optional_user": Provide(get_optional_user),
    },
    stores=create_store_registry(),
    request_max_body_size=settings.MAX_BODY_SIZE,
    middleware=[
        DefineMiddleware(BodySizeLimitMiddleware, max_body_size=settings.MAX_BODY_SIZE),
        DefineMiddleware(RequestIDMiddleware),
        DefineMiddleware(JWEAuthenticationMiddleware, exclude=["^/health"]),
    ],
    cors_config=cors_config,
    compression_config=compression_config,
    openapi_config=openapi_config,
    plugins=[
        get_opentelemetry_plugin(),
        get_structlog_plugin(),
    ],
    exception_handlers={
        HTTPException: http_exception_handler,
        Exception: global_exception_handler,
    },
    lifespan=[lifespan],
)
app.asgi_handler = BodySizeLimitMiddleware(
    app.asgi_handler, max_body_size=settings.MAX_BODY_SIZE
)
