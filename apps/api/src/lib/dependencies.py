from litestar.di import NamedDependency
from sqlalchemy.ext.asyncio import AsyncSession

from src.lib.auth import (
    CurrentUser,
    CurrentUserInfo,
    JWEAuthenticationMiddleware,
    OptionalUser,
    get_current_user,
    get_optional_user,
    require_auth_guard,
)
from src.lib.database import get_db
from src.lib.storage import StorageProvider, get_storage_provider

# Type alias for database session dependency
DBSession = NamedDependency[AsyncSession]

# Type alias for object storage dependency
Storage = NamedDependency[StorageProvider]

# Re-export auth dependencies and guards for convenience
__all__ = [
    "CurrentUser",
    "CurrentUserInfo",
    "DBSession",
    "JWEAuthenticationMiddleware",
    "OptionalUser",
    "Storage",
    "get_current_user",
    "get_db",
    "get_optional_user",
    "get_storage_provider",
    "require_auth_guard",
]
