---
name: fastapi-templates
description: Production-ready FastAPI project templates and patterns. Use when starting new FastAPI projects, services, or adding standard components like auth, DB connection, or middleware.
---

# FastAPI Templates

This skill provides production-ready templates and scaffolding patterns for FastAPI applications.

## When to Use

- Starting a new FastAPI service or project.
- Adding standard components (Auth, DB, Logging) to an existing app.
- Standardizing project structure across the team.

## Project Structure Template

Recommended structure for scalable FastAPI apps:

```
src/
├── api/
│   ├── v1/
│   │   ├── endpoints/  # Route handlers
│   │   └── api.py      # Router aggregation
│   └── deps.py         # Dependencies (get_current_user, etc.)
├── core/
│   ├── config.py       # Pydantic BaseSettings
│   └── security.py     # JWT & Password hashing
├── db/
│   ├── models/         # SQLAlchemy models
│   ├── session.py      # DB engine and session factory
│   └── base.py         # Import all models here
├── schemas/            # Pydantic models (Request/Response)
├── services/           # Business logic
└── main.py             # App entrypoint
```

## Code Templates

### 1. Standard API Endpoint

```python
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from src.api import deps
from src.schemas.item import ItemCreate, Item
from src.services import item_service

router = APIRouter()

@router.post("/", response_model=Item)
async def create_item(
    item_in: ItemCreate,
    db: AsyncSession = Depends(deps.get_db),
    current_user = Depends(deps.get_current_user),
) -> Item:
    """
    Create a new item.
    """
    return await item_service.create(db, obj_in=item_in, owner_id=current_user.id)
```

### 2. Pydantic Settings

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "FastAPI App"
    DATABASE_URL: str
    SECRET_KEY: str

    class Config:
        case_sensitive = True
        env_file = ".env"

settings = Settings()
```

### 3. SQLAlchemy Async Model

```python
from sqlalchemy import Column, Integer, String
from src.db.base_class import Base

class Item(Base):
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String, nullable=True)
```
