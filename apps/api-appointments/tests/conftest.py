"""
Pytest configuration and shared fixtures for api-appointments tests
"""
from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest

from adyela_api_appointments.config import AppointmentStatus, AppointmentType
from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.value_objects import DateTimeRange, TenantId


@pytest.fixture
def tenant_id() -> TenantId:
    """Create a sample tenant ID"""
    return TenantId(uuid4())


@pytest.fixture
def patient_id() -> str:
    """Create a sample patient ID"""
    return str(uuid4())


@pytest.fixture
def practitioner_id() -> str:
    """Create a sample practitioner ID"""
    return str(uuid4())


@pytest.fixture
def future_time_range() -> DateTimeRange:
    """Create a future time range for appointments"""
    start = datetime.now(UTC) + timedelta(days=1)
    end = start + timedelta(hours=1)
    return DateTimeRange(start=start, end=end)


@pytest.fixture
def sample_appointment(
    tenant_id: TenantId,
    patient_id: str,
    practitioner_id: str,
    future_time_range: DateTimeRange,
) -> Appointment:
    """Create a sample appointment"""
    return Appointment(
        id=str(uuid4()),
        tenant_id=tenant_id,
        patient_id=patient_id,
        practitioner_id=practitioner_id,
        schedule=future_time_range,
        appointment_type=AppointmentType.VIDEO_CALL,
        status=AppointmentStatus.SCHEDULED,
        reason="Annual checkup",
    )


@pytest.fixture
def confirmed_appointment(sample_appointment: Appointment) -> Appointment:
    """Create a confirmed appointment"""
    sample_appointment.confirm()
    return sample_appointment


@pytest.fixture
def overlapping_time_range(future_time_range: DateTimeRange) -> DateTimeRange:
    """Create a time range that overlaps with the future_time_range"""
    # Start 30 minutes into the original appointment
    start = future_time_range.start + timedelta(minutes=30)
    end = start + timedelta(hours=1)
    return DateTimeRange(start=start, end=end)


@pytest.fixture
def non_overlapping_time_range(future_time_range: DateTimeRange) -> DateTimeRange:
    """Create a time range that doesn't overlap"""
    # Start after the original appointment ends
    start = future_time_range.end + timedelta(hours=1)
    end = start + timedelta(hours=1)
    return DateTimeRange(start=start, end=end)
