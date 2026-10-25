"""In-process cron scheduler for single-instance deployments.

Runs one job at a time per id, coalesces missed ticks and drains running jobs
on shutdown. Only start it in exactly one worker process: there is no leader
election or distributed lock.
"""

import asyncio
from datetime import datetime
from typing import Literal
from zoneinfo import ZoneInfo

from apscheduler.events import EVENT_SCHEDULER_SHUTDOWN, SchedulerEvent
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from pydantic import BaseModel

from src.jobs import TASKS
from src.lib.logging import get_logger
from src.lib.schedules import ScheduleConfig, ScheduledJob, validate_tasks

logger = get_logger(__name__)

SHUTDOWN_GRACE_SECONDS = 25


class JobStatus(BaseModel):
    id: str
    task: str
    cron: str
    enabled: bool
    next_run_time: datetime | None = None
    completed_runs: int = 0
    last_finished_at: datetime | None = None
    last_result: Literal["success", "error", "cancelled"] | None = None


class SchedulerStatus(BaseModel):
    running: bool
    timezone: str
    jobs: list[JobStatus]


class WorkerScheduler:
    def __init__(self, config: ScheduleConfig) -> None:
        validate_tasks(config)
        self.config = config
        self.timezone = ZoneInfo(config.timezone)
        self.scheduler = AsyncIOScheduler(
            timezone=self.timezone,
            job_defaults={
                "coalesce": True,
                "max_instances": 1,
                "misfire_grace_time": 300,
            },
        )
        self._statuses = {job.id: JobStatus(**job.model_dump()) for job in config.jobs}
        self._active_count = 0
        self._drained = asyncio.Event()
        self._drained.set()

    def start(self) -> None:
        for job in self.config.jobs:
            if job.enabled:
                self.scheduler.add_job(
                    self._run_job,
                    trigger=job.trigger(self.timezone),
                    args=[job],
                    id=job.id,
                    replace_existing=True,
                )
        self.scheduler.start()
        logger.info(
            "scheduler started",
            timezone=self.config.timezone,
            job_ids=[job.id for job in self.config.jobs if job.enabled],
        )

    async def _run_job(self, job: ScheduledJob) -> None:
        status = self._statuses[job.id]
        self._active_count += 1
        self._drained.clear()
        try:
            await TASKS[job.task]()
        except asyncio.CancelledError:
            status.last_result = "cancelled"
            raise
        except Exception:
            status.last_result = "error"
            logger.exception("scheduled job failed", job_id=job.id, task=job.task)
            raise
        else:
            status.completed_runs += 1
            status.last_result = "success"
        finally:
            status.last_finished_at = datetime.now(self.timezone)
            self._active_count -= 1
            if self._active_count == 0:
                self._drained.set()

    def snapshot(self) -> SchedulerStatus:
        jobs: list[JobStatus] = []
        for job in self.config.jobs:
            status = self._statuses[job.id].model_copy()
            scheduled_job = self.scheduler.get_job(job.id)
            if scheduled_job is not None:
                status.next_run_time = scheduled_job.next_run_time
            jobs.append(status)
        return SchedulerStatus(
            running=self.scheduler.running,
            timezone=self.config.timezone,
            jobs=jobs,
        )

    async def stop(self) -> None:
        if not self.scheduler.running:
            return
        self.scheduler.pause()
        # Let jobs already submitted to the executor enter _run_job before draining.
        await asyncio.sleep(0)
        try:
            await asyncio.wait_for(self._drained.wait(), timeout=SHUTDOWN_GRACE_SECONDS)
        except TimeoutError:
            logger.warning("scheduler shutdown grace period exceeded; cancelling jobs")
        stopped: asyncio.Future[None] = asyncio.get_running_loop().create_future()

        def on_shutdown(event: SchedulerEvent) -> None:
            if not stopped.done():
                stopped.set_result(None)

        self.scheduler.add_listener(on_shutdown, EVENT_SCHEDULER_SHUTDOWN)
        # AsyncIOExecutor cancels pending futures even with wait=True, so drain
        # first and then await the asynchronously dispatched shutdown event.
        self.scheduler.shutdown(wait=False)
        await asyncio.wait_for(stopped, timeout=5)
        await asyncio.sleep(0)
