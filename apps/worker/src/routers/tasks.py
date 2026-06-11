"""Task processing router."""

from typing import Annotated, Literal

from fastapi import APIRouter, BackgroundTasks, Depends
from pydantic import BaseModel, Field

from src.lib.logging import get_logger
from src.lib.oidc import verify_oidc_token
from src.lib.retry import with_retry

router = APIRouter(tags=["Tasks"])
logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Payload models
# ---------------------------------------------------------------------------


class AnalysisPayload(BaseModel):
    task_type: Literal["analysis"]
    text: str
    options: dict[str, object] = Field(default_factory=dict)


class EmbeddingPayload(BaseModel):
    task_type: Literal["embedding"]
    content: str
    model: str = "text-embedding-3-small"


TaskPayload = Annotated[
    AnalysisPayload | EmbeddingPayload,
    Field(discriminator="task_type"),
]


# ---------------------------------------------------------------------------
# Route
# ---------------------------------------------------------------------------


@router.post("/process", status_code=202)
async def process_task(
    payload: AnalysisPayload | EmbeddingPayload,
    background_tasks: BackgroundTasks,
    _: None = Depends(verify_oidc_token),
) -> dict[str, str]:
    background_tasks.add_task(execute_task, payload)
    return {"status": "accepted"}


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
