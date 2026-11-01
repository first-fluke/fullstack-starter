"""Cron schedule definitions loaded from a TOML file.

Used by the single-VM deployment (``apps/infra/vm``) where no cloud scheduler
exists. Managed stacks keep Cloud Scheduler / EventBridge and never set
``WORKER_SCHEDULES_FILE``.
"""

import argparse
import json
import tomllib
from datetime import datetime
from pathlib import Path
from typing import Annotated
from zoneinfo import ZoneInfo

import msgspec
from apscheduler.triggers.cron import CronTrigger
from msgspec import Meta

from src.jobs import TASKS


class ScheduledJob(msgspec.Struct, forbid_unknown_fields=True):
    id: Annotated[str, Meta(pattern=r"^[a-z][a-z0-9_]{0,63}$")]
    task: Annotated[str, Meta(min_length=1)]
    cron: str
    enabled: bool = True

    def __post_init__(self) -> None:
        fields = self.cron.split()
        if len(fields) != 5:
            raise ValueError("cron requires five fields: minute hour day month weekday")
        # APScheduler numbers weekdays mon=0, unlike crontab's sun=0. Names are
        # unambiguous in both, so only names are accepted.
        if any(character.isdigit() for character in fields[4]):
            raise ValueError("Use weekday names mon..sun, not weekday numbers")
        CronTrigger.from_crontab(self.cron, timezone=ZoneInfo("UTC"))

    def trigger(self, timezone: ZoneInfo) -> CronTrigger:
        return CronTrigger.from_crontab(self.cron, timezone=timezone)


class ScheduleConfig(msgspec.Struct, forbid_unknown_fields=True):
    timezone: str = "UTC"
    jobs: list[ScheduledJob] = msgspec.field(default_factory=list)

    def __post_init__(self) -> None:
        try:
            ZoneInfo(self.timezone)
        except (KeyError, ValueError) as error:
            raise ValueError("timezone must be an IANA timezone name") from error

        ids = [job.id for job in self.jobs]
        if len(ids) != len(set(ids)):
            raise ValueError("Scheduled job ids must be unique")


def validate_tasks(config: ScheduleConfig) -> None:
    """Reject jobs that reference handlers missing from the registry."""
    for job in config.jobs:
        if job.task not in TASKS:
            raise ValueError(f"Unknown scheduled task: {job.task}")


def load_schedules(path: Path) -> ScheduleConfig:
    with path.open("rb") as schedule_file:
        config = msgspec.convert(
            tomllib.load(schedule_file), type=ScheduleConfig, strict=True
        )
    validate_tasks(config)
    return config


def main() -> None:
    """Validate a schedule file and print the next fire time of every job."""
    parser = argparse.ArgumentParser(
        description="Validate and preview worker schedules"
    )
    parser.add_argument(
        "--file",
        type=Path,
        default=Path(__file__).resolve().parents[2] / "schedules.toml",
    )
    arguments = parser.parse_args()
    config = load_schedules(arguments.file)
    timezone = ZoneInfo(config.timezone)
    now = datetime.now(timezone)
    rows: list[dict[str, object]] = []
    for job in config.jobs:
        next_run = job.trigger(timezone).get_next_fire_time(None, now)
        rows.append(
            {
                **msgspec.structs.asdict(job),
                "next_run_time": next_run.isoformat()
                if job.enabled and next_run is not None
                else None,
            }
        )
    print(json.dumps({"timezone": config.timezone, "jobs": rows}, indent=2))


if __name__ == "__main__":
    main()
