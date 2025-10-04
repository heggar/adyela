"""Tenant entity."""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any

from adyela_api.domain.value_objects import Address, Email, PhoneNumber


@dataclass
class Tenant:
    """Tenant entity representing an organization (clinic, hospital, etc.)."""

    id: str
    name: str
    email: Email
    phone: PhoneNumber
    address: Address
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    settings: dict[str, Any] = field(default_factory=dict)

    def activate(self) -> None:
        """Activate the tenant."""
        self.is_active = True
        self.updated_at = datetime.utcnow()

    def deactivate(self) -> None:
        """Deactivate the tenant."""
        self.is_active = False
        self.updated_at = datetime.utcnow()

    def update_settings(self, settings: dict[str, Any]) -> None:
        """Update tenant settings."""
        self.settings.update(settings)
        self.updated_at = datetime.utcnow()

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "id": self.id,
            "name": self.name,
            "email": str(self.email),
            "phone": str(self.phone),
            "address": self.address.to_dict(),
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "settings": self.settings,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Tenant":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            name=data["name"],
            email=Email(data["email"]),
            phone=PhoneNumber(data["phone"]),
            address=Address.from_dict(data["address"]),
            is_active=data.get("is_active", True),
            created_at=datetime.fromisoformat(data["created_at"]),
            updated_at=datetime.fromisoformat(data["updated_at"]),
            settings=data.get("settings", {}),
        )
