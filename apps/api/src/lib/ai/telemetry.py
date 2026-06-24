"""OpenTelemetry GenAI semantic-convention instrumentation.

Implements the OpenTelemetry **GenAI semantic conventions** as of 2026-Q2. The
spec is still in ``Development`` status and now lives in its own repository:
https://github.com/open-telemetry/semantic-conventions-genai

Two complementary layers are provided:

1. ``instrument_genai_sdks()`` — zero-code auto-instrumentation for the official
   OpenAI and Google GenAI SDKs. Guarded by import checks, so it is a no-op when
   the SDK or its instrumentor is not installed. Wired from
   ``src.lib.telemetry.instrument_app``.

2. ``genai_span()`` — a manual context manager for custom ``AIProvider``
   implementations that do not go through an official SDK. It emits a
   spec-compliant inference span plus the ``gen_ai.client.*`` metrics.

Message content (prompts/completions) is **never** captured by default because
it routinely contains user PII. Enable it explicitly via
``OTEL_GENAI_CAPTURE_MESSAGE_CONTENT`` (see ``src.lib.config``), which maps to the
upstream ``OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT`` env var. The
manual ``genai_span()`` helper records content as **span attributes** (``true`` /
``span_only`` / ``span_and_event`` modes); ``event_only`` content events are
emitted only by the official SDK auto-instrumentation via the logs pipeline
configured in ``src.lib.telemetry``.

Example (manual instrumentation inside a custom provider)::

    from src.lib.ai.telemetry import GenAIOperation, genai_span, provider_name

    with genai_span(
        operation=GenAIOperation.CHAT,
        provider=provider_name("openai"),
        request_model="gpt-4o",
        temperature=0.2,
    ) as call:
        completion = await client.chat.completions.create(...)
        call.set_response(
            model=completion.model,
            response_id=completion.id,
            finish_reasons=[c.finish_reason for c in completion.choices],
            input_tokens=completion.usage.prompt_tokens,
            output_tokens=completion.usage.completion_tokens,
        )
"""

from __future__ import annotations

import json
import logging
import os
import time
from collections.abc import Iterator, Mapping, Sequence
from contextlib import contextmanager
from typing import Any, Final

from opentelemetry import metrics, trace
from opentelemetry.metrics import Histogram, Meter
from opentelemetry.trace import Span, Status, StatusCode, Tracer
from opentelemetry.util.types import AttributeValue

logger = logging.getLogger(__name__)

_INSTRUMENTATION_NAME: Final = "src.lib.ai.telemetry"


# ---------------------------------------------------------------------------
# Semantic-convention attribute names (GenAI semconv, 2026-Q2 / latest experimental).
# Defined as literals rather than importing the incubating semconv module, which
# is unstable and may relocate between releases.
# ---------------------------------------------------------------------------
class GenAIAttr:
    """``gen_ai.*`` span/metric attribute keys."""

    OPERATION_NAME: Final = "gen_ai.operation.name"
    PROVIDER_NAME: Final = "gen_ai.provider.name"  # replaces gen_ai.system
    CONVERSATION_ID: Final = "gen_ai.conversation.id"
    OUTPUT_TYPE: Final = "gen_ai.output.type"

    REQUEST_MODEL: Final = "gen_ai.request.model"
    REQUEST_TEMPERATURE: Final = "gen_ai.request.temperature"
    REQUEST_MAX_TOKENS: Final = "gen_ai.request.max_tokens"
    REQUEST_TOP_P: Final = "gen_ai.request.top_p"

    RESPONSE_MODEL: Final = "gen_ai.response.model"
    RESPONSE_ID: Final = "gen_ai.response.id"
    RESPONSE_FINISH_REASONS: Final = "gen_ai.response.finish_reasons"

    USAGE_INPUT_TOKENS: Final = "gen_ai.usage.input_tokens"
    USAGE_OUTPUT_TOKENS: Final = "gen_ai.usage.output_tokens"
    # metric dimension: "input" | "output"
    TOKEN_TYPE: Final = "gen_ai.token.type"  # noqa: S105

    # Opt-in, sensitive (captured only when content recording is enabled).
    INPUT_MESSAGES: Final = "gen_ai.input.messages"
    OUTPUT_MESSAGES: Final = "gen_ai.output.messages"
    SYSTEM_INSTRUCTIONS: Final = "gen_ai.system_instructions"

    # Shared (non gen_ai.*) attributes.
    SERVER_ADDRESS: Final = "server.address"
    SERVER_PORT: Final = "server.port"
    ERROR_TYPE: Final = "error.type"


