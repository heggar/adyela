"""
Unit tests for CreateAppointmentUseCase
"""
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from unittest.mock import AsyncMock, MagicMock

from adyela_api_appointments.application.use_cases.appointments import (
    CreateAppointmentUseCase,
)
from adyela_api_appointments.config import AppointmentType
from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.exceptions import AppointmentConflictError


class TestCreateAppointmentUseCase:
    """Test suite for CreateAppointmentUseCase"""

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
        """Create use case with mocked dependencies"""
        return CreateAppointmentUseCase(
            repository=mock_repository,
            event_publisher=mock_event_publisher,
        )

    @pytest.mark.asyncio
    async def test_create_appointment_success(
        self,
        use_case,
        mock_repository,
        mock_event_publisher,
        tenant_id,
        patient_id,
        practitioner_id,
    ):
        """Test successfully creating an appointment"""
        # Arrange
        start_time = datetime.now(UTC) + timedelta(days=1)
        end_time = start_time + timedelta(hours=1)

        # No conflicts
        mock_repository.find_conflicts.return_value = []

        # Repository returns the created appointment
        def create_side_effect(appointment):
            return appointment

        mock_repository.create.side_effect = create_side_effect

        # Act
        appointment = await use_case.execute(
            tenant_id=tenant_id.value,
            patient_id=patient_id,
            practitioner_id=practitioner_id,
            start_time=start_time,
            end_time=end_time,
            appointment_type=AppointmentType.VIDEO_CALL,
            reason="Annual checkup",
        )

        # Assert
        assert appointment is not None
        assert appointment.patient_id == patient_id
        assert appointment.practitioner_id == practitioner_id
        assert appointment.reason == "Annual checkup"

        # Verify conflict check was called
        mock_repository.find_conflicts.assert_called_once()

        # Verify repository create was called
        mock_repository.create.assert_called_once()

        # Verify event was published
        mock_event_publisher.publish.assert_called_once()
        call_args = mock_event_publisher.publish.call_args
        assert call_args[1]["event_type"] == "AppointmentCreated"
        assert "appointment_id" in call_args[1]["data"]

    @pytest.mark.asyncio
    async def test_create_appointment_with_conflict_fails(
        self,
        use_case,
        mock_repository,
        mock_event_publisher,
        tenant_id,
        patient_id,
        practitioner_id,
        sample_appointment,
    ):
        """Test that creating appointment with conflict raises error"""
        # Arrange
        start_time = datetime.now(UTC) + timedelta(days=1)
        end_time = start_time + timedelta(hours=1)

        # Return existing conflicting appointment
        mock_repository.find_conflicts.return_value = [sample_appointment]

        # Act & Assert
        with pytest.raises(AppointmentConflictError) as exc_info:
            await use_case.execute(
                tenant_id=tenant_id.value,
                patient_id=patient_id,
                practitioner_id=practitioner_id,
                start_time=start_time,
                end_time=end_time,
                appointment_type=AppointmentType.IN_PERSON,
            )

        assert "conflict" in str(exc_info.value).lower()

        # Verify event was NOT published
        mock_event_publisher.publish.assert_not_called()

    @pytest.mark.asyncio
    async def test_create_appointment_publishes_correct_event(
        self,
        use_case,
        mock_repository,
        mock_event_publisher,
        tenant_id,
        patient_id,
        practitioner_id,
    ):
        """Test that correct event is published after creation"""
        # Arrange
        start_time = datetime.now(UTC) + timedelta(days=2)
        end_time = start_time + timedelta(hours=1)

        mock_repository.find_conflicts.return_value = []

        def create_side_effect(appointment):
            return appointment

        mock_repository.create.side_effect = create_side_effect

        # Act
        appointment = await use_case.execute(
            tenant_id=tenant_id.value,
            patient_id=patient_id,
            practitioner_id=practitioner_id,
            start_time=start_time,
            end_time=end_time,
            appointment_type=AppointmentType.PHONE_CALL,
        )

        # Assert
        mock_event_publisher.publish.assert_called_once()
        call_kwargs = mock_event_publisher.publish.call_args.kwargs

        assert call_kwargs["event_type"] == "AppointmentCreated"
        assert call_kwargs["data"]["appointment_id"] == appointment.id
        assert call_kwargs["data"]["tenant_id"] == str(tenant_id)
        assert call_kwargs["data"]["patient_id"] == patient_id
        assert call_kwargs["data"]["practitioner_id"] == practitioner_id
        assert call_kwargs["data"]["appointment_type"] == AppointmentType.PHONE_CALL.value
