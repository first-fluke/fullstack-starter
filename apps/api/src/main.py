from collections.abc import AsyncIterator, Awaitable, Callable
from contextlib import asynccontextmanager
from typing import TYPE_CHECKING, Literal, cast
from uuid import uuid4

import structlog
from fastapi import FastAPI, Request, Response, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from opentelemetry import trace
from pydantic import BaseModel
from sqlalchemy import text

from src.lib.config import settings
from src.lib.database import async_session_factory
from src.lib.logging import configure_logging, get_logger
from src.lib.telemetry import configure_telemetry, instrument_app

if TYPE_CHECKING:
    import redis.asyncio as redis_module

# Configure logging first
configure_logging()
logger = get_logger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    """Application lifespan handler for startup/shutdown events."""
    # Startup
    logger.info("Starting application", env=settings.PROJECT_ENV)
    configure_telemetry()
    instrument_app(app)
    yield
    # Shutdown
    logger.info("Shutting down application")


app = FastAPI(
    title=settings.PROJECT_NAME,
    version="0.1.0",
    lifespan=lifespan,
    docs_url="/docs" if settings.PROJECT_ENV != "prod" else None,
    redoc_url="/redoc" if settings.PROJECT_ENV != "prod" else None,
)


# Request ID middleware
@app.middleware("http")
async def request_id_middleware(
    request: Request, call_next: Callable[[Request], Awaitable[Response]]
) -> Response:
    """Add request ID to each request for tracing."""
    request_id = request.headers.get("X-Request-ID", str(uuid4()))

    # Bind request ID to structlog context
    structlog.contextvars.clear_contextvars()
    structlog.contextvars.bind_contextvars(request_id=request_id)

    # Add to current span
    span = trace.get_current_span()
    if span.is_recording():
        span.set_attribute("request.id", request_id)

    response = await call_next(request)
    response.headers["X-Request-ID"] = request_id
    return response


# Error response model
class ErrorResponse(BaseModel):
    """Standard error response format."""

    error: str
    message: str
    request_id: str | None = None
    trace_id: str | None = None


# Global exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    """Handle all unhandled exceptions with consistent format."""
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
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            error="internal_server_error",
            message="An unexpected error occurred"
            if settings.PROJECT_ENV == "prod"
            else str(exc),
            request_id=request_id,
            trace_id=trace_id,
        ).model_dump(),
    )


# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ServiceStatus(BaseModel):
    """Individual service health status."""

    status: Literal["healthy", "unhealthy"]
    latency_ms: float | None = None
    error: str | None = None


class HealthResponse(BaseModel):
    """Health check response with detailed service statuses."""

    status: Literal["healthy", "degraded", "unhealthy"]
    version: str = "0.1.0"
    services: dict[str, ServiceStatus]


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

        client = cast(redis_module.Redis, redis.from_url(settings.REDIS_URL))  # type: ignore[no-untyped-call]
        await client.ping()  # type: ignore[misc]
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


@app.get("/health")
async def health_check() -> HealthResponse:
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


@app.get("/health/live")
async def liveness_check() -> dict[str, str]:
    """Simple liveness probe for Kubernetes."""
    return {"status": "ok"}


@app.get("/health/ready")
async def readiness_check() -> dict[str, str]:
    """Readiness probe - checks if app can serve traffic."""
    db_status = await check_database()
    if db_status.status == "unhealthy":
        from fastapi import HTTPException, status

        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Database not ready",
        )
    return {"status": "ready"}


# Register routers here
# from src.users.router import router as users_router
# app.include_router(users_router, prefix="/api")
