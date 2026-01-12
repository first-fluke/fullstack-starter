"""Pagination models and utilities."""

from pydantic import BaseModel, Field


class PaginationParams(BaseModel):
    """Query parameters for pagination."""

    page: int = Field(default=1, ge=1, description="Page number (1-indexed)")
    limit: int = Field(default=20, ge=1, le=100, description="Items per page")

    @property
    def offset(self) -> int:
        """Calculate offset for database query."""
        return (self.page - 1) * self.limit


class PaginationMeta(BaseModel):
    """Pagination metadata."""

    page: int = Field(description="Current page number")
    limit: int = Field(description="Items per page")
    total: int = Field(description="Total number of items")
    total_pages: int = Field(description="Total number of pages")
    has_next: bool = Field(description="Whether there is a next page")
    has_prev: bool = Field(description="Whether there is a previous page")


class PaginatedResponse[T](BaseModel):
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
    ) -> "PaginatedResponse[T]":
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
