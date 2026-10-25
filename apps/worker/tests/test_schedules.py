"""Tests for the opt-in in-process cron scheduler (WORKER_SCHEDULES_FILE)."""

import asyncio
from datetime import UTC, datetime, timedelta
from pathlib import Path
from zoneinfo import ZoneInfo

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from src.jobs import TASKS
from src.lib.config import Settings
from src.lib.scheduler import WorkerScheduler
from src.lib.schedules import ScheduleConfig, ScheduledJob, load_schedules
from src.main import create_app

COMMITTED_SCHEDULES = Path(__file__).resolve().parents[1] / "schedules.toml"


def schedule(**overrides: object) -> ScheduledJob:
    return ScheduledJob.model_validate(
        {
            "id": "test_job",
            "task": "scheduler_heartbeat",
            "cron": "*/5 * * * *",
            **overrides,
        }
    )


# ---------------------------------------------------------------------------
# Schedule file validation
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "cron",
    ["* * * *", "* * * * * *", "61 * * * *", "* 25 * * *", "0 9 * * 0", "@daily"],
)
def test_invalid_cron_is_rejected(cron: str) -> None:
    with pytest.raises(ValidationError):
        schedule(cron=cron)


def test_next_run_follows_configured_timezone() -> None:
    trigger = schedule().trigger(ZoneInfo("Asia/Seoul"))
    now = datetime(2026, 10, 13, 15, 3, tzinfo=UTC)
    assert trigger.get_next_fire_time(None, now) == datetime(
        2026, 10, 14, 0, 5, tzinfo=ZoneInfo("Asia/Seoul")
    )


def test_bad_timezone_duplicate_ids_and_unknown_keys_are_rejected() -> None:
    with pytest.raises(ValidationError, match="IANA timezone"):
        ScheduleConfig(timezone="Not/A-Timezone")
    with pytest.raises(ValidationError, match="unique"):
        ScheduleConfig(jobs=[schedule(), schedule()])
    with pytest.raises(ValidationError, match="Extra inputs"):
        ScheduleConfig.model_validate({"unknown_key": True})


def test_unregistered_handler_is_rejected_even_if_disabled() -> None:
    config = ScheduleConfig(jobs=[schedule(task="missing_task", enabled=False)])
    with pytest.raises(ValueError, match="Unknown scheduled task"):
        WorkerScheduler(config)


def test_committed_schedule_file_loads_with_registered_tasks() -> None:
    config = load_schedules(COMMITTED_SCHEDULES)
    runtime = WorkerScheduler(config)
    assert runtime.config.timezone == "UTC"
    assert [job.id for job in runtime.config.jobs] == ["scheduler_heartbeat"]


def test_invalid_schedule_file_prevents_app_startup(tmp_path: Path) -> None:
    path = tmp_path / "schedules.toml"
    path.write_text(
        'timezone = "UTC"\n[[jobs]]\nid = "bad"\ncron = "@daily"\n'
        'task = "scheduler_heartbeat"\n'
    )
    with pytest.raises(ValidationError, match="five fields"):
        create_app(Settings(WORKER_SCHEDULES_FILE=path))


# ---------------------------------------------------------------------------
# Scheduler runtime
# ---------------------------------------------------------------------------


