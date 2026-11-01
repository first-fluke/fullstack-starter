"""Structured logging with OpenTelemetry correlation and Litestar StructlogPlugin."""

import logging
import sys
from typing import Any, cast

import structlog
from litestar.logging.config import StructLoggingConfig
from litestar.plugins.structlog import StructlogConfig, StructlogPlugin
from opentelemetry import trace

from src.lib.config import settings


def add_trace_context(
    logger: logging.Logger,
    method_name: str,
    event_dict: dict[str, Any],
) -> dict[str, Any]:
    """Add OpenTelemetry trace context to log entries."""
    span = trace.get_current_span()
    if span.is_recording():
        ctx = span.get_span_context()
        event_dict["trace_id"] = format(ctx.trace_id, "032x")
        event_dict["span_id"] = format(ctx.span_id, "016x")
    return event_dict


def _build_processors() -> list[Any]:
    """Build structlog processor chain."""
    use_json = settings.PROJECT_ENV != "local"
    processors: list[Any] = [
        structlog.contextvars.merge_contextvars,
        structlog.stdlib.add_log_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.UnicodeDecoder(),
        add_trace_context,
    ]
    if use_json:
        processors.append(structlog.processors.JSONRenderer())
    else:
        processors.append(structlog.dev.ConsoleRenderer(colors=True))
    return processors


def configure_logging() -> None:
    """Configure structured logging with optional JSON output for production."""
    processors = _build_processors()

    structlog.configure(
        processors=processors,
        wrapper_class=structlog.stdlib.BoundLogger,
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )

    # Configure standard library logging
    log_level = logging.DEBUG if settings.PROJECT_ENV == "local" else logging.INFO

    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=log_level,
    )

    # Suppress noisy loggers
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)


def get_structlog_plugin() -> StructlogPlugin:
    """Create the Litestar StructlogPlugin with OpenTelemetry processors."""
    return StructlogPlugin(
        config=StructlogConfig(
            structlog_logging_config=StructLoggingConfig(
                processors=_build_processors(),
                wrapper_class=structlog.stdlib.BoundLogger,
                logger_factory=structlog.stdlib.LoggerFactory(),
                cache_logger_on_first_use=True,
            ),
            enable_middleware_logging=False,
        )
    )


def get_logger(name: str | None = None) -> structlog.stdlib.BoundLogger:
    """Get a configured structured logger."""
    return cast(structlog.stdlib.BoundLogger, structlog.get_logger(name))
