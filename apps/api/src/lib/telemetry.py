"""OpenTelemetry configuration for distributed tracing, metrics, and logs."""

import contextlib
import os

from fastapi import FastAPI
from opentelemetry import metrics, trace
from opentelemetry._logs import set_logger_provider
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor
from opentelemetry.instrumentation.redis import RedisInstrumentor
from opentelemetry.instrumentation.sqlalchemy import SQLAlchemyInstrumentor
from opentelemetry.sdk._logs import LoggerProvider
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import (
    ConsoleMetricExporter,
    MetricReader,
    PeriodicExportingMetricReader,
)
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor, ConsoleSpanExporter

from src.lib.config import settings


def _configure_genai_env() -> None:
    """Set GenAI semantic-convention env defaults before instrumentors load.

    The OTel GenAI conventions are still in ``Development`` status (2026-Q2), so
    instrumentations stay on the pre-1.37 attribute set unless explicitly opted
    into the latest experimental conventions. Existing opt-ins are preserved.
    """
    optins = [
        v.strip()
        for v in os.environ.get("OTEL_SEMCONV_STABILITY_OPT_IN", "").split(",")
        if v.strip()
    ]
    if "gen_ai_latest_experimental" not in optins:
        optins.append("gen_ai_latest_experimental")
    os.environ["OTEL_SEMCONV_STABILITY_OPT_IN"] = ",".join(optins)

    # Prompt/completion capture is PII-sensitive and off by default; only export
    # it when the app explicitly opts in. ``setdefault`` respects external config.
    if settings.OTEL_GENAI_CAPTURE_MESSAGE_CONTENT != "off":
        os.environ.setdefault(
            "OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT",
            settings.OTEL_GENAI_CAPTURE_MESSAGE_CONTENT,
        )


def configure_telemetry() -> None:
    """Configure OpenTelemetry tracing and metrics with OTLP exporters."""
    _configure_genai_env()

    resource = Resource.create(
        {
            "service.name": settings.OTEL_SERVICE_NAME or settings.PROJECT_NAME,
            "service.version": "0.1.0",
            # `deployment.environment` was deprecated in favour of
            # `deployment.environment.name` in the deployment semconv.
            "deployment.environment.name": settings.PROJECT_ENV,
        }
    )

    # --- Traces ---
    provider = TracerProvider(resource=resource)
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

    # --- Metrics (required for the GenAI gen_ai.client.* histograms) ---
    metric_readers: list[MetricReader] = []
    if settings.OTEL_EXPORTER_OTLP_ENDPOINT:
        metric_readers.append(
            PeriodicExportingMetricReader(
                OTLPMetricExporter(
                    endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT,
                    insecure=settings.PROJECT_ENV != "prod",
                )
            )
        )
    elif settings.PROJECT_ENV == "local":
        metric_readers.append(PeriodicExportingMetricReader(ConsoleMetricExporter()))
    metrics.set_meter_provider(
        MeterProvider(resource=resource, metric_readers=metric_readers)
    )

    # --- Logs (carries GenAI content events in event_only / span_and_event
    # capture modes; the official SDK instrumentors emit them via the logs API).
    # Exported only when an OTLP endpoint is set — locally, structlog already
    # writes app logs to stdout, so we avoid duplicating them here.
    logger_provider = LoggerProvider(resource=resource)
    if settings.OTEL_EXPORTER_OTLP_ENDPOINT:
        logger_provider.add_log_record_processor(
            BatchLogRecordProcessor(
                OTLPLogExporter(
                    endpoint=settings.OTEL_EXPORTER_OTLP_ENDPOINT,
                    insecure=settings.PROJECT_ENV != "prod",
                )
            )
        )
    set_logger_provider(logger_provider)

    # Build GenAI metric instruments against the configured meter provider.
    from src.lib.ai.telemetry import init_genai_metrics

    init_genai_metrics()


def instrument_app(app: FastAPI) -> None:
    """Instrument FastAPI and other libraries for tracing."""
    from src.lib.ai.telemetry import instrument_genai_sdks
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

    # Auto-instrument official GenAI SDKs (no-op when their packages are absent)
    instrument_genai_sdks()


def get_tracer(name: str = __name__) -> trace.Tracer:
    """Get a tracer instance for manual instrumentation."""
    return trace.get_tracer(name)


def get_meter(name: str = __name__) -> metrics.Meter:
    """Get a meter instance for manual metric instrumentation."""
    return metrics.get_meter(name)
