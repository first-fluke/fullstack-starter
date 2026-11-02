"""Task processing controller."""

from typing import Literal

import msgspec
from litestar import Controller, Response, Router, post
from litestar.background_tasks import BackgroundTask
from litestar.params import JSONBody
from litestar.status_codes import HTTP_202_ACCEPTED

from src.lib.logging import get_logger
from src.lib.oidc import verify_oidc_guard
from src.lib.retry import with_retry

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Payload models
# ---------------------------------------------------------------------------


class AnalysisPayload(msgspec.Struct, tag_field="task_type", tag="analysis"):
    text: str
    options: dict[str, object] = msgspec.field(default_factory=dict)

    @property
    def task_type(self) -> Literal["analysis"]:
        return "analysis"


class EmbeddingPayload(msgspec.Struct, tag_field="task_type", tag="embedding"):
    content: str
    model: str = "text-embedding-3-small"

    @property
    def task_type(self) -> Literal["embedding"]:
        return "embedding"


type TaskPayload = AnalysisPayload | EmbeddingPayload


# ---------------------------------------------------------------------------
# Controller & Route
# ---------------------------------------------------------------------------


class TasksController(Controller):
    """Task processing endpoints guarded by Google OIDC verification."""

    path = "/"
    guards = (verify_oidc_guard,)

    @post("/process", status_code=HTTP_202_ACCEPTED)
    async def process_task(
        self,
        data: JSONBody[AnalysisPayload | EmbeddingPayload],
    ) -> Response[dict[str, str]]:
        return Response(
            content={"status": "accepted"},
            status_code=HTTP_202_ACCEPTED,
            background=BackgroundTask(execute_task, data),
        )


router = Router(
    path="/tasks",
    tags=["Tasks"],
    route_handlers=[TasksController],
)


# ---------------------------------------------------------------------------
# Background task execution
# ---------------------------------------------------------------------------


@with_retry()
async def execute_task(payload: AnalysisPayload | EmbeddingPayload) -> None:
    """Execute the given task payload with automatic retry on transient failures."""
    bound_logger = logger.bind(task_type=payload.task_type)
    try:
        match payload:
            case AnalysisPayload():
                bound_logger.info("executing analysis task")
            case EmbeddingPayload():
                bound_logger.info("executing embedding task")
    except Exception:
        bound_logger.exception(
            "task execution failed",
            exc_info=True,
        )
        raise
