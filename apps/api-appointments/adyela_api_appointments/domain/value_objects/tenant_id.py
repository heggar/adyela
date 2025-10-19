"""Tenant ID value object."""

from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True)
class TenantId:
    """Tenant identifier value object."""

    value: UUID

    def __post_init__(self) -> None:
        """Validate tenant ID."""
        if not isinstance(self.value, UUID):
            raise ValueError("Tenant ID must be a UUID")

    def __str__(self) -> str:
        """String representation."""
        return str(self.value)

    def __eq__(self, other: object) -> bool:
        """Equality comparison."""
        if not isinstance(other, TenantId):
            return False
        return self.value == other.value

    def __hash__(self) -> int:
        """Hash for use in sets and dicts."""
        return hash(self.value)
