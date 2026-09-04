"""Configuration normalization tests."""

from src.lib.config import Settings


def test_redis_url_is_derived_from_cloud_environment() -> None:
    settings = Settings(
        REDIS_HOST="cache.internal",
        REDIS_PORT=6380,
        REDIS_TLS=True,
        REDIS_PASSWORD="password with:/symbols",  # noqa: S106
    )

    assert settings.REDIS_URL == (
        "rediss://:password%20with%3A%2Fsymbols@cache.internal:6380"
    )


def test_explicit_redis_url_takes_precedence() -> None:
    settings = Settings(
        REDIS_URL="redis://explicit.internal:6379",
        REDIS_HOST="ignored.internal",
    )

    assert settings.REDIS_URL == "redis://explicit.internal:6379"


def test_android_certificate_fingerprint_adds_native_webauthn_origin() -> None:
    settings = Settings(
        WEBAUTHN_ORIGINS=["https://example.com"],
        WEBAUTHN_ANDROID_SHA256_CERT_FINGERPRINTS=[
            "00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:"
            "00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF"
        ],
    )

    assert settings.WEBAUTHN_ORIGINS == [
        "https://example.com",
        "android:apk-key-hash:ABEiM0RVZneImaq7zN3u_wARIjNEVWZ3iJmqu8zd7v8",
    ]


def test_invalid_android_certificate_fingerprint_is_rejected() -> None:
    try:
        Settings(WEBAUTHN_ANDROID_SHA256_CERT_FINGERPRINTS=["not-a-fingerprint"])
    except ValueError as error:
        assert "Invalid Android SHA-256 certificate fingerprint" in str(error)
    else:
        raise AssertionError("Expected invalid fingerprint to be rejected")
