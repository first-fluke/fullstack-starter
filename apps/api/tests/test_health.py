from fastapi.testclient import TestClient


def test_health_check(client: TestClient) -> None:
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] in ["healthy", "degraded", "unhealthy"]
    assert "version" in data
    assert "services" in data
    assert "database" in data["services"]


def test_liveness_check(client: TestClient) -> None:
    response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_check(client: TestClient) -> None:
    response = client.get("/health/ready")
    # May return 200 or 503 depending on DB state
    assert response.status_code in [200, 503]
