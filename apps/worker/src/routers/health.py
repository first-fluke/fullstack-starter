"""Health check router."""

from typing import Literal

import msgspec
from litestar import Response, Router, get
from litestar.status_codes import HTTP_200_OK, HTTP_503_SERVICE_UNAVAILABLE

from src.lib.config import settings
from src.lib.scheduler import SchedulerStatus, WorkerScheduler


class HealthResponse(msgspec.Struct):
    status: Literal["healthy", "unhealthy"]
    environment: str
    version: str = "0.1.0"
    # Present only when WORKER_SCHEDULES_FILE enables the in-process scheduler.
    scheduler: SchedulerStatus | None = None


def build_health_router(runtime: WorkerScheduler | None) -> Router:
    @get("/health", tags=["Health"])
    async def health_check() -> Response[HealthResponse]:
        scheduler = runtime.snapshot() if runtime is not None else None
        healthy = scheduler is None or scheduler.running
        return Response(
            content=HealthResponse(
                status="healthy" if healthy else "unhealthy",
                environment=settings.PROJECT_ENV,
                scheduler=scheduler,
            ),
            status_code=HTTP_200_OK if healthy else HTTP_503_SERVICE_UNAVAILABLE,
        )

    return Router(path="/", route_handlers=[health_check])
