"""List appointments use case."""

from uuid import UUID

from adyela_api_appointments.application.ports import AppointmentRepository
from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.value_objects import TenantId


class ListAppointmentsUseCase:
    """Use case for listing appointments."""

    def __init__(self, repository: AppointmentRepository) -> None:
        """Initialize use case."""
        self.repository = repository

    async def execute(
        self,
        tenant_id: UUID,
        patient_id: str | None = None,
        practitioner_id: str | None = None,
        limit: int = 20,
        offset: int = 0,
    ) -> tuple[list[Appointment], int]:
        """
        List appointments with optional filtering.

        Args:
            tenant_id: Tenant identifier
            patient_id: Optional patient filter
            practitioner_id: Optional practitioner filter
            limit: Maximum number of results
            offset: Number of results to skip

        Returns:
            Tuple of (appointments list, total count)
        """
        tenant = TenantId(tenant_id)

        # Filter by patient if specified
        if patient_id:
            appointments = await self.repository.list_by_patient(
                patient_id=patient_id,
                tenant_id=tenant,
                limit=limit,
                offset=offset,
            )
        # Filter by practitioner if specified
        elif practitioner_id:
            appointments = await self.repository.list_by_practitioner(
                practitioner_id=practitioner_id,
                tenant_id=tenant,
                limit=limit,
                offset=offset,
            )
        # Otherwise list all for tenant
        else:
            appointments = await self.repository.list_by_tenant(
                tenant_id=tenant,
                limit=limit,
                offset=offset,
            )

        # Get total count
        total_count = await self.repository.count_by_tenant(tenant)

        return appointments, total_count
