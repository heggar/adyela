"""Practitioner entity."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from adyela_api.config import UserRole
from adyela_api.domain.value_objects import Email, PhoneNumber, TenantId


@dataclass
class Practitioner:
    """Practitioner entity (doctor, nurse, etc.)."""

    id: str
    tenant_id: TenantId
    first_name: str
    last_name: str
    email: Email
    phone: PhoneNumber
    role: UserRole
    specialty: str | None = None
    license_number: str | None = None
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def full_name(self) -> str:
        """Get practitioner's full name."""
        return f"{self.first_name} {self.last_name}"

    @property
    def display_name(self) -> str:
        """Get practitioner's display name with title."""
        title = "Dr." if self.role == UserRole.DOCTOR else ""
        return f"{title} {self.full_name}".strip()

    def can_manage_appointments(self) -> bool:
        """Check if practitioner can manage appointments."""
        return self.role in [UserRole.DOCTOR, UserRole.NURSE, UserRole.RECEPTIONIST]

    def can_conduct_consultations(self) -> bool:
        """Check if practitioner can conduct consultations."""
        return self.role in [UserRole.DOCTOR, UserRole.NURSE]

    def deactivate(self) -> None:
        """Deactivate the practitioner."""
        self.is_active = False
        self.updated_at = datetime.utcnow()

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "id": self.id,
            "tenant_id": str(self.tenant_id),
            "first_name": self.first_name,
            "last_name": self.last_name,
            "email": str(self.email),
            "phone": str(self.phone),
            "role": self.role.value,
            "specialty": self.specialty,
            "license_number": self.license_number,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Practitioner":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            tenant_id=TenantId(data["tenant_id"]),
            first_name=data["first_name"],
            last_name=data["last_name"],
            email=Email(data["email"]),
            phone=PhoneNumber(data["phone"]),
            role=UserRole(data["role"]),
            specialty=data.get("specialty"),
            license_number=data.get("license_number"),
            is_active=data.get("is_active", True),
            created_at=datetime.fromisoformat(data["created_at"]),
            updated_at=datetime.fromisoformat(data["updated_at"]),
            metadata=data.get("metadata", {}),
        )
