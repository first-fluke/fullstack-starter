from collections.abc import Iterator

from fastapi import FastAPI, Request
from fastapi.testclient import TestClient

from src.lib.body_limit import BodySizeLimitMiddleware
from src.lib.config import settings

OVERSIZE = settings.MAX_BODY_SIZE + 1


def test_oversized_body_rejected(client: TestClient) -> None:
    response = client.post("/health", content=b"x" * OVERSIZE)
    assert response.status_code == 413
    assert response.json()["error"] == "request_entity_too_large"


def test_small_body_passes_through(client: TestClient) -> None:
    # /health only allows GET, so reaching 405 proves the middleware let
    # the request through to the router
    response = client.post("/health", content=b"x" * 1024)
    assert response.status_code == 405


def _echo_app(max_body_size: int) -> FastAPI:
    """Minimal app whose endpoint consumes the body (required to exercise
    the streaming/chunked path — body bytes are only counted when read)."""
    app = FastAPI()
    app.add_middleware(BodySizeLimitMiddleware, max_body_size=max_body_size)

    @app.post("/echo")
    async def echo(request: Request) -> dict[str, int]:
        body = await request.body()
        return {"size": len(body)}

    return app


def test_oversized_chunked_body_rejected() -> None:
    def chunks() -> Iterator[bytes]:
        for _ in range(8):
            yield b"x" * 256

    with TestClient(_echo_app(max_body_size=1024)) as client:
        response = client.post("/echo", content=chunks())
    assert response.status_code == 413
    assert response.json()["error"] == "request_entity_too_large"


def test_chunked_body_within_limit_passes() -> None:
    def chunks() -> Iterator[bytes]:
        for _ in range(4):
            yield b"x" * 256

    with TestClient(_echo_app(max_body_size=1024)) as client:
        response = client.post("/echo", content=chunks())
    assert response.status_code == 200
    assert response.json() == {"size": 1024}
