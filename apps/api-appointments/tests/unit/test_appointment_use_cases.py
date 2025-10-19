"""
Unit tests for appointment use cases (Get, List, Cancel, Confirm, CheckAvailability)
"""
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from unittest.mock import AsyncMock

from adyela_api_appointments.application.use_cases.appointments import (
    CancelAppointmentUseCase,
    CheckAvailabilityUseCase,
    ConfirmAppointmentUseCase,
    GetAppointmentUseCase,
    ListAppointmentsUseCase,
)
from adyela_api_appointments.domain.exceptions import (
    AppointmentNotFoundError,
    BusinessRuleViolationError,
)


class TestGetAppointmentUseCase:
    """Test suite for GetAppointmentUseCase"""

    @pytest.fixture
    def mock_repository(self):
        """Mock appointment repository"""
        return AsyncMock()

    @pytest.fixture
    def use_case(self, mock_repository):
        """Create use case"""
        return GetAppointmentUseCase(repository=mock_repository)

    @pytest.mark.asyncio
    async def test_get_appointment_success(
        self, use_case, mock_repository, tenant_id, sample_appointment
    ):
        """Test successfully getting an appointment"""
        # Arrange
        mock_repository.get_by_id.return_value = sample_appointment

        # Act
        result = await use_case.execute(
            appointment_id=sample_appointment.id,
            tenant_id=tenant_id.value,
        )

        # Assert
        assert result == sample_appointment
        mock_repository.get_by_id.assert_called_once()

    @pytest.mark.asyncio
    async def test_get_appointment_not_found(
        self, use_case, mock_repository, tenant_id
    ):
        """Test getting non-existent appointment raises error"""
        # Arrange
        mock_repository.get_by_id.return_value = None

        # Act & Assert
        with pytest.raises(AppointmentNotFoundError):
            await use_case.execute(
                appointment_id="nonexistent-id",
                tenant_id=tenant_id.value,
            )


class TestListAppointmentsUseCase:
    """Test suite for ListAppointmentsUseCase"""

    @pytest.fixture
    def mock_repository(self):
        """Mock appointment repository"""
        return AsyncMock()

    @pytest.fixture
    def use_case(self, mock_repository):
        """Create use case"""
        return ListAppointmentsUseCase(repository=mock_repository)

    @pytest.mark.asyncio
    async def test_list_all_appointments(
        self, use_case, mock_repository, tenant_id, sample_appointment
    ):
        """Test listing all appointments for a tenant"""
        # Arrange
        mock_repository.list_by_tenant.return_value = [sample_appointment]
        mock_repository.count_by_tenant.return_value = 1

        # Act
        appointments, total = await use_case.execute(
            tenant_id=tenant_id.value,
            limit=20,
            offset=0,
        )

        # Assert
        assert len(appointments) == 1
        assert total == 1
        assert appointments[0] == sample_appointment
        mock_repository.list_by_tenant.assert_called_once()

    @pytest.mark.asyncio
    async def test_list_appointments_by_patient(
        self, use_case, mock_repository, tenant_id, patient_id, sample_appointment
    ):
        """Test listing appointments filtered by patient"""
        # Arrange
        mock_repository.list_by_patient.return_value = [sample_appointment]
        mock_repository.count_by_tenant.return_value = 1

        # Act
        appointments, total = await use_case.execute(
            tenant_id=tenant_id.value,
            patient_id=patient_id,
            limit=20,
            offset=0,
        )

        # Assert
        assert len(appointments) == 1
        mock_repository.list_by_patient.assert_called_once()
        mock_repository.list_by_tenant.assert_not_called()

    @pytest.mark.asyncio
    async def test_list_appointments_by_practitioner(
        self,
        use_case,
        mock_repository,
        tenant_id,
        practitioner_id,
        sample_appointment,
    ):
        """Test listing appointments filtered by practitioner"""
        # Arrange
        mock_repository.list_by_practitioner.return_value = [sample_appointment]
        mock_repository.count_by_tenant.return_value = 1

        # Act
        appointments, total = await use_case.execute(
            tenant_id=tenant_id.value,
            practitioner_id=practitioner_id,
            limit=20,
            offset=0,
        )

        # Assert
        assert len(appointments) == 1
        mock_repository.list_by_practitioner.assert_called_once()


