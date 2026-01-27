---
name: fastapi-router-creator
description: Guide for creating and organizing FastAPI routes using a file-based routing system or modular router pattern. Helps organize complex API structures.
---

# FastAPI Router Creator

This skill guides the creation of modular, organized FastAPI routers, emphasizing maintainability and scalability.

## Routing Strategies

### 1. Modular Router Pattern (Standard)

The most common and recommended approach for FastAPI.

**Structure:**
```
src/api/v1/endpoints/
├── users.py
├── items.py
└── auth.py
```

**Implementation:**

`src/api/v1/endpoints/users.py`:
```python
from fastapi import APIRouter

router = APIRouter()

@router.get("/")
async def get_users():
    ...
```

`src/api/v1/api.py` (Aggregator):
```python
from fastapi import APIRouter
from src.api.v1.endpoints import users, items

api_router = APIRouter()
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(items.router, prefix="/items", tags=["items"])
```

### 2. File-Based Routing (fastapi-router)

For a Next.js-like experience where file structure dictates URLs. (Requires `fastapi-router` library or custom walker).

**Structure:**
```
src/app/
├── api/
│   ├── users/
│   │   ├── route.py  # Handles /api/users
│   │   └── [id]/
│   │       └── route.py # Handles /api/users/{id}
```

## Best Practices

1.  **Prefixing**: Use prefixes at the router include level, not inside every endpoint decorator.
2.  **Tags**: Use tags to group endpoints in OpenAPI docs.
3.  **Dependencies**: Apply dependencies (like auth) at the router level if they apply to all endpoints in that router.
    ```python
    router = APIRouter(dependencies=[Depends(get_current_active_user)])
    ```
4.  **Version**: Namespace routers by API version (`v1`, `v2`).
