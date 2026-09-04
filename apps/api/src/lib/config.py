import base64
from functools import lru_cache
from typing import Literal
from urllib.parse import quote

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    # Project
    PROJECT_NAME: str = "fullstack-starter-api"
    PROJECT_ENV: Literal["local", "staging", "prod"] = "local"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/app"
    DATABASE_URL_SYNC: str = "postgresql://postgres:postgres@localhost:5432/app"

    # CORS
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]

    # Request limits (edge WAFs cannot enforce body size; the app does)
    MAX_BODY_SIZE: int = 1_048_576  # 1 MiB

    # OAuth 2.0 / OpenID Connect (Authorization Code + PKCE)
    API_PUBLIC_URL: str = "http://localhost:8000"
    OAUTH_ALLOWED_WEB_ORIGINS: list[str] = ["http://localhost:3000"]
    OAUTH_ALLOWED_MOBILE_REDIRECT_URIS: list[str] = ["fullstackstarter://auth/callback"]
    GOOGLE_CLIENT_ID: str | None = None
    GOOGLE_CLIENT_SECRET: str | None = None
    GITHUB_CLIENT_ID: str | None = None
    GITHUB_CLIENT_SECRET: str | None = None
    FACEBOOK_CLIENT_ID: str | None = None
    FACEBOOK_CLIENT_SECRET: str | None = None

    # WebAuthn / passkeys
    WEBAUTHN_RP_ID: str = "localhost"
    WEBAUTHN_RP_NAME: str = "Fullstack Starter"
    WEBAUTHN_ORIGINS: list[str] = ["http://localhost:3000"]
    WEBAUTHN_ANDROID_SHA256_CERT_FINGERPRINTS: list[str] = []

    @model_validator(mode="after")
    def add_android_webauthn_origins(self) -> "Settings":
        """Allow native Android origins derived from trusted signing certs."""
        for fingerprint in self.WEBAUTHN_ANDROID_SHA256_CERT_FINGERPRINTS:
            try:
                digest = bytes.fromhex(fingerprint.replace(":", ""))
            except ValueError as exc:
                raise ValueError(
                    "Invalid Android SHA-256 certificate fingerprint"
                ) from exc
            if len(digest) != 32:
                raise ValueError("Android certificate fingerprint must be SHA-256")
            encoded = base64.urlsafe_b64encode(digest).decode().rstrip("=")
            origin = f"android:apk-key-hash:{encoded}"
            if origin not in self.WEBAUTHN_ORIGINS:
                self.WEBAUTHN_ORIGINS.append(origin)
        return self

    # JWT/JWE (stateless authentication)
    JWT_SECRET: str = "your-super-secret-jwt-key-change-in-production"  # noqa: S105
    JWE_SECRET_KEY: str = "your-super-secret-jwe-encryption-key-change-in-production"  # noqa: S105

    # Redis (optional)
    REDIS_URL: str | None = None
    REDIS_HOST: str | None = None
    REDIS_PORT: int = 6379
    REDIS_TLS: bool = False
    REDIS_PASSWORD: str | None = None

    @model_validator(mode="after")
    def derive_redis_url(self) -> "Settings":
        """Build REDIS_URL from cloud-provider host settings when needed."""
        if self.REDIS_URL or not self.REDIS_HOST:
            return self
        scheme = "rediss" if self.REDIS_TLS else "redis"
        auth = f":{quote(self.REDIS_PASSWORD, safe='')}@" if self.REDIS_PASSWORD else ""
        self.REDIS_URL = f"{scheme}://{auth}{self.REDIS_HOST}:{self.REDIS_PORT}"
        return self

    # Trusted reverse-proxy CIDRs whose X-Forwarded-For header is honoured.
    # Example: ["10.0.0.0/8", "172.16.0.0/12"]
    TRUSTED_PROXY_IPS: list[str] = []

    # OpenTelemetry (optional)
    OTEL_EXPORTER_OTLP_ENDPOINT: str | None = None
    OTEL_SERVICE_NAME: str | None = None

    # OpenTelemetry GenAI (LLM observability via OTel GenAI semconv).
    # Prompt/completion content is PII-sensitive; "off" records only metadata
    # (model, token usage, durations). Other modes record message content.
    OTEL_GENAI_CAPTURE_MESSAGE_CONTENT: Literal[
        "off", "span_only", "event_only", "span_and_event"
    ] = "off"

    # AI (optional)
    AI_PROVIDER: Literal["gemini", "openai"] = "gemini"
    GOOGLE_CLOUD_PROJECT: str | None = None
    GEMINI_API_KEY: str | None = None
    OPENAI_API_KEY: str | None = None

    # Storage (optional)
    STORAGE_BACKEND: Literal["gcs", "s3", "minio", "azure"] = "minio"
    GCS_BUCKET_NAME: str | None = None
    MINIO_ENDPOINT: str = "localhost:9000"
    MINIO_ACCESS_KEY: str = "minioadmin"
    MINIO_SECRET_KEY: str = "minioadmin"  # noqa: S105

    # Azure Blob Storage (used when STORAGE_BACKEND="azure").
    # Auth resolves in order: connection string > account name + key (shared
    # key) > account name + managed/workload identity (DefaultAzureCredential).
    AZURE_STORAGE_CONNECTION_STRING: str | None = None
    AZURE_STORAGE_ACCOUNT_NAME: str | None = None
    AZURE_STORAGE_ACCOUNT_KEY: str | None = None
    AZURE_STORAGE_CONTAINER: str | None = None
    # Override for sovereign clouds (e.g. core.chinacloudapi.cn).
    AZURE_STORAGE_ENDPOINT_SUFFIX: str = "core.windows.net"


@lru_cache
def get_settings() -> Settings:
    """Cached settings instance."""
    return Settings()


settings = get_settings()
