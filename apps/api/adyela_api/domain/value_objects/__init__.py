"""Domain value objects."""

from dataclasses import dataclass
from datetime import datetime
from typing import Any


@dataclass(frozen=True)
class Email:
    """Email value object."""

    value: str

    def __post_init__(self) -> None:
        """Validate email format."""
        if "@" not in self.value or "." not in self.value.split("@")[1]:
            raise ValueError(f"Invalid email format: {self.value}")

    def __str__(self) -> str:
        return self.value


@dataclass(frozen=True)
class PhoneNumber:
    """Phone number value object."""

    value: str

    def __post_init__(self) -> None:
        """Validate phone number format."""
        # Simple validation - enhance as needed
        cleaned = "".join(filter(str.isdigit, self.value))
        if len(cleaned) < 10:
            raise ValueError(f"Invalid phone number: {self.value}")

    def __str__(self) -> str:
        return self.value


@dataclass(frozen=True)
class TenantId:
    """Tenant ID value object."""

    value: str

    def __post_init__(self) -> None:
        """Validate tenant ID."""
        if not self.value or not self.value.strip():
            raise ValueError("Tenant ID cannot be empty")

    def __str__(self) -> str:
        return self.value


@dataclass(frozen=True)
class Address:
    """Address value object."""

    street: str
    city: str
    state: str
    postal_code: str
    country: str

    def to_dict(self) -> dict[str, str]:
        """Convert to dictionary."""
        return {
            "street": self.street,
            "city": self.city,
            "state": self.state,
            "postal_code": self.postal_code,
            "country": self.country,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Address":
        """Create from dictionary."""
        return cls(
            street=data["street"],
            city=data["city"],
            state=data["state"],
            postal_code=data["postal_code"],
            country=data["country"],
        )


@dataclass(frozen=True)
class DateTimeRange:
    """Date time range value object."""

    start: datetime
    end: datetime

    def __post_init__(self) -> None:
        """Validate date range."""
        if self.start >= self.end:
            raise ValueError("Start time must be before end time")

    def overlaps_with(self, other: "DateTimeRange") -> bool:
        """Check if this range overlaps with another."""
        return self.start < other.end and self.end > other.start

    @property
    def duration_minutes(self) -> int:
        """Get duration in minutes."""
        return int((self.end - self.start).total_seconds() / 60)
