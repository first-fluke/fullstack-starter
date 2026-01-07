from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.lib.auth import (
    CurrentUser,
    OptionalSession,
    OptionalUser,
    RequiredSession,
    SessionResponse,
    SessionUser,
    get_current_user,
    get_optional_session,
    get_optional_user,
    get_required_session,
)
from src.lib.database import get_db

# Type alias for database session dependency
DBSession = Annotated[AsyncSession, Depends(get_db)]

# Re-export auth dependencies for convenience
__all__ = [
    "DBSession",
    "CurrentUser",
    "OptionalUser",
    "RequiredSession",
    "OptionalSession",
    "SessionUser",
    "SessionResponse",
    "get_current_user",
    "get_optional_user",
    "get_required_session",
    "get_optional_session",
]