class GenAIOperation:
    """Allowed values for ``gen_ai.operation.name``."""

    CHAT: Final = "chat"
    GENERATE_CONTENT: Final = "generate_content"
    TEXT_COMPLETION: Final = "text_completion"
    EMBEDDINGS: Final = "embeddings"
    EXECUTE_TOOL: Final = "execute_tool"
    CREATE_AGENT: Final = "create_agent"
    INVOKE_AGENT: Final = "invoke_agent"


class GenAIProvider:
    """Common ``gen_ai.provider.name`` discriminator values."""

    OPENAI: Final = "openai"
    GCP_GEMINI: Final = "gcp.gemini"  # Gemini Developer API
    GCP_VERTEX_AI: Final = "gcp.vertex_ai"
    ANTHROPIC: Final = "anthropic"
    AWS_BEDROCK: Final = "aws.bedrock"
    AZURE_AI_OPENAI: Final = "azure.ai.openai"


# Maps this project's ``AI_PROVIDER`` setting to the semconv provider name.
_PROVIDER_NAME_MAP: Final[dict[str, str]] = {
    "openai": GenAIProvider.OPENAI,
    "gemini": GenAIProvider.GCP_GEMINI,
}


# Advisory histogram bucket boundaries from the GenAI metrics semconv.
_TOKEN_USAGE_BUCKETS: Final[list[float]] = [
    1,
    4,
    16,
    64,
    256,
    1024,
    4096,
    16384,
    65536,
    262144,
    1048576,
    4194304,
    16777216,
    67108864,
]
_OPERATION_DURATION_BUCKETS: Final[list[float]] = [
    0.01,
    0.02,
    0.04,
    0.08,
    0.16,
    0.32,
    0.64,
    1.28,
    2.56,
    5.12,
    10.24,
    20.48,
    40.96,
    81.92,
]


def provider_name(ai_provider: str) -> str:
    """Map an ``AI_PROVIDER`` setting value to a ``gen_ai.provider.name`` value."""
    return _PROVIDER_NAME_MAP.get(ai_provider, ai_provider)


# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------
_token_usage_histogram: Histogram | None = None
_operation_duration_histogram: Histogram | None = None


def init_genai_metrics(meter: Meter | None = None) -> None:
    """Create the GenAI client metric instruments.

    Call once after the global ``MeterProvider`` is configured. Passing an
    explicit ``meter`` is intended for tests; production uses the global meter.
    """
    global _token_usage_histogram, _operation_duration_histogram

    meter = meter or metrics.get_meter(_INSTRUMENTATION_NAME)
    _token_usage_histogram = meter.create_histogram(
        name="gen_ai.client.token.usage",
        unit="{token}",
        description="Number of input and output tokens used by GenAI requests.",
        explicit_bucket_boundaries_advisory=_TOKEN_USAGE_BUCKETS,
    )
    _operation_duration_histogram = meter.create_histogram(
        name="gen_ai.client.operation.duration",
        unit="s",
        description="Duration of GenAI client operations.",
        explicit_bucket_boundaries_advisory=_OPERATION_DURATION_BUCKETS,
    )


# ---------------------------------------------------------------------------
# Content-capture gating (PII-sensitive opt-in)
# ---------------------------------------------------------------------------
_SPAN_CAPTURE_MODES: Final = frozenset({"true", "span_only", "span_and_event"})


