"""Tenant entity for multi-tenant architecture."""

from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any

from adyela_api_admin.domain.exceptions import InvalidStatusTransitionError


@dataclass
class TenantStats:
    """Tenant statistics."""

    total_appointments: int = 0
    total_patients: int = 0
    total_revenue: float = 0.0
    last_appointment_date: datetime | None = None

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary."""
        return {
            "total_appointments": self.total_appointments,
            "total_patients": self.total_patients,
            "total_revenue": self.total_revenue,
            "last_appointment_date": (
                self.last_appointment_date.isoformat() if self.last_appointment_date else None
            ),
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "TenantStats":
        """Create from dictionary."""
        return cls(
            total_appointments=data.get("total_appointments", 0),
            total_patients=data.get("total_patients", 0),
            total_revenue=data.get("total_revenue", 0.0),
            last_appointment_date=(
                datetime.fromisoformat(data["last_appointment_date"])
                if data.get("last_appointment_date")
                else None
            ),
        )


@dataclass
class Tenant:
    """
    Tenant entity for multi-tenant architecture.

    Represents a healthcare practice or organization.
    Each tenant has isolated data and configuration.
    """

    id: str
    owner_id: str
    name: str
    email: str
    phone: str
    tier: str = "free"  # free, pro, enterprise
    status: str = "active"  # active, suspended, cancelled
    organization_id: str | None = None
    timezone: str = "America/Bogota"
    language: str = "es"
    created_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    updated_at: datetime = field(default_factory=lambda: datetime.now(UTC))
    migrated_from_legacy: bool = False
    subscription_expires_at: datetime | None = None
    payment_method_id: str | None = None
    stats: TenantStats = field(default_factory=TenantStats)
    metadata: dict[str, Any] = field(default_factory=dict)

    def activate(self) -> None:
        """Activate a suspended or cancelled tenant."""
        if self.status == "active":
            raise InvalidStatusTransitionError("Tenant is already active")
        self.status = "active"
        self.updated_at = datetime.now(UTC)

    def suspend(self, reason: str) -> None:
        """Suspend an active tenant."""
        if self.status != "active":
            raise InvalidStatusTransitionError(f"Cannot suspend tenant with status {self.status}")
        self.status = "suspended"
        self.updated_at = datetime.now(UTC)
        self.metadata["suspension_reason"] = reason
        self.metadata["suspended_at"] = datetime.now(UTC).isoformat()

    def cancel(self, reason: str) -> None:
        """Cancel a tenant (soft delete)."""
        if self.status == "cancelled":
            raise InvalidStatusTransitionError("Tenant is already cancelled")
        self.status = "cancelled"
        self.updated_at = datetime.now(UTC)
        self.metadata["cancellation_reason"] = reason
        self.metadata["cancelled_at"] = datetime.now(UTC).isoformat()

    def upgrade_tier(self, new_tier: str) -> None:
        """Upgrade tenant tier."""
        tier_order = {"free": 0, "pro": 1, "enterprise": 2}
        if new_tier not in tier_order:
            raise ValueError(f"Invalid tier: {new_tier}")
        if tier_order[new_tier] <= tier_order[self.tier]:
            raise ValueError(f"Cannot upgrade from {self.tier} to {new_tier}")
        self.tier = new_tier
        self.updated_at = datetime.now(UTC)
        self.metadata["tier_upgraded_at"] = datetime.now(UTC).isoformat()
        self.metadata["previous_tier"] = self.tier

    def downgrade_tier(self, new_tier: str) -> None:
        """Downgrade tenant tier."""
        tier_order = {"free": 0, "pro": 1, "enterprise": 2}
        if new_tier not in tier_order:
            raise ValueError(f"Invalid tier: {new_tier}")
        if tier_order[new_tier] >= tier_order[self.tier]:
            raise ValueError(f"Cannot downgrade from {self.tier} to {new_tier}")
        self.tier = new_tier
        self.updated_at = datetime.now(UTC)
        self.metadata["tier_downgraded_at"] = datetime.now(UTC).isoformat()
        self.metadata["previous_tier"] = self.tier

    def update_stats(
        self,
        total_appointments: int | None = None,
        total_patients: int | None = None,
        total_revenue: float | None = None,
        last_appointment_date: datetime | None = None,
    ) -> None:
        """Update tenant statistics."""
        if total_appointments is not None:
            self.stats.total_appointments = total_appointments
        if total_patients is not None:
            self.stats.total_patients = total_patients
        if total_revenue is not None:
            self.stats.total_revenue = total_revenue
        if last_appointment_date is not None:
            self.stats.last_appointment_date = last_appointment_date
        self.updated_at = datetime.now(UTC)

    def is_subscription_active(self) -> bool:
        """Check if subscription is active."""
        if not self.subscription_expires_at:
            return self.tier == "free"  # Free tier never expires
        return datetime.now(UTC) < self.subscription_expires_at

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "id": self.id,
            "owner_id": self.owner_id,
            "name": self.name,
            "email": self.email,
            "phone": self.phone,
            "tier": self.tier,
            "status": self.status,
            "organization_id": self.organization_id,
            "timezone": self.timezone,
            "language": self.language,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "migrated_from_legacy": self.migrated_from_legacy,
            "subscription_expires_at": (
                self.subscription_expires_at.isoformat() if self.subscription_expires_at else None
            ),
            "payment_method_id": self.payment_method_id,
            "stats": self.stats.to_dict(),
            "metadata": self.metadata,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Tenant":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            owner_id=data["owner_id"],
            name=data["name"],
            email=data["email"],
            phone=data["phone"],
            tier=data.get("tier", "free"),
            status=data.get("status", "active"),
            organization_id=data.get("organization_id"),
            timezone=data.get("timezone", "America/Bogota"),
            language=data.get("language", "es"),
            created_at=datetime.fromisoformat(data["created_at"]),
            updated_at=datetime.fromisoformat(data["updated_at"]),
            migrated_from_legacy=data.get("migrated_from_legacy", False),
            subscription_expires_at=(
                datetime.fromisoformat(data["subscription_expires_at"])
                if data.get("subscription_expires_at")
                else None
            ),
            payment_method_id=data.get("payment_method_id"),
            stats=TenantStats.from_dict(data.get("stats", {})),
            metadata=data.get("metadata", {}),
        )
