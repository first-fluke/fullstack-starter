"""Persistence operations for users and authentication credentials."""

from uuid import UUID

from sqlalchemy import select

from src.lib.auth import normalize_email
from src.lib.dependencies import DBSession
from src.users.model import OAuthIdentity, PasskeyCredential, User


class AuthRepository:
    """Database access for authentication services."""

    def __init__(self, db: DBSession) -> None:
        self._db = db

    async def get_user_by_id(self, user_id: str) -> User | None:
        result = await self._db.execute(select(User).where(User.id == UUID(user_id)))
        return result.scalar_one_or_none()

    async def get_user_by_email(self, email: str) -> User | None:
        result = await self._db.execute(
            select(User).where(User.email == normalize_email(email))
        )
        return result.scalar_one_or_none()

    async def create_user(
        self,
        *,
        email: str,
        name: str | None = None,
        image: str | None = None,
        email_verified: bool = False,
        password_hash: str | None = None,
    ) -> User:
        user = User(
            email=normalize_email(email),
            name=name,
            image=image,
            email_verified=email_verified,
            password_hash=password_hash,
        )
        self._db.add(user)
        await self._db.flush()
        await self._db.refresh(user)
        return user

    async def get_oauth_user(self, provider: str, subject: str) -> User | None:
        result = await self._db.execute(
            select(User)
            .join(OAuthIdentity, OAuthIdentity.user_id == User.id)
            .where(
                OAuthIdentity.provider == provider,
                OAuthIdentity.subject == subject,
            )
        )
        return result.scalar_one_or_none()

    async def link_oauth_identity(
        self, *, user_id: UUID, provider: str, subject: str
    ) -> None:
        self._db.add(OAuthIdentity(user_id=user_id, provider=provider, subject=subject))
        await self._db.flush()

    async def list_passkeys(self, user_id: UUID) -> list[PasskeyCredential]:
        result = await self._db.execute(
            select(PasskeyCredential).where(PasskeyCredential.user_id == user_id)
        )
        return list(result.scalars().all())

    async def get_passkey(self, credential_id: bytes) -> PasskeyCredential | None:
        result = await self._db.execute(
            select(PasskeyCredential).where(
                PasskeyCredential.credential_id == credential_id
            )
        )
        return result.scalar_one_or_none()

    async def create_passkey(
        self,
        *,
        user_id: UUID,
        credential_id: bytes,
        public_key: bytes,
        sign_count: int,
        transports: str | None,
        device_type: str,
        backed_up: bool,
    ) -> PasskeyCredential:
        credential = PasskeyCredential(
            user_id=user_id,
            credential_id=credential_id,
            public_key=public_key,
            sign_count=sign_count,
            transports=transports,
            device_type=device_type,
            backed_up=backed_up,
        )
        self._db.add(credential)
        await self._db.flush()
        return credential

    async def update_passkey_counter(
        self,
        credential: PasskeyCredential,
        *,
        sign_count: int,
        device_type: str,
        backed_up: bool,
    ) -> None:
        credential.sign_count = sign_count
        credential.device_type = device_type
        credential.backed_up = backed_up
        await self._db.flush()
