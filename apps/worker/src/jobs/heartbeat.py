"""Liveness job that proves the scheduler is ticking."""

from src.lib.logging import get_logger

logger = get_logger(__name__)


async def scheduler_heartbeat() -> None:
    logger.info("scheduler heartbeat")
