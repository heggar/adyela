"""Audit log entity."""

from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any

from adyela_api_admin.config import AuditAction


@dataclass
class AuditLog:
    """Audit log entry for tracking admin actions."""

    id: str
    action: AuditAction
    performed_by: str
    target_id: str | None
    details: dict[str, Any]
    ip_address: str | None = None
    timestamp: datetime = field(default_factory=lambda: datetime.now(UTC))

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary for serialization."""
        return {
            "id": self.id,
            "action": self.action.value,
            "performed_by": self.performed_by,
            "target_id": self.target_id,
            "details": self.details,
            "ip_address": self.ip_address,
            "timestamp": self.timestamp.isoformat(),
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "AuditLog":
        """Create from dictionary."""
        return cls(
            id=data["id"],
            action=AuditAction(data["action"]),
            performed_by=data["performed_by"],
            target_id=data.get("target_id"),
            details=data["details"],
            ip_address=data.get("ip_address"),
            timestamp=datetime.fromisoformat(data["timestamp"]),
        )
