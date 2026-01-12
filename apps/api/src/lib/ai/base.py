from abc import ABC, abstractmethod
from collections.abc import AsyncIterator
from typing import Any


class AIProvider[T](ABC):
    @abstractmethod
    async def analyze_image(self, image_data: bytes | list[bytes]) -> T:
        pass

    @abstractmethod
    async def generate_text(self, prompt: str, **kwargs: Any) -> str:
        """Generate text from prompt.

        Args:
            prompt: Input prompt.
            **kwargs: Additional provider-specific options.

        Returns:
            Generated text.
        """
        pass

    @abstractmethod
    async def generate_stream(self, prompt: str, **kwargs: Any) -> AsyncIterator[str]:
        """Generate text with streaming.

        Args:
            prompt: Input prompt.
            **kwargs: Additional provider-specific options.

        Yields:
            Text chunks as they are generated.
        """
        pass

    @abstractmethod
    async def generate_structured(
        self, prompt: str, schema: type[T], **kwargs: Any
    ) -> T:
        """Generate structured output matching a Pydantic schema.

        Args:
            prompt: Input prompt.
            schema: Pydantic model class for response validation.
            **kwargs: Additional provider-specific options.

        Returns:
            Parsed response matching the schema.
        """
        pass
