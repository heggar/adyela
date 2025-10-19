"""Check availability use case."""

from datetime import datetime
from uuid import UUID

from adyela_api_appointments.application.ports import AppointmentRepository
from adyela_api_appointments.domain.value_objects import DateTimeRange, TenantId


class CheckAvailabilityUseCase:
    """Use case for checking practitioner availability."""

    def __init__(self, repository: AppointmentRepository) -> None:
        """Initialize use case."""
        self.repository = repository

    async def execute(
        self,
        tenant_id: UUID,
        practitioner_id: str,
        start_time: datetime,
        end_time: datetime,
    ) -> bool:
        """
        Check if a practitioner is available in a time slot.

        Args:
            tenant_id: Tenant identifier
            practitioner_id: Practitioner identifier
            start_time: Start time to check
            end_time: End time to check

        Returns:
            True if available, False if there are conflicts
        """
        tenant = TenantId(tenant_id)
        time_range = DateTimeRange(start=start_time, end=end_time)

        # Find any conflicting appointments
        conflicts = await self.repository.find_conflicts(
            practitioner_id=practitioner_id,
            tenant_id=tenant,
            time_range=time_range,
        )

        # Available if no conflicts
        return len(conflicts) == 0
