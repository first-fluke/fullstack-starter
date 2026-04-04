import uuid as uuid_lib
from datetime import datetime

from pydantic import BaseModel
from sqlalchemy import DateTime, String, func
from sqlalchemy.orm import Mapped, mapped_column

from src.lib.database import Base


class User(Base):
    """User model for authentication."""

    __tablename__ = "users"

    id: Mapped[uuid_lib.UUID] = mapped_column(
        primary_key=True,
        default=uuid_lib.uuid4,
    )
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str | None] = mapped_column(String(255), nullable=True)
    image: Mapped[str | None] = mapped_column(String(500), nullable=True)
    email_verified: Mapped[bool] = mapped_column(default=False)
    password_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
    )


class UserResponse(BaseModel):
    """User response model."""

    id: str
    email: str
    name: str | None = None
    image: str | None = None
    email_verified: bool = False
    created_at: datetime
    updated_at: datetime
