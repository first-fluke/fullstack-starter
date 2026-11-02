"""Health check router."""

from typing import Literal

import msgspec
from litestar import Controller, Response, Router, get
from litestar.di import NamedDependency, Provide
from litestar.status_codes import HTTP_200_OK, HTTP_503_SERVICE_UNAVAILABLE

from src.lib.config import settings
from src.lib.scheduler import SchedulerStatus, WorkerScheduler


class HealthResponse(msgspec.Struct):
    status: Literal["healthy", "unhealthy"]
    environment: str
    version: str = "0.1.0"
    # Present only when WORKER_SCHEDULES_FILE enables the in-process scheduler.
    scheduler: SchedulerStatus | None = None


class HealthController(Controller):
    """Health checks using the scheduler attached to this application."""

    path = "/"

    @get("/health", tags=["Health"], operation_id="HealthHealthCheck")
    async def health_check(
        self,
        runtime: NamedDependency[WorkerScheduler | None],
        environment: NamedDependency[str],
    ) -> Response[HealthResponse]:
        scheduler = runtime.snapshot() if runtime is not None else None
        healthy = scheduler is None or scheduler.running
        return Response(
            content=HealthResponse(
                status="healthy" if healthy else "unhealthy",
                environment=environment,
                scheduler=scheduler,
            ),
            status_code=HTTP_200_OK if healthy else HTTP_503_SERVICE_UNAVAILABLE,
        )


def build_health_router(
    runtime: WorkerScheduler | None,
    *,
    environment: str | None = None,
) -> Router:
    configured_environment = (
        settings.PROJECT_ENV if environment is None else environment
    )

    def scheduler_runtime() -> WorkerScheduler | None:
        return runtime

    def project_environment() -> str:
        return configured_environment

    return Router(
        path="/",
        route_handlers=[HealthController],
        dependencies={
            "runtime": Provide(scheduler_runtime, sync_to_thread=False),
            "environment": Provide(project_environment, sync_to_thread=False),
        },
    )
