from functools import lru_cache
from typing import Literal

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",
    )

    PROJECT_NAME: str = "fullstack-starter"
    PROJECT_ENV: Literal["local", "staging", "prod"] = "local"

    GOOGLE_CLOUD_PROJECT: str | None = None
    CLOUD_TASKS_QUEUE: str = "default"
    CLOUD_TASKS_LOCATION: str = "asia-northeast3"

    WORKER_VERIFY_OIDC: bool = False
    WORKER_OIDC_AUDIENCE: str | None = None

    @model_validator(mode="after")
    def _require_audience_when_verify_enabled(self) -> "Settings":
        """Fail closed: audience must be set when OIDC verification is enabled.

        google-auth skips audience verification when ``audience=None``, which
        would silently accept tokens issued for any service.  Reject the
        configuration before any request is ever handled.
        """
        if self.WORKER_VERIFY_OIDC and not self.WORKER_OIDC_AUDIENCE:
            raise ValueError(
                "WORKER_OIDC_AUDIENCE must be set when WORKER_VERIFY_OIDC is True. "
                "Leaving audience empty causes google-auth to skip audience "
                "verification, accepting tokens for any service."
            )
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
