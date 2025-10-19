"""DateTime range value object."""

from dataclasses import dataclass
from datetime import datetime

from adyela_api_appointments.domain.exceptions import InvalidTimeRangeError


@dataclass(frozen=True)
class DateTimeRange:
    """Date and time range value object."""

    start: datetime
    end: datetime

    def __post_init__(self) -> None:
        """Validate time range."""
        if self.start >= self.end:
            raise InvalidTimeRangeError("Start time must be before end time")

    @property
    def duration_minutes(self) -> int:
        """Get duration in minutes."""
        delta = self.end - self.start
        return int(delta.total_seconds() / 60)

    def overlaps_with(self, other: "DateTimeRange") -> bool:
        """Check if this range overlaps with another."""
        return (
            self.start < other.end and self.end > other.start
        )

    def contains(self, dt: datetime) -> bool:
        """Check if a datetime is within this range."""
        return self.start <= dt < self.end

    def __str__(self) -> str:
        """String representation."""
        return f"{self.start.isoformat()} - {self.end.isoformat()}"
