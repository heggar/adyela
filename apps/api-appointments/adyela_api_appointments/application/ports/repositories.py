"""Repository interfaces."""

from abc import ABC, abstractmethod
from datetime import datetime

from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.value_objects import DateTimeRange, TenantId


class AppointmentRepository(ABC):
    """Appointment repository interface."""

    @abstractmethod
    async def create(self, appointment: Appointment) -> Appointment:
        """Create a new appointment."""
        pass

    @abstractmethod
    async def get_by_id(self, appointment_id: str, tenant_id: TenantId) -> Appointment | None:
        """Get appointment by ID."""
        pass

    @abstractmethod
    async def list_by_tenant(
        self,
        tenant_id: TenantId,
        limit: int = 20,
        offset: int = 0,
    ) -> list[Appointment]:
        """List appointments for a tenant."""
        pass

    @abstractmethod
    async def list_by_patient(
        self,
        patient_id: str,
        tenant_id: TenantId,
        limit: int = 20,
        offset: int = 0,
    ) -> list[Appointment]:
        """List appointments for a patient."""
        pass

    @abstractmethod
    async def list_by_practitioner(
        self,
        practitioner_id: str,
        tenant_id: TenantId,
        limit: int = 20,
        offset: int = 0,
    ) -> list[Appointment]:
        """List appointments for a practitioner."""
        pass

    @abstractmethod
    async def update(self, appointment: Appointment) -> Appointment:
        """Update an existing appointment."""
        pass

    @abstractmethod
    async def delete(self, appointment_id: str, tenant_id: TenantId) -> bool:
        """Delete an appointment."""
        pass

    @abstractmethod
    async def find_conflicts(
        self,
        practitioner_id: str,
        tenant_id: TenantId,
        time_range: DateTimeRange,
        exclude_appointment_id: str | None = None,
    ) -> list[Appointment]:
        """Find conflicting appointments for a practitioner in a time range."""
        pass

    @abstractmethod
    async def count_by_tenant(self, tenant_id: TenantId) -> int:
        """Count total appointments for a tenant."""
        pass

    @abstractmethod
    async def find_upcoming(
        self,
        tenant_id: TenantId,
        start_date: datetime,
        limit: int = 100,
    ) -> list[Appointment]:
        """Find upcoming appointments starting from a specific date."""
        pass
