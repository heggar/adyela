"""Professional entity."""

from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any

from adyela_api_admin.config import ProfessionalStatus
from adyela_api_admin.domain.exceptions import InvalidStatusTransitionError


@dataclass
class Professional:
    """Professional entity for verification and approval workflow."""

    id: str
    email: str
    full_name: str
    specialty: str
    license_number: str
    status: ProfessionalStatus = ProfessionalStatus.PENDING_VERIFICATION
    submitted_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    reviewed_at: datetime | None = None
    reviewed_by: str | None = None
    rejection_reason: str | None = None
    documents: list[str] = field(default_factory=list)
    metadata: dict[str, Any] = field(default_factory=dict)

    def approve(self, admin_id: str) -> None:
        """Approve the professional application."""
        if self.status != ProfessionalStatus.PENDING_VERIFICATION:
            raise InvalidStatusTransitionError(
                f"Cannot approve professional with status {self.status}"
            )
        self.status = ProfessionalStatus.APPROVED
        self.reviewed_at = datetime.now(UTC)
        self.reviewed_by = admin_id

    def reject(self, admin_id: str, reason: str) -> None:
        """Reject the professional application."""
        if self.status != ProfessionalStatus.PENDING_VERIFICATION:
            raise InvalidStatusTransitionError(
                f"Cannot reject professional with status {self.status}"
            )
        self.status = ProfessionalStatus.REJECTED
        self.reviewed_at = datetime.now(UTC)
        self.reviewed_by = admin_id
        self.rejection_reason = reason

    def suspend(self, admin_id: str, reason: str) -> None:
        """Suspend an approved professional."""
        if self.status != ProfessionalStatus.APPROVED:
            raise InvalidStatusTransitionError(
                f"Cannot suspend professional with status {self.status}"
            )
        self.status = ProfessionalStatus.SUSPENDED
        self.reviewed_at = datetime.now(UTC)
        self.reviewed_by = admin_id
        self.rejection_reason = reason

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "id": self.id,
            "email": self.email,
            "full_name": self.full_name,
            "specialty": self.specialty,
            "license_number": self.license_number,
            "status": self.status.value,
            "submitted_at": self.submitted_at.isoformat(),
            "reviewed_at": self.reviewed_at.isoformat() if self.reviewed_at else None,
            "reviewed_by": self.reviewed_by,
            "rejection_reason": self.rejection_reason,
            "documents": self.documents,
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Professional":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            email=data["email"],
            full_name=data["full_name"],
            specialty=data["specialty"],
            license_number=data["license_number"],
            status=ProfessionalStatus(data["status"]),
            submitted_at=datetime.fromisoformat(data["submitted_at"]),
            reviewed_at=(
                datetime.fromisoformat(data["reviewed_at"]) if data.get("reviewed_at") else None
            ),
            reviewed_by=data.get("reviewed_by"),
            rejection_reason=data.get("rejection_reason"),
            documents=data.get("documents", []),
            metadata=data.get("metadata", {}),
        )
