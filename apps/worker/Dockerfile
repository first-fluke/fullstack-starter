# syntax=docker/dockerfile:1
FROM python:3.14-alpine AS base
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

FROM base AS production
COPY pyproject.toml uv.lock ./
COPY apps/api/pyproject.toml ./apps/api/pyproject.toml
COPY apps/worker/pyproject.toml ./apps/worker/pyproject.toml
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --package worker --no-install-workspace
COPY apps/worker/src ./apps/worker/src

RUN addgroup -g 1000 appuser && \
    adduser -D -u 1000 -G appuser -h /home/appuser -s /bin/sh appuser
USER 1000

WORKDIR /app/apps/worker
EXPOSE 8080
CMD ["/app/.venv/bin/litestar", "--app", "src.main:app", "run", "--host", "0.0.0.0", "--port", "8080"]
