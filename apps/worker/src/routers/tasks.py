from fastapi import APIRouter, BackgroundTasks
from pydantic import BaseModel

router = APIRouter(tags=["Tasks"])


class TaskPayload(BaseModel):
    task_type: str
    data: dict[str, object]


@router.post("/process")
async def process_task(
    payload: TaskPayload,
    background_tasks: BackgroundTasks,
) -> dict[str, str]:
    background_tasks.add_task(execute_task, payload)
    return {"status": "accepted"}


async def execute_task(payload: TaskPayload) -> None:
    match payload.task_type:
        case "analysis":
            pass
        case "embedding":
            pass
        case _:
            pass
