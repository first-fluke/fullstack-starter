---
name: backend-development
description: Comprehensive backend development skill for building scalable backend systems using Python (FastAPI), Postgres, Redis, and more. Includes API design, database optimization, security implementation, and performance tuning.
---

# Backend Development

This skill provides expert guidance for building robust, scalable, and secure backend systems, primarily focusing on the Python/FastAPI ecosystem used in this project.

## Core Capabilities

### 1. API Design & Implementation
- **RESTful Design**: Resource-oriented URLs, proper HTTP methods, and status codes.
- **FastAPI Best Practices**: Validation with Pydantic, dependency injection, and async handlers.
- **Documentation**: Automatic OpenAPI generation, clear descriptions, and examples.

### 2. Database Management
- **Schema Design**: Normalized relationships, indexing strategies, and migration management (Alembic).
- **ORM Usage**: SQLAlchemy async session management, repository pattern.
- **Optimization**: N+1 problem avoidance, query analysis, connection pooling.

### 3. Security
- **Authentication**: JWT/OAuth2 implementation, password hashing (bcrypt/argon2).
- **Authorization**: Role-Based Access Control (RBAC), scopes.
- **Data Protection**: Input sanitization, SQL injection prevention (via ORM), secure headers.

### 4. Performance Tuning
- **Caching**: Redis implementation for specific endpoints or data.
- **Async I/O**: Non-blocking database and API calls.
- **Background Tasks**: Offloading heavy processing (Celery/Cloud Tasks).

## Design Patterns

- **Repository Pattern**: Decouple business logic from data access.
- **Dependency Injection**: Manage dependencies (DB sessions, config) cleanly.
- **Service Layer**: Encapsulate complex business rules.

## When to Use

- Designing new API endpoints or microservices.
- Optimizing slow database queries.
- Implementing complex business logic.
- Reviewing backend code for security and performance.
- Setting up authentication and authorization flows.
