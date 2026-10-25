"""Health check router."""

from typing import Literal

from fastapi import APIRouter, Response
from pydantic import BaseModel

from src.lib.config import settings
from src.lib.scheduler import SchedulerStatus, WorkerScheduler


class HealthResponse(BaseModel):
    status: Literal["healthy", "unhealthy"]
    version: str = "0.1.0"
    environment: str
    # Present only when WORKER_SCHEDULES_FILE enables the in-process scheduler.
    scheduler: SchedulerStatus | None = None


def build_health_router(runtime: WorkerScheduler | None) -> APIRouter:
    router = APIRouter(tags=["Health"])

    @router.get("/health", response_model=HealthResponse)
    async def health_check(response: Response) -> HealthResponse:
        scheduler = runtime.snapshot() if runtime is not None else None
        healthy = scheduler is None or scheduler.running
        if not healthy:
            response.status_code = 503
        return HealthResponse(
            status="healthy" if healthy else "unhealthy",
            environment=settings.PROJECT_ENV,
            scheduler=scheduler,
        )

    return router
