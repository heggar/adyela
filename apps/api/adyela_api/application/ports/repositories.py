"""Repository port interfaces."""

from abc import ABC, abstractmethod
from typing import Generic, TypeVar

from adyela_api.domain import Appointment, Patient, Practitioner, Tenant

T = TypeVar("T")


class BaseRepository(ABC, Generic[T]):
    """Base repository interface."""

    @abstractmethod
    async def create(self, entity: T) -> T:
        """Create a new entity."""
        pass

    @abstractmethod
    async def get_by_id(self, entity_id: str) -> T | None:
        """Get entity by ID."""
        pass

    @abstractmethod
    async def update(self, entity: T) -> T:
        """Update an existing entity."""
        pass

    @abstractmethod
    async def delete(self, entity_id: str) -> bool:
        """Delete an entity."""
        pass

    @abstractmethod
    async def list(
        self, skip: int = 0, limit: int = 100, filters: dict | None = None
    ) -> list[T]:
        """List entities with pagination and filtering."""
        pass


class TenantRepository(BaseRepository[Tenant]):
    """Tenant repository interface."""

    @abstractmethod
    async def get_by_name(self, name: str) -> Tenant | None:
        """Get tenant by name."""
        pass


class PatientRepository(BaseRepository[Patient]):
    """Patient repository interface."""

    @abstractmethod
    async def get_by_email(self, tenant_id: str, email: str) -> Patient | None:
        """Get patient by email within a tenant."""
        pass

    @abstractmethod
    async def get_by_medical_record(
        self, tenant_id: str, medical_record_number: str
    ) -> Patient | None:
        """Get patient by medical record number."""
        pass

    @abstractmethod
    async def list_by_tenant(
        self, tenant_id: str, skip: int = 0, limit: int = 100
    ) -> list[Patient]:
        """List patients for a tenant."""
        pass


class PractitionerRepository(BaseRepository[Practitioner]):
    """Practitioner repository interface."""

    @abstractmethod
    async def get_by_email(self, tenant_id: str, email: str) -> Practitioner | None:
        """Get practitioner by email within a tenant."""
        pass

    @abstractmethod
    async def list_by_tenant(
        self, tenant_id: str, skip: int = 0, limit: int = 100
    ) -> list[Practitioner]:
        """List practitioners for a tenant."""
        pass

    @abstractmethod
    async def list_by_specialty(
        self, tenant_id: str, specialty: str, skip: int = 0, limit: int = 100
    ) -> list[Practitioner]:
        """List practitioners by specialty."""
        pass


class AppointmentRepository(BaseRepository[Appointment]):
    """Appointment repository interface."""

    @abstractmethod
    async def list_by_patient(
        self, tenant_id: str, patient_id: str, skip: int = 0, limit: int = 100
    ) -> list[Appointment]:
        """List appointments for a patient."""
        pass

    @abstractmethod
    async def list_by_practitioner(
        self, tenant_id: str, practitioner_id: str, skip: int = 0, limit: int = 100
    ) -> list[Appointment]:
        """List appointments for a practitioner."""
        pass

    @abstractmethod
    async def list_by_date_range(
        self,
        tenant_id: str,
        start_date: str,
        end_date: str,
        skip: int = 0,
        limit: int = 100,
    ) -> list[Appointment]:
        """List appointments within a date range."""
        pass

    @abstractmethod
    async def check_availability(
        self, tenant_id: str, practitioner_id: str, start_time: str, end_time: str
    ) -> bool:
        """Check if practitioner is available in the given time slot."""
        pass
