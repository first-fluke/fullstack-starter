"""OpenTelemetry configuration for distributed tracing."""

import contextlib

from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter

from src.lib.config import settings


def configure_telemetry() -> None:
    """Configure OpenTelemetry tracing with OTLP exporter."""
    resource = Resource.create(
        {
            "service.name": settings.PROJECT_NAME,
            "service.version": "0.1.0",
            "deployment.environment": settings.PROJECT_ENV,
        }
    )

    provider = TracerProvider(resource=resource)

    # Configure exporter based on environment
    if settings.OTEL_EXPORTER_OTLP_ENDPOINT:
        # OTLP exporter for production (e.g., Jaeger, Tempo, Cloud Trace)
        otlp_exporter = OTLPSpanExporter(
            endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT,
            insecure=settings.PROJECT_ENV != "prod",
        )
        provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
    elif settings.PROJECT_ENV == "local":
        # Console exporter for local development
        provider.add_span_processor(BatchSpanProcessor(ConsoleSpanExporter()))

    trace.set_tracer_provider(provider)


def instrument_app(app: FastAPI) -> None:
    """Instrument FastAPI and other libraries for tracing."""
    from src.lib.database import engine

    # Instrument FastAPI
    FastAPIInstrumentor.instrument_app(
        app,
        excluded_urls="health,health/live,health/ready",
    )

    # Instrument SQLAlchemy
    SQLAlchemyInstrumentor().instrument(
        engine=engine.sync_engine,
        enable_commenter=True,
    )

    # Instrument HTTPX (for outgoing HTTP requests)
    HTTPXClientInstrumentor().instrument()

    # Instrument Redis (if available)
    with contextlib.suppress(Exception):
        RedisInstrumentor().instrument()


def get_tracer(name: str = __name__) -> trace.Tracer:
    """Get a tracer instance for manual instrumentation."""
    return trace.get_tracer(name)
