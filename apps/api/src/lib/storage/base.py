from abc import ABC, abstractmethod


class StorageProvider(ABC):
    @abstractmethod
    async def upload(
        self,
        bucket: str,
        key: str,
        data: bytes,
        content_type: str | None = None,
    ) -> str:
        pass

    @abstractmethod
    async def download(self, bucket: str, key: str) -> bytes:
        pass

    @abstractmethod
    async def delete(self, bucket: str, key: str) -> None:
        pass

    @abstractmethod
    async def get_signed_url(
        self, bucket: str, key: str, expires_in: int = 3600
    ) -> str:
        pass

    async def aclose(self) -> None:
        """Release underlying resources. Default no-op; override if needed."""
        return
