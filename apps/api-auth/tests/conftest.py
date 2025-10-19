"""
Pytest configuration and shared fixtures for api-auth tests
"""
from datetime import datetime
from uuid import uuid4

import pytest

from adyela_api_auth.domain.entities.user import User, UserRole, UserStatus


@pytest.fixture
def sample_patient():
    """Create a sample patient user"""
    return User(
        id=uuid4(),
        email="patient@example.com",
        email_verified=True,
        full_name="John Patient",
        roles=[UserRole.PATIENT],
        status=UserStatus.ACTIVE,
        firebase_uid="firebase_patient_123",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )


@pytest.fixture
def sample_professional():
    """Create a sample professional user"""
    return User(
        id=uuid4(),
        email="doctor@example.com",
        email_verified=True,
        full_name="Dr. Professional",
        roles=[UserRole.PROFESSIONAL],
        status=UserStatus.ACTIVE,
        firebase_uid="firebase_prof_123",
        tenant_id=uuid4(),  # Professionals have tenant_id
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )


@pytest.fixture
def sample_admin():
    """Create a sample admin user"""
    return User(
        id=uuid4(),
        email="admin@example.com",
        email_verified=True,
        full_name="Admin User",
        roles=[UserRole.ADMIN],
        status=UserStatus.ACTIVE,
        firebase_uid="firebase_admin_123",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )


@pytest.fixture
def pending_verification_user():
    """Create a user pending verification"""
    return User(
        id=uuid4(),
        email="pending@example.com",
        email_verified=False,
        full_name="Pending User",
        roles=[UserRole.PATIENT],
        status=UserStatus.PENDING_VERIFICATION,
        firebase_uid="firebase_pending_123",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )


@pytest.fixture
def suspended_user():
    """Create a suspended user"""
    return User(
        id=uuid4(),
        email="suspended@example.com",
        email_verified=True,
        full_name="Suspended User",
        roles=[UserRole.PATIENT],
        status=UserStatus.SUSPENDED,
        firebase_uid="firebase_suspended_123",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )
