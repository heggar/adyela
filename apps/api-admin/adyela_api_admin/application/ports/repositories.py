"""Repository interfaces."""

from abc import ABC, abstractmethod

from adyela_api_admin.config import ProfessionalStatus
from adyela_api_admin.domain.entities import AuditLog, Professional, Tenant


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


class TenantRepository(ABC):
    """Tenant repository interface."""

    @abstractmethod
    async def create(self, tenant: Tenant) -> Tenant:
        """Create a new tenant."""
        pass

    @abstractmethod
    async def get_by_id(self, tenant_id: str) -> Tenant | None:
        """Get tenant by ID."""
        pass

    @abstractmethod
    async def get_by_owner(self, owner_id: str) -> list[Tenant]:
        """Get all tenants owned by a user."""
        pass

    @abstractmethod
    async def update(self, tenant: Tenant) -> Tenant:
        """Update a tenant."""
        pass

    @abstractmethod
    async def delete(self, tenant_id: str) -> None:
        """Delete a tenant (hard delete - use with caution)."""
        pass

    @abstractmethod
    async def list_all(self, limit: int = 100, offset: int = 0) -> list[Tenant]:
        """List all tenants with pagination."""
        pass

    @abstractmethod
    async def list_by_status(self, status: str, limit: int = 100) -> list[Tenant]:
        """List tenants by status."""
        pass

    @abstractmethod
    async def list_by_tier(self, tier: str, limit: int = 100) -> list[Tenant]:
        """List tenants by tier."""
        pass

    @abstractmethod
    async def count_by_status(self, status: str) -> int:
        """Count tenants by status."""
        pass

    @abstractmethod
    async def count_total(self) -> int:
        """Count total tenants."""
        pass
