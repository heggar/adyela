"""Patient entity."""

from dataclasses import dataclass, field
from datetime import date, datetime
from typing import Any

from adyela_api.domain.value_objects import Email, PhoneNumber, TenantId


@dataclass
class Patient:
    """Patient entity."""

    id: str
    tenant_id: TenantId
    first_name: str
    last_name: str
    email: Email
    phone: PhoneNumber
    date_of_birth: date
    gender: str | None = None
    medical_record_number: str | None = None
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    metadata: dict[str, Any] = field(default_factory=dict)

    @property
    def full_name(self) -> str:
        """Get patient's full name."""
        return f"{self.first_name} {self.last_name}"

    @property
    def age(self) -> int:
        """Calculate patient's age."""
        today = date.today()
        return today.year - self.date_of_birth.year - (
            (today.month, today.day) < (self.date_of_birth.month, self.date_of_birth.day)
        )

    def deactivate(self) -> None:
        """Deactivate the patient."""
        self.is_active = False
        self.updated_at = datetime.utcnow()

    def update_contact_info(self, email: Email | None = None, phone: PhoneNumber | None = None) -> None:
        """Update patient contact information."""
        if email:
            self.email = email
        if phone:
            self.phone = phone
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
            "date_of_birth": self.date_of_birth.isoformat(),
            "gender": self.gender,
            "medical_record_number": self.medical_record_number,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Patient":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            tenant_id=TenantId(data["tenant_id"]),
            first_name=data["first_name"],
            last_name=data["last_name"],
            email=Email(data["email"]),
            phone=PhoneNumber(data["phone"]),
            date_of_birth=date.fromisoformat(data["date_of_birth"]),
            gender=data.get("gender"),
            medical_record_number=data.get("medical_record_number"),
            is_active=data.get("is_active", True),
            created_at=datetime.fromisoformat(data["created_at"]),
            updated_at=datetime.fromisoformat(data["updated_at"]),
            metadata=data.get("metadata", {}),
        )
