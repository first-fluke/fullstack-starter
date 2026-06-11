"""Health check router."""

from fastapi import APIRouter

from src.lib.config import settings

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_check() -> dict[str, str]:
    return {
        "status": "healthy",
        "version": "0.1.0",
        "environment": settings.PROJECT_ENV,
    }