async def test_scheduler_executes_tracks_success_and_stops(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    called = asyncio.Event()

    async def probe() -> None:
        called.set()

    monkeypatch.setitem(TASKS, "scheduler_heartbeat", probe)
    runtime = WorkerScheduler(ScheduleConfig(jobs=[schedule()]))
    runtime.start()
    try:
        runtime.scheduler.reschedule_job(
            "test_job",
            trigger="date",
            run_date=datetime.now(UTC) + timedelta(milliseconds=20),
        )
        await asyncio.wait_for(called.wait(), timeout=2)
        await asyncio.sleep(0)
        status = runtime.snapshot().jobs[0]
        assert status.completed_runs == 1
        assert status.last_result == "success"
        assert status.last_finished_at is not None
    finally:
        await runtime.stop()
    assert runtime.scheduler.running is False
    await runtime.stop()  # Shutdown is idempotent.


async def test_disabled_jobs_do_not_register() -> None:
    runtime = WorkerScheduler(ScheduleConfig(jobs=[schedule(enabled=False)]))
    runtime.start()
    try:
        assert runtime.scheduler.get_jobs() == []
        snapshot = runtime.snapshot()
        assert snapshot.running is True
        assert snapshot.jobs[0].next_run_time is None
    finally:
        await runtime.stop()


async def test_long_job_does_not_overlap_and_shutdown_waits(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    started = asyncio.Event()
    release = asyncio.Event()
    active = 0
    peak_active = 0

    async def probe() -> None:
        nonlocal active, peak_active
        active += 1
        peak_active = max(peak_active, active)
        started.set()
        try:
            await release.wait()
        finally:
            active -= 1

    monkeypatch.setitem(TASKS, "scheduler_heartbeat", probe)
    runtime = WorkerScheduler(ScheduleConfig(jobs=[schedule()]))
    runtime.start()
    try:
        runtime.scheduler.reschedule_job("test_job", trigger="interval", seconds=0.02)
        await asyncio.wait_for(started.wait(), timeout=2)
        await asyncio.sleep(0.08)
        assert peak_active == 1
        stop = asyncio.create_task(runtime.stop())
        await asyncio.sleep(0.02)
        assert not stop.done()
        release.set()
        await asyncio.wait_for(stop, timeout=2)
        assert active == 0
        assert runtime.snapshot().jobs[0].last_result == "success"
    finally:
        release.set()
        await runtime.stop()


async def test_failed_job_is_reported_and_scheduler_keeps_running(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    failed = asyncio.Event()

    async def probe() -> None:
        failed.set()
        raise RuntimeError("test failure")

    monkeypatch.setitem(TASKS, "scheduler_heartbeat", probe)
    runtime = WorkerScheduler(ScheduleConfig(jobs=[schedule()]))
    runtime.start()
    try:
        runtime.scheduler.reschedule_job(
            "test_job", trigger="date", run_date=datetime.now(UTC)
        )
        await asyncio.wait_for(failed.wait(), timeout=2)
        await asyncio.sleep(0)
        assert runtime.snapshot().jobs[0].last_result == "error"
        assert runtime.snapshot().running is True
    finally:
        await runtime.stop()


# ---------------------------------------------------------------------------
# Health integration
# ---------------------------------------------------------------------------


def test_health_without_schedule_file_has_no_scheduler() -> None:
    with TestClient(create_app(Settings(WORKER_SCHEDULES_FILE=None))) as client:
        payload = client.get("/health").json()
    assert payload["status"] == "healthy"
    assert payload["scheduler"] is None


def test_health_reports_running_scheduler_inside_lifespan() -> None:
    app = create_app(Settings(WORKER_SCHEDULES_FILE=COMMITTED_SCHEDULES))
    with TestClient(app) as client:
        response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["scheduler"]["running"] is True
    assert payload["scheduler"]["timezone"] == "UTC"
    assert [job["id"] for job in payload["scheduler"]["jobs"]] == [
        "scheduler_heartbeat"
    ]
    assert payload["scheduler"]["jobs"][0]["next_run_time"] is not None


def test_health_is_503_when_scheduler_is_not_running() -> None:
    # Outside the lifespan the scheduler never started; a stopped scheduler
    # must fail the container health check so Compose restarts it.
    client = TestClient(create_app(Settings(WORKER_SCHEDULES_FILE=COMMITTED_SCHEDULES)))
    response = client.get("/health")
    assert response.status_code == 503
    assert response.json()["status"] == "unhealthy"
    assert response.json()["scheduler"]["running"] is False
