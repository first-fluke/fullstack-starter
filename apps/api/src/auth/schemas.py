"""Authentication API schemas."""

from typing import Any, Literal

from pydantic import BaseModel, Field

OAuthProvider = Literal["google", "github", "facebook"]


class OAuthExchangeRequest(BaseModel):
    """Exchange a one-time OAuth login code for first-party tokens."""

    code: str = Field(min_length=32, max_length=256)
    code_verifier: str | None = Field(default=None, min_length=43, max_length=128)


class PasskeyRegistrationVerifyRequest(BaseModel):
    """Complete an authenticated passkey registration ceremony."""

    ceremony_id: str = Field(min_length=32, max_length=256)
    credential: dict[str, Any]


class PasskeyAuthenticationOptionsRequest(BaseModel):
    """Start a passkey authentication ceremony."""

    email: str = Field(min_length=3, max_length=255)


class PasskeyAuthenticationVerifyRequest(BaseModel):
    """Complete a passkey authentication ceremony."""

    ceremony_id: str = Field(min_length=32, max_length=256)
    credential: dict[str, Any]
