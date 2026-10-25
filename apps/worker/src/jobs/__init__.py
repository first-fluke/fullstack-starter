"""Registry of handlers that ``schedules.toml`` may reference by name.

Jobs are registered in code, never as shell commands or arbitrary imports.
Add a coroutine here and reference its key from the TOML ``task`` field.
"""

from collections.abc import Awaitable, Callable

from src.jobs.heartbeat import scheduler_heartbeat

type TaskHandler = Callable[[], Awaitable[None]]

TASKS: dict[str, TaskHandler] = {
    "scheduler_heartbeat": scheduler_heartbeat,
}