def _capture_content_on_span() -> bool:
    """Whether prompt/completion content may be recorded as span attributes."""
    mode = os.environ.get(
        "OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT", "off"
    ).lower()
    return mode in _SPAN_CAPTURE_MODES


def _json_attr(value: Any) -> str:
    """Serialize structured message content for an attribute value."""
    return json.dumps(value, ensure_ascii=False, default=str)


# ---------------------------------------------------------------------------
# Manual instrumentation: genai_span context manager
# ---------------------------------------------------------------------------
class GenAISpanHandle:
    """Mutable handle used to enrich an in-flight GenAI span and its metrics."""

    def __init__(self, span: Span, metric_attrs: dict[str, AttributeValue]) -> None:
        self._span = span
        self._metric_attrs = metric_attrs
        self.input_tokens: int | None = None
        self.output_tokens: int | None = None

    @property
    def span(self) -> Span:
        return self._span

    def set_response(
        self,
        *,
        model: str | None = None,
        response_id: str | None = None,
        finish_reasons: Sequence[str] | None = None,
        input_tokens: int | None = None,
        output_tokens: int | None = None,
    ) -> None:
        """Record response-side attributes (model, id, finish reasons, usage)."""
        if model is not None:
            self._span.set_attribute(GenAIAttr.RESPONSE_MODEL, model)
            self._metric_attrs[GenAIAttr.RESPONSE_MODEL] = model
        if response_id is not None:
            self._span.set_attribute(GenAIAttr.RESPONSE_ID, response_id)
        if finish_reasons:
            self._span.set_attribute(
                GenAIAttr.RESPONSE_FINISH_REASONS, list(finish_reasons)
            )
        if input_tokens is not None:
            self._span.set_attribute(GenAIAttr.USAGE_INPUT_TOKENS, input_tokens)
            self.input_tokens = input_tokens
        if output_tokens is not None:
            self._span.set_attribute(GenAIAttr.USAGE_OUTPUT_TOKENS, output_tokens)
            self.output_tokens = output_tokens

    def record_input_messages(self, messages: Any) -> None:
        """Record input chat history (opt-in; PII-sensitive)."""
        if _capture_content_on_span():
            self._span.set_attribute(GenAIAttr.INPUT_MESSAGES, _json_attr(messages))

    def record_output_messages(self, messages: Any) -> None:
        """Record model output messages (opt-in; PII-sensitive)."""
        if _capture_content_on_span():
            self._span.set_attribute(GenAIAttr.OUTPUT_MESSAGES, _json_attr(messages))

    def record_system_instructions(self, instructions: Any) -> None:
        """Record system instructions (opt-in; PII-sensitive)."""
        if _capture_content_on_span():
            self._span.set_attribute(
                GenAIAttr.SYSTEM_INSTRUCTIONS, _json_attr(instructions)
            )


