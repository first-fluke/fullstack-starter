"""Application routes must be bound to native Litestar controllers."""

from litestar import Controller
from litestar.routes import HTTPRoute

from src.lib.config import Settings
from src.main import create_app


def test_application_routes_are_bound_to_controllers() -> None:
    app = create_app(Settings(WORKER_SCHEDULES_FILE=None))
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


def test_health_openapi_keeps_its_operation_id() -> None:
    app = create_app(Settings(WORKER_SCHEDULES_FILE=None))
    operation = app.openapi_schema.to_schema()["paths"]["/health"]["get"]
    assert operation["operationId"] == "HealthHealthCheck"
    assert operation["tags"] == ["Health"]
    assert operation.get("parameters", []) == []
