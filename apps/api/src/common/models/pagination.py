"""Pagination models and utilities."""

from typing import Annotated

import msgspec
from msgspec import Meta


class PaginationParams(msgspec.Struct):
    """Query parameters for pagination."""

    page: Annotated[int, Meta(ge=1, description="Page number (1-indexed)")] = 1
    limit: Annotated[int, Meta(ge=1, le=100, description="Items per page")] = 20

    @property
    def offset(self) -> int:
        """Calculate offset for database query."""
        return (self.page - 1) * self.limit


class PaginationMeta(msgspec.Struct):
    """Pagination metadata."""

    page: Annotated[int, Meta(description="Current page number")]
    limit: Annotated[int, Meta(description="Items per page")]
    total: Annotated[int, Meta(description="Total number of items")]
    total_pages: Annotated[int, Meta(description="Total number of pages")]
    has_next: Annotated[bool, Meta(description="Whether there is a next page")]
    has_prev: Annotated[bool, Meta(description="Whether there is a previous page")]


class PaginatedResponse[T](msgspec.Struct):
    """Generic paginated response wrapper."""

    data: list[T]
    meta: PaginationMeta

    @classmethod
    def create(
        cls,
        data: list[T],
        total: int,
        page: int,
        limit: int,
    ) -> PaginatedResponse[T]:
        """
        Create a paginated response.

        Args:
            data: List of items for the current page
            total: Total number of items across all pages
            page: Current page number (1-indexed)
            limit: Items per page

        Returns:
            PaginatedResponse with data and metadata
        """
        total_pages = (total + limit - 1) // limit if total > 0 else 0

        return cls(
            data=data,
            meta=PaginationMeta(
                page=page,
                limit=limit,
                total=total,
                total_pages=total_pages,
                has_next=page < total_pages,
                has_prev=page > 1,
            ),
        )
