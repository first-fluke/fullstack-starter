from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from litestar import Litestar, Request, Response
from litestar.config.compression import CompressionConfig
from litestar.exceptions import HTTPException, ValidationException
from litestar.middleware import DefineMiddleware
from litestar.openapi.config import OpenAPIConfig
from litestar.status_codes import HTTP_422_UNPROCESSABLE_ENTITY

from src.lib.config import Settings, get_settings
from src.lib.logging import configure_logging, get_structlog_plugin
from src.lib.middleware import RequestIDMiddleware
from src.lib.scheduler import WorkerScheduler
from src.lib.schedules import load_schedules
from src.routers import tasks
from src.routers.health import build_health_router


def build_scheduler(config: Settings) -> WorkerScheduler | None:
    """Create the cron scheduler when a schedule file is configured.

    Managed stacks deliver scheduled work through Cloud Tasks / Pub/Sub and
    leave ``WORKER_SCHEDULES_FILE`` unset, so they never start a scheduler.
    An invalid file fails startup instead of silently running nothing.
    """
    if config.WORKER_SCHEDULES_FILE is None:
        return None
    return WorkerScheduler(load_schedules(config.WORKER_SCHEDULES_FILE))


def http_exception_handler(
    _request: Request[Any, Any, Any], exc: HTTPException
) -> Response[dict[str, Any]]:
    """Map ValidationException to 422 and format HTTPExceptions consistently."""
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


def create_app(config: Settings | None = None) -> Litestar:
    config = config if config is not None else get_settings()
    runtime = build_scheduler(config)

    @asynccontextmanager
    async def lifespan(_app: Litestar) -> AsyncIterator[None]:
        configure_logging()
        if runtime is not None:
            runtime.start()
        try:
            yield
        finally:
            if runtime is not None:
                await runtime.stop()

    openapi_config = (
        OpenAPIConfig(
            title=f"{config.PROJECT_NAME} Worker",
            version="0.1.0",
            path="/docs",
        )
        if config.PROJECT_ENV != "prod"
        else None
    )

    return Litestar(
        route_handlers=[
            build_health_router(runtime, environment=config.PROJECT_ENV),
            tasks.router,
        ],
        middleware=[DefineMiddleware(RequestIDMiddleware)],
        compression_config=CompressionConfig(backend="gzip", gzip_compress_level=6),
        openapi_config=openapi_config,
        plugins=[get_structlog_plugin()],
        exception_handlers={HTTPException: http_exception_handler},
        lifespan=[lifespan],
    )


app = create_app()