class TestCancelAppointmentUseCase:
    """Test suite for CancelAppointmentUseCase"""

    @pytest.fixture
    def mock_repository(self):
        """Mock appointment repository"""
        return AsyncMock()

    @pytest.fixture
    def mock_event_publisher(self):
        """Mock event publisher"""
        publisher = AsyncMock()
        publisher.publish = AsyncMock(return_value="message-id-123")
        return publisher

    @pytest.fixture
    def use_case(self, mock_repository, mock_event_publisher):
        """Create use case"""
        return CancelAppointmentUseCase(
            repository=mock_repository,
            event_publisher=mock_event_publisher,
        )

    @pytest.mark.asyncio
    async def test_cancel_appointment_success(
        self,
        use_case,
        mock_repository,
        mock_event_publisher,
        tenant_id,
        sample_appointment,
    ):
        """Test successfully canceling an appointment"""
        # Arrange
        mock_repository.get_by_id.return_value = sample_appointment

        def update_side_effect(appointment):
            return appointment

        mock_repository.update.side_effect = update_side_effect

        # Act
        result = await use_case.execute(
            appointment_id=sample_appointment.id,
            tenant_id=tenant_id.value,
        )

        # Assert
        assert result.status.value == "cancelled"
        mock_repository.update.assert_called_once()
        mock_event_publisher.publish.assert_called_once()

    @pytest.mark.asyncio
    async def test_cancel_appointment_not_found(
        self, use_case, mock_repository, tenant_id
    ):
        """Test canceling non-existent appointment"""
        # Arrange
        mock_repository.get_by_id.return_value = None

        # Act & Assert
        with pytest.raises(AppointmentNotFoundError):
            await use_case.execute(
                appointment_id="nonexistent-id",
                tenant_id=tenant_id.value,
            )


class TestConfirmAppointmentUseCase:
    """Test suite for ConfirmAppointmentUseCase"""

    @pytest.fixture
    def mock_repository(self):
        """Mock appointment repository"""
        return AsyncMock()

    @pytest.fixture
    def mock_event_publisher(self):
        """Mock event publisher"""
        publisher = AsyncMock()
        publisher.publish = AsyncMock(return_value="message-id-123")
        return publisher

    @pytest.fixture
    def use_case(self, mock_repository, mock_event_publisher):
        """Create use case"""
        return ConfirmAppointmentUseCase(
            repository=mock_repository,
            event_publisher=mock_event_publisher,
        )

    @pytest.mark.asyncio
    async def test_confirm_appointment_success(
        self,
        use_case,
        mock_repository,
        mock_event_publisher,
        tenant_id,
        sample_appointment,
    ):
        """Test successfully confirming an appointment"""
        # Arrange
        mock_repository.get_by_id.return_value = sample_appointment

        def update_side_effect(appointment):
            return appointment

        mock_repository.update.side_effect = update_side_effect

        # Act
        result = await use_case.execute(
            appointment_id=sample_appointment.id,
            tenant_id=tenant_id.value,
        )

        # Assert
        assert result.status.value == "confirmed"
        mock_repository.update.assert_called_once()
        mock_event_publisher.publish.assert_called_once()


class TestCheckAvailabilityUseCase:
    """Test suite for CheckAvailabilityUseCase"""

    @pytest.fixture
    def mock_repository(self):
        """Mock appointment repository"""
        return AsyncMock()

    @pytest.fixture
    def use_case(self, mock_repository):
        """Create use case"""
        return CheckAvailabilityUseCase(repository=mock_repository)

    @pytest.mark.asyncio
    async def test_check_availability_available(
        self, use_case, mock_repository, tenant_id, practitioner_id
    ):
        """Test checking availability when slot is available"""
        # Arrange
        start_time = datetime.now(UTC) + timedelta(days=1)
        end_time = start_time + timedelta(hours=1)

        # No conflicts
        mock_repository.find_conflicts.return_value = []

        # Act
        is_available = await use_case.execute(
            tenant_id=tenant_id.value,
            practitioner_id=practitioner_id,
            start_time=start_time,
            end_time=end_time,
        )

        # Assert
        assert is_available is True
        mock_repository.find_conflicts.assert_called_once()

    @pytest.mark.asyncio
    async def test_check_availability_not_available(
        self,
        use_case,
        mock_repository,
        tenant_id,
        practitioner_id,
        sample_appointment,
    ):
        """Test checking availability when slot is not available"""
        # Arrange
        start_time = datetime.now(UTC) + timedelta(days=1)
        end_time = start_time + timedelta(hours=1)

        # Return conflicting appointment
        mock_repository.find_conflicts.return_value = [sample_appointment]

        # Act
        is_available = await use_case.execute(
            tenant_id=tenant_id.value,
            practitioner_id=practitioner_id,
            start_time=start_time,
            end_time=end_time,
        )

        # Assert
        assert is_available is False
