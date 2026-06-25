from typing import Annotated

from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession

from src.lib.auth import (
    CurrentUser,
    CurrentUserInfo,
    OptionalUser,
    get_current_user,
    get_optional_user,
)
from src.lib.database import get_db
from src.lib.storage import StorageProvider, get_storage_provider

# Type alias for database session dependency
DBSession = Annotated[AsyncSession, Depends(get_db)]

# Type alias for object storage dependency
Storage = Annotated[StorageProvider, Depends(get_storage_provider)]

# Re-export auth dependencies for convenience
__all__ = [
    "CurrentUser",
    "CurrentUserInfo",
    "DBSession",
    "OptionalUser",
    "Storage",
    "get_current_user",
    "get_optional_user",
]
