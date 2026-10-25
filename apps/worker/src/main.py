from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from src.lib.config import Settings, get_settings
from src.lib.logging import configure_logging
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


def create_app(config: Settings | None = None) -> FastAPI:
    config = config if config is not None else get_settings()
    runtime = build_scheduler(config)

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        configure_logging()
        if runtime is not None:
            runtime.start()
        try:
            yield
        finally:
            if runtime is not None:
                await runtime.stop()

    app = FastAPI(
        title=f"{config.PROJECT_NAME} Worker",
        version="0.1.0",
        lifespan=lifespan,
        docs_url="/docs" if config.PROJECT_ENV != "prod" else None,
    )

    app.add_middleware(RequestIDMiddleware)

    app.include_router(build_health_router(runtime))
    app.include_router(tasks.router, prefix="/tasks")
    return app


app = create_app()
