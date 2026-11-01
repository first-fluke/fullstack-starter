"""Authentication API schemas."""

from typing import Annotated, Any, Literal

import msgspec
from msgspec import Meta

OAuthProvider = Literal["google", "github", "facebook"]


class OAuthExchangeRequest(msgspec.Struct):
    """Exchange a one-time OAuth login code for first-party tokens."""

    code: Annotated[str, Meta(min_length=32, max_length=256)]
    code_verifier: Annotated[str, Meta(min_length=43, max_length=128)] | None = None


class PasskeyRegistrationVerifyRequest(msgspec.Struct):
    """Complete an authenticated passkey registration ceremony."""

    ceremony_id: Annotated[str, Meta(min_length=32, max_length=256)]
    credential: dict[str, Any]


class PasskeyAuthenticationOptionsRequest(msgspec.Struct):
    """Start a passkey authentication ceremony."""

    email: Annotated[str, Meta(min_length=3, max_length=255)]


class PasskeyAuthenticationVerifyRequest(msgspec.Struct):
    """Complete a passkey authentication ceremony."""

    ceremony_id: Annotated[str, Meta(min_length=32, max_length=256)]
    credential: dict[str, Any]
