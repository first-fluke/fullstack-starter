"""WebAuthn passkey registration and authentication services."""

import base64
import json
import secrets
from typing import Any
from uuid import UUID

from fastapi import HTTPException, status
from webauthn import (
    base64url_to_bytes,
    generate_authentication_options,
    generate_registration_options,
    options_to_json,
    verify_authentication_response,
    verify_registration_response,
)
from webauthn.helpers.exceptions import WebAuthnException
from webauthn.helpers.structs import (
    AuthenticatorSelectionCriteria,
    PublicKeyCredentialDescriptor,
    ResidentKeyRequirement,
    UserVerificationRequirement,
)

from src.auth.ephemeral_store import ephemeral_auth_store
from src.auth.repository import AuthRepository
from src.lib.auth import TokenResponse, create_access_token, create_refresh_token
from src.lib.config import settings

_PASSKEY_CHALLENGE_TTL = 300


def _encode_bytes(value: bytes) -> str:
    return base64.urlsafe_b64encode(value).rstrip(b"=").decode()


def _decode_bytes(value: str) -> bytes:
    padding = "=" * (-len(value) % 4)
    return base64.urlsafe_b64decode(value + padding)


def _issue_tokens(user_id: str) -> TokenResponse:
    return TokenResponse(
        access_token=create_access_token(user_id),
        refresh_token=create_refresh_token(user_id),
    )


async def create_registration_options(
    repository: AuthRepository, user_id: str
) -> dict[str, Any]:
    user = await repository.get_user_by_id(user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    existing = await repository.list_passkeys(user.id)
    challenge = secrets.token_bytes(32)
    ceremony_id = secrets.token_urlsafe(32)
    options = generate_registration_options(
        rp_id=settings.WEBAUTHN_RP_ID,
        rp_name=settings.WEBAUTHN_RP_NAME,
        user_id=user.id.bytes,
        user_name=user.email,
        user_display_name=user.name or user.email,
        challenge=challenge,
        exclude_credentials=[
            PublicKeyCredentialDescriptor(id=item.credential_id) for item in existing
        ],
        authenticator_selection=AuthenticatorSelectionCriteria(
            resident_key=ResidentKeyRequirement.PREFERRED,
            user_verification=UserVerificationRequirement.REQUIRED,
        ),
    )
    await ephemeral_auth_store.put(
        "passkey-registration",
        ceremony_id,
        {"challenge": _encode_bytes(challenge), "user_id": str(user.id)},
        _PASSKEY_CHALLENGE_TTL,
    )
    return {
        "ceremony_id": ceremony_id,
        "public_key": json.loads(options_to_json(options)),
    }


async def verify_registration(
    repository: AuthRepository,
    *,
    user_id: str,
    ceremony_id: str,
    credential: dict[str, Any],
) -> None:
    ceremony = await ephemeral_auth_store.take("passkey-registration", ceremony_id)
    if ceremony is None or ceremony.get("user_id") != user_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired passkey registration ceremony",
        )
    try:
        verification = verify_registration_response(
            credential=credential,
            expected_challenge=_decode_bytes(str(ceremony["challenge"])),
            expected_rp_id=settings.WEBAUTHN_RP_ID,
            expected_origin=settings.WEBAUTHN_ORIGINS,
            require_user_verification=True,
        )
    except WebAuthnException as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passkey registration verification failed",
        ) from exc

    transports = credential.get("response", {}).get("transports")
    await repository.create_passkey(
        user_id=UUID(user_id),
        credential_id=verification.credential_id,
        public_key=verification.credential_public_key,
        sign_count=verification.sign_count,
        transports=json.dumps(transports) if transports else None,
        device_type=verification.credential_device_type.value,
        backed_up=verification.credential_backed_up,
    )


async def create_authentication_options(
    repository: AuthRepository, email: str
) -> dict[str, Any]:
    user = await repository.get_user_by_email(email)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No passkey is available for this account",
        )
    credentials = await repository.list_passkeys(user.id)
    if not credentials:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="No passkey is available for this account",
        )
    challenge = secrets.token_bytes(32)
    ceremony_id = secrets.token_urlsafe(32)
    options = generate_authentication_options(
        rp_id=settings.WEBAUTHN_RP_ID,
        challenge=challenge,
        allow_credentials=[
            PublicKeyCredentialDescriptor(id=item.credential_id) for item in credentials
        ],
        user_verification=UserVerificationRequirement.REQUIRED,
    )
    await ephemeral_auth_store.put(
        "passkey-authentication",
        ceremony_id,
        {"challenge": _encode_bytes(challenge), "user_id": str(user.id)},
        _PASSKEY_CHALLENGE_TTL,
    )
    return {
        "ceremony_id": ceremony_id,
        "public_key": json.loads(options_to_json(options)),
    }


async def verify_authentication(
    repository: AuthRepository,
    *,
    ceremony_id: str,
    credential: dict[str, Any],
) -> TokenResponse:
    ceremony = await ephemeral_auth_store.take("passkey-authentication", ceremony_id)
    if ceremony is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired passkey authentication ceremony",
        )
    credential_id = credential.get("id")
    if not isinstance(credential_id, str):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Passkey credential ID is missing",
        )
    stored = await repository.get_passkey(base64url_to_bytes(credential_id))
    if stored is None or str(stored.user_id) != str(ceremony["user_id"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Passkey credential was not recognized",
        )
    try:
        verification = verify_authentication_response(
            credential=credential,
            expected_challenge=_decode_bytes(str(ceremony["challenge"])),
            expected_rp_id=settings.WEBAUTHN_RP_ID,
            expected_origin=settings.WEBAUTHN_ORIGINS,
            credential_public_key=stored.public_key,
            credential_current_sign_count=stored.sign_count,
            require_user_verification=True,
        )
    except WebAuthnException as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Passkey authentication verification failed",
        ) from exc

    await repository.update_passkey_counter(
        stored,
        sign_count=verification.new_sign_count,
        device_type=verification.credential_device_type.value,
        backed_up=verification.credential_backed_up,
    )
    return _issue_tokens(str(stored.user_id))
