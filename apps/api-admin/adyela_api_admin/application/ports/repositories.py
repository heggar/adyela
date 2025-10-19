"""Repository interfaces."""

from abc import ABC, abstractmethod

from adyela_api_admin.config import ProfessionalStatus
from adyela_api_admin.domain.entities import AuditLog, Professional


class ProfessionalRepository(ABC):
    """Professional repository interface."""

    @abstractmethod
    async def create(self, professional: Professional) -> Professional:
        """Create a new professional."""
        pass

    @abstractmethod
    async def get_by_id(self, professional_id: str) -> Professional | None:
        """Get professional by ID."""
        pass

    @abstractmethod
    async def update(self, professional: Professional) -> Professional:
        """Update a professional."""
        pass

    @abstractmethod
    async def list_by_status(
        self, status: ProfessionalStatus, limit: int = 50
    ) -> list[Professional]:
        """List professionals by status."""
        pass

    @abstractmethod
    async def count_by_status(self, status: ProfessionalStatus) -> int:
        """Count professionals by status."""
        pass


class AuditLogRepository(ABC):
    """Audit log repository interface."""

    @abstractmethod
    async def create(self, log: AuditLog) -> AuditLog:
        """Create audit log entry."""
        pass

    @abstractmethod
    async def list_recent(self, limit: int = 100) -> list[AuditLog]:
        """List recent audit log entries."""
        pass
