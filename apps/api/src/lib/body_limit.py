"""Request body size limit middleware.

Edge WAFs cannot enforce payload size limits (AWS WAF on ALB inspects only
the first 8 KB; Cloud Armor likewise), so the API enforces the real maximum
request body size here.
"""

import json

from starlette.types import ASGIApp, Message, Receive, Scope, Send


class _BodyTooLargeError(Exception):
    """Raised by the wrapped receive when the streamed body exceeds the limit."""


class BodySizeLimitMiddleware:
    """Reject requests whose body exceeds ``max_body_size`` with HTTP 413.

    Requests with a Content-Length header are rejected up front; chunked
    requests are counted as they stream and aborted once over the limit.
    """

    def __init__(self, app: ASGIApp, max_body_size: int) -> None:
        self.app = app
        self.max_body_size = max_body_size

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        content_length = self._content_length(scope)
        if content_length is not None and content_length > self.max_body_size:
            await self._send_413(send)
            return

        response_started = False
        received_bytes = 0

        async def wrapped_send(message: Message) -> None:
            nonlocal response_started
            if message["type"] == "http.response.start":
                response_started = True
            await send(message)

        async def wrapped_receive() -> Message:
            nonlocal received_bytes
            message = await receive()
            if message["type"] == "http.request":
                received_bytes += len(message.get("body", b""))
                if received_bytes > self.max_body_size:
                    raise _BodyTooLargeError
            return message

        try:
            await self.app(scope, wrapped_receive, wrapped_send)
        except _BodyTooLargeError:
            if not response_started:
                await self._send_413(send)

    @staticmethod
    def _content_length(scope: Scope) -> int | None:
        for name, value in scope.get("headers", []):
            if name == b"content-length":
                try:
                    return int(value)
                except ValueError:
                    return None
        return None

    async def _send_413(self, send: Send) -> None:
        body = json.dumps(
            {
                "error": "request_entity_too_large",
                "message": f"Request body must not exceed {self.max_body_size} bytes",
            }
        ).encode()
        await send(
            {
                "type": "http.response.start",
                "status": 413,
                "headers": [
                    (b"content-type", b"application/json"),
                    (b"content-length", str(len(body)).encode()),
                ],
            }
        )
        await send({"type": "http.response.body", "body": body})
