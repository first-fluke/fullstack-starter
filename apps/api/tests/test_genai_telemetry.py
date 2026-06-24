"""Tests for the OTel GenAI semantic-convention instrumentation helper."""

from collections.abc import Iterator

import pytest
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import (
    HistogramDataPoint,
    InMemoryMetricReader,
)
from opentelemetry.sdk.trace import ReadableSpan, TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry.sdk.trace.export.in_memory_span_exporter import (
    InMemorySpanExporter,
)
from opentelemetry.trace import StatusCode, Tracer

from src.lib.ai import telemetry as gen
from src.lib.ai.telemetry import (
    GenAIAttr,
    GenAIOperation,
    GenAIProvider,
    genai_span,
    init_genai_metrics,
    provider_name,
)


class _Tracing:
    def __init__(self, tracer: Tracer, exporter: InMemorySpanExporter) -> None:
        self.tracer = tracer
        self.exporter = exporter


@pytest.fixture
def tracing() -> Iterator[_Tracing]:
    """Local in-memory tracer, isolated from the global provider."""
    provider = TracerProvider()
    span_exporter = InMemorySpanExporter()
    provider.add_span_processor(SimpleSpanProcessor(span_exporter))
    yield _Tracing(provider.get_tracer("test"), span_exporter)


@pytest.fixture
def metric_reader() -> Iterator[InMemoryMetricReader]:
    """Local in-memory meter wired into the module's metric instruments."""
    reader = InMemoryMetricReader()
    provider = MeterProvider(metric_readers=[reader])
    init_genai_metrics(provider.get_meter("test"))
    yield reader
    gen._token_usage_histogram = None
    gen._operation_duration_histogram = None


def _histogram_points(
    reader: InMemoryMetricReader, name: str
) -> list[HistogramDataPoint]:
    data = reader.get_metrics_data()
    points: list[HistogramDataPoint] = []
    for resource_metric in data.resource_metrics:
        for scope_metric in resource_metric.scope_metrics:
            for metric in scope_metric.metrics:
                if metric.name == name:
                    points.extend(metric.data.data_points)
    return points


def test_span_name_and_required_attributes(
    tracing: _Tracing, metric_reader: InMemoryMetricReader
) -> None:
    with genai_span(
        operation=GenAIOperation.CHAT,
        provider=provider_name("openai"),
        request_model="gpt-4o",
        temperature=0.2,
        max_tokens=512,
        tracer=tracing.tracer,
    ) as call:
        call.set_response(
            model="gpt-4o-2024-08-06",
            response_id="chatcmpl-123",
            finish_reasons=["stop"],
            input_tokens=42,
            output_tokens=18,
        )

    (span,) = tracing.exporter.get_finished_spans()
    assert isinstance(span, ReadableSpan)
    assert span.name == "chat gpt-4o"
    attrs = span.attributes or {}
    assert attrs[GenAIAttr.OPERATION_NAME] == "chat"
    assert attrs[GenAIAttr.PROVIDER_NAME] == GenAIProvider.OPENAI
    assert attrs[GenAIAttr.REQUEST_MODEL] == "gpt-4o"
    assert attrs[GenAIAttr.RESPONSE_MODEL] == "gpt-4o-2024-08-06"
    assert attrs[GenAIAttr.RESPONSE_ID] == "chatcmpl-123"
    assert attrs[GenAIAttr.RESPONSE_FINISH_REASONS] == ("stop",)
    assert attrs[GenAIAttr.USAGE_INPUT_TOKENS] == 42
    assert attrs[GenAIAttr.USAGE_OUTPUT_TOKENS] == 18
    assert attrs[GenAIAttr.REQUEST_TEMPERATURE] == 0.2
    assert attrs[GenAIAttr.REQUEST_MAX_TOKENS] == 512


def test_token_usage_and_duration_metrics(
    tracing: _Tracing, metric_reader: InMemoryMetricReader
) -> None:
    with genai_span(
        operation=GenAIOperation.CHAT,
        provider=provider_name("gemini"),
        request_model="gemini-2.5-flash",
        tracer=tracing.tracer,
    ) as call:
        call.set_response(input_tokens=100, output_tokens=50)

    token_points = _histogram_points(metric_reader, "gen_ai.client.token.usage")
    by_type = {p.attributes[GenAIAttr.TOKEN_TYPE]: p for p in token_points}
    assert by_type["input"].sum == 100
    assert by_type["output"].sum == 50
    assert by_type["input"].attributes[GenAIAttr.PROVIDER_NAME] == "gcp.gemini"

    duration_points = _histogram_points(
        metric_reader, "gen_ai.client.operation.duration"
    )
    assert len(duration_points) == 1
    assert duration_points[0].count == 1
    assert duration_points[0].attributes[GenAIAttr.OPERATION_NAME] == "chat"


def test_content_not_captured_by_default(
    tracing: _Tracing,
    metric_reader: InMemoryMetricReader,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.delenv(
        "OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT", raising=False
    )
    with genai_span(
        operation=GenAIOperation.CHAT,
        provider=provider_name("openai"),
        request_model="gpt-4o",
        tracer=tracing.tracer,
    ) as call:
        call.record_input_messages([{"role": "user", "parts": [{"type": "text"}]}])

    (span,) = tracing.exporter.get_finished_spans()
    assert GenAIAttr.INPUT_MESSAGES not in (span.attributes or {})


def test_content_captured_when_enabled(
    tracing: _Tracing,
    metric_reader: InMemoryMetricReader,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv(
        "OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT", "span_only"
    )
    with genai_span(
        operation=GenAIOperation.CHAT,
        provider=provider_name("openai"),
        request_model="gpt-4o",
        tracer=tracing.tracer,
    ) as call:
        call.record_input_messages([{"role": "user", "content": "hi"}])

    (span,) = tracing.exporter.get_finished_spans()
    assert GenAIAttr.INPUT_MESSAGES in (span.attributes or {})


def test_error_sets_error_type_on_span_and_metric(
    tracing: _Tracing, metric_reader: InMemoryMetricReader
) -> None:
    with (
        pytest.raises(ValueError, match="boom"),
        genai_span(
            operation=GenAIOperation.CHAT,
            provider=provider_name("openai"),
            request_model="gpt-4o",
            tracer=tracing.tracer,
        ),
    ):
        raise ValueError("boom")

    (span,) = tracing.exporter.get_finished_spans()
    attrs = span.attributes or {}
    assert attrs[GenAIAttr.ERROR_TYPE] == "ValueError"
    assert span.status.status_code == StatusCode.ERROR

    duration_points = _histogram_points(
        metric_reader, "gen_ai.client.operation.duration"
    )
    assert duration_points[0].attributes[GenAIAttr.ERROR_TYPE] == "ValueError"


def test_provider_name_mapping() -> None:
    assert provider_name("openai") == "openai"
    assert provider_name("gemini") == "gcp.gemini"
    assert provider_name("unknown") == "unknown"
