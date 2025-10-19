"""Pytest configuration and shared fixtures."""

from datetime import UTC, datetime
from uuid import uuid4

import pytest

from adyela_api_admin.config import ProfessionalStatus
from adyela_api_admin.domain.entities import Professional


@pytest.fixture
def sample_professional() -> Professional:
    """Create a sample pending professional."""
    return Professional(
        id=str(uuid4()),
        email="doctor@example.com",
        full_name="Dr. John Smith",
        specialty="Cardiology",
        license_number="MED-12345",
        status=ProfessionalStatus.PENDING_VERIFICATION,
        submitted_at=datetime.now(UTC),
    )


@pytest.fixture
def admin_id() -> str:
    """Sample admin ID."""
    return str(uuid4())