@contextmanager
def genai_span(
    *,
    operation: str,
    provider: str,
    request_model: str,
    temperature: float | None = None,
    max_tokens: int | None = None,
    top_p: float | None = None,
    server_address: str | None = None,
    server_port: int | None = None,
    conversation_id: str | None = None,
    tracer: Tracer | None = None,
) -> Iterator[GenAISpanHandle]:
    """Open a GenAI inference span following the OTel GenAI semantic conventions.

    The span is named ``{operation} {request_model}`` and carries the required
    ``gen_ai.operation.name`` / ``gen_ai.provider.name`` attributes. On exit the
    ``gen_ai.client.operation.duration`` and ``gen_ai.client.token.usage`` metrics
    are recorded. Exceptions set ``error.type`` on both the span and the metrics.
    """
    tracer = tracer or trace.get_tracer(_INSTRUMENTATION_NAME)
    span_name = f"{operation} {request_model}"

    # Attributes shared by the span and the emitted metrics.
    metric_attrs: dict[str, AttributeValue] = {
        GenAIAttr.OPERATION_NAME: operation,
        GenAIAttr.PROVIDER_NAME: provider,
        GenAIAttr.REQUEST_MODEL: request_model,
    }
    if server_address is not None:
        metric_attrs[GenAIAttr.SERVER_ADDRESS] = server_address
    if server_port is not None:
        metric_attrs[GenAIAttr.SERVER_PORT] = server_port

    start = time.perf_counter()
    error_type: str | None = None

    with tracer.start_as_current_span(span_name, kind=trace.SpanKind.CLIENT) as span:
        for key, value in metric_attrs.items():
            span.set_attribute(key, value)
        if temperature is not None:
            span.set_attribute(GenAIAttr.REQUEST_TEMPERATURE, temperature)
        if max_tokens is not None:
            span.set_attribute(GenAIAttr.REQUEST_MAX_TOKENS, max_tokens)
        if top_p is not None:
            span.set_attribute(GenAIAttr.REQUEST_TOP_P, top_p)
        if conversation_id is not None:
            span.set_attribute(GenAIAttr.CONVERSATION_ID, conversation_id)

        handle = GenAISpanHandle(span, metric_attrs)
        try:
            yield handle
        except Exception as exc:
            error_type = type(exc).__qualname__
            span.set_attribute(GenAIAttr.ERROR_TYPE, error_type)
            span.set_status(Status(StatusCode.ERROR, str(exc)))
            span.record_exception(exc)
            raise
        finally:
            _record_metrics(metric_attrs, handle, start, error_type)


def _record_metrics(
    base_attrs: Mapping[str, AttributeValue],
    handle: GenAISpanHandle,
    start: float,
    error_type: str | None,
) -> None:
    duration = time.perf_counter() - start
    duration_attrs: dict[str, AttributeValue] = dict(base_attrs)
    if error_type is not None:
        duration_attrs[GenAIAttr.ERROR_TYPE] = error_type

    if _operation_duration_histogram is not None:
        _operation_duration_histogram.record(duration, attributes=duration_attrs)

    if _token_usage_histogram is not None:
        if handle.input_tokens is not None:
            _token_usage_histogram.record(
                handle.input_tokens,
                attributes={**base_attrs, GenAIAttr.TOKEN_TYPE: "input"},
            )
        if handle.output_tokens is not None:
            _token_usage_histogram.record(
                handle.output_tokens,
                attributes={**base_attrs, GenAIAttr.TOKEN_TYPE: "output"},
            )


# ---------------------------------------------------------------------------
# Auto-instrumentation for the official GenAI SDKs (guarded; optional deps)
# ---------------------------------------------------------------------------
def instrument_genai_sdks() -> None:
    """Enable auto-instrumentation for any installed official GenAI SDK.

    No-op for each SDK whose instrumentor package is not installed. Requires
    ``OTEL_SEMCONV_STABILITY_OPT_IN=gen_ai_latest_experimental`` (set in
    ``src.lib.telemetry``) for the latest experimental conventions.
    """
    _instrument_openai()
    _instrument_google_genai()


def _instrument_openai() -> None:
    try:
        from opentelemetry.instrumentation.openai_v2 import OpenAIInstrumentor
    except ImportError:
        return
    try:
        OpenAIInstrumentor().instrument()
        logger.debug("OpenAI GenAI instrumentation enabled")
    except Exception:  # pragma: no cover - boot must not crash
        logger.warning("Failed to enable OpenAI GenAI instrumentation", exc_info=True)


def _instrument_google_genai() -> None:
    try:
        from opentelemetry.instrumentation.google_genai import (
            GoogleGenAiSdkInstrumentor,
        )
    except ImportError:
        return
    try:
        GoogleGenAiSdkInstrumentor().instrument()
        logger.debug("Google GenAI instrumentation enabled")
    except Exception:  # pragma: no cover - boot must not crash
        logger.warning("Failed to enable Google GenAI instrumentation", exc_info=True)
