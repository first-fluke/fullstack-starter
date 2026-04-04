from fastapi.testclient import TestClient


def test_register_returns_backend_tokens(client: TestClient) -> None:
    response = client.post(
        "/api/auth/register",
        json={
            "email": "grace@example.com",
            "password": "supersecret123",
            "name": "Grace",
        },
    )

    assert response.status_code == 201
    data = response.json()
    assert data["access_token"]
    assert data["refresh_token"]
    assert data["token_type"] == "bearer"  # noqa: S105


def test_email_login_and_me_flow(client: TestClient) -> None:
    register_response = client.post(
        "/api/auth/register",
        json={
            "email": "grace@example.com",
            "password": "supersecret123",
            "name": "Grace",
        },
    )
    access_token = register_response.json()["access_token"]

    me_response = client.get(
        "/api/auth/me",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert me_response.status_code == 200
    assert me_response.json()["email"] == "grace@example.com"

    login_response = client.post(
        "/api/auth/login",
        json={
            "email": "grace@example.com",
            "password": "supersecret123",
        },
    )

    assert login_response.status_code == 200
    assert login_response.json()["access_token"]
    assert login_response.json()["refresh_token"]


def test_duplicate_email_registration_is_rejected(client: TestClient) -> None:
    payload = {
        "email": "grace@example.com",
        "password": "supersecret123",
        "name": "Grace",
    }

    first_response = client.post("/api/auth/register", json=payload)
    second_response = client.post("/api/auth/register", json=payload)

    assert first_response.status_code == 201
    assert second_response.status_code == 409
    assert second_response.json()["detail"] == "Email already registered"
