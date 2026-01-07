"""Generate OpenAPI schema from FastAPI application."""

import json
from pathlib import Path

from src.main import app


def generate_openapi() -> None:
    """Generate openapi.json from FastAPI app."""
    openapi_schema = app.openapi()
    output_path = Path(__file__).parent.parent / "openapi.json"

    with output_path.open("w", encoding="utf-8") as f:
        json.dump(openapi_schema, f, indent=2, ensure_ascii=False)

    print(f"OpenAPI schema generated: {output_path}")


if __name__ == "__main__":
    generate_openapi()
