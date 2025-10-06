"""Appointment entity."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from adyela_api.config import AppointmentStatus, AppointmentType
from adyela_api.domain.exceptions import BusinessRuleViolationError
from adyela_api.domain.value_objects import DateTimeRange, TenantId


@dataclass
class Appointment:
    """Appointment entity."""

    id: str
    tenant_id: TenantId
    patient_id: str
    practitioner_id: str
    schedule: DateTimeRange
    appointment_type: AppointmentType
    status: AppointmentStatus = AppointmentStatus.SCHEDULED
    reason: str | None = None
    notes: str | None = None
    video_room_url: str | None = None
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    metadata: dict[str, Any] = field(default_factory=dict)

    def __post_init__(self) -> None:
        """Validate appointment after initialization."""
        if self.schedule.start < datetime.utcnow():
            raise BusinessRuleViolationError("Cannot create appointment in the past")

    def confirm(self) -> None:
        """Confirm the appointment."""
        if self.status != AppointmentStatus.SCHEDULED:
            raise BusinessRuleViolationError(
                f"Cannot confirm appointment with status {self.status}"
            )
        self.status = AppointmentStatus.CONFIRMED
        self.updated_at = datetime.utcnow()

    def start(self) -> None:
        """Start the appointment."""
        if self.status not in [AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED]:
            raise BusinessRuleViolationError(f"Cannot start appointment with status {self.status}")
        self.status = AppointmentStatus.IN_PROGRESS
        self.updated_at = datetime.utcnow()

    def complete(self, notes: str | None = None) -> None:
        """Complete the appointment."""
        if self.status != AppointmentStatus.IN_PROGRESS:
            raise BusinessRuleViolationError(
                f"Cannot complete appointment with status {self.status}"
            )
        self.status = AppointmentStatus.COMPLETED
        if notes:
            self.notes = notes
        self.updated_at = datetime.utcnow()

    def cancel(self) -> None:
        """Cancel the appointment."""
        if self.status in [AppointmentStatus.COMPLETED, AppointmentStatus.CANCELLED]:
            raise BusinessRuleViolationError(f"Cannot cancel appointment with status {self.status}")
        self.status = AppointmentStatus.CANCELLED
        self.updated_at = datetime.utcnow()

    def mark_no_show(self) -> None:
        """Mark appointment as no-show."""
        if self.status not in [AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED]:
            raise BusinessRuleViolationError(
                f"Cannot mark as no-show appointment with status {self.status}"
            )
        self.status = AppointmentStatus.NO_SHOW
        self.updated_at = datetime.utcnow()

    def set_video_room(self, room_url: str) -> None:
        """Set video room URL."""
        if self.appointment_type != AppointmentType.VIDEO_CALL:
            raise BusinessRuleViolationError("Can only set video room for video call appointments")
        self.video_room_url = room_url
        self.updated_at = datetime.utcnow()

    @property
    def duration_minutes(self) -> int:
        """Get appointment duration in minutes."""
        return self.schedule.duration_minutes

    @property
    def is_upcoming(self) -> bool:
        """Check if appointment is upcoming."""
        return self.schedule.start > datetime.utcnow() and self.status in [
            AppointmentStatus.SCHEDULED,
            AppointmentStatus.CONFIRMED,
        ]

    @property
    def can_be_modified(self) -> bool:
        """Check if appointment can be modified."""
        return self.status in [AppointmentStatus.SCHEDULED, AppointmentStatus.CONFIRMED]

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "id": self.id,
            "tenant_id": str(self.tenant_id),
            "patient_id": self.patient_id,
            "practitioner_id": self.practitioner_id,
            "start_time": self.schedule.start.isoformat(),
            "end_time": self.schedule.end.isoformat(),
            "appointment_type": self.appointment_type.value,
            "status": self.status.value,
            "reason": self.reason,
            "notes": self.notes,
            "video_room_url": self.video_room_url,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Appointment":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            tenant_id=TenantId(data["tenant_id"]),
            patient_id=data["patient_id"],
            practitioner_id=data["practitioner_id"],
            schedule=DateTimeRange(
                start=datetime.fromisoformat(data["start_time"]),
                end=datetime.fromisoformat(data["end_time"]),
            ),
            appointment_type=AppointmentType(data["appointment_type"]),
            status=AppointmentStatus(data["status"]),
            reason=data.get("reason"),
            notes=data.get("notes"),
            video_room_url=data.get("video_room_url"),
            created_at=datetime.fromisoformat(data["created_at"]),
            updated_at=datetime.fromisoformat(data["updated_at"]),
            metadata=data.get("metadata", {}),
        )
