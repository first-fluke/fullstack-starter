"""Application routes must be bound to native Litestar controllers."""

from litestar import Controller
from litestar.routes import HTTPRoute

from src.main import app


def test_application_routes_are_bound_to_controllers() -> None:
    handlers = [
        (route.path, handler)
        for route in app.routes
        if isinstance(route, HTTPRoute)
        for handler in route.route_handlers
        if handler.fn.__module__.startswith("src.")
    ]
    assert handlers
    assert [
        path
        for path, handler in handlers
        if not isinstance(getattr(handler.fn, "__self__", None), Controller)
    ] == []
