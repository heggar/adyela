"""Unit tests for Professional entity."""

import pytest

from adyela_api_admin.config import ProfessionalStatus
from adyela_api_admin.domain.exceptions import InvalidStatusTransitionError


class TestProfessionalEntity:
    """Test suite for Professional entity."""

    def test_approve_pending_professional(self, sample_professional, admin_id):
        """Test approving a pending professional."""
        # Arrange
        assert sample_professional.status == ProfessionalStatus.PENDING_VERIFICATION

        # Act
        sample_professional.approve(admin_id)

        # Assert
        assert sample_professional.status == ProfessionalStatus.APPROVED
        assert sample_professional.reviewed_by == admin_id
        assert sample_professional.reviewed_at is not None

    def test_approve_already_approved_fails(self, sample_professional, admin_id):
        """Test that approving already approved professional fails."""
        # Arrange
        sample_professional.approve(admin_id)
        assert sample_professional.status == ProfessionalStatus.APPROVED

        # Act & Assert
        with pytest.raises(InvalidStatusTransitionError):
            sample_professional.approve(admin_id)

    def test_reject_pending_professional(self, sample_professional, admin_id):
        """Test rejecting a pending professional."""
        # Arrange
        reason = "Incomplete documentation"

        # Act
        sample_professional.reject(admin_id, reason)

        # Assert
        assert sample_professional.status == ProfessionalStatus.REJECTED
        assert sample_professional.reviewed_by == admin_id
        assert sample_professional.rejection_reason == reason
        assert sample_professional.reviewed_at is not None

    def test_suspend_approved_professional(self, sample_professional, admin_id):
        """Test suspending an approved professional."""
        # Arrange
        sample_professional.approve(admin_id)
        reason = "License expired"

        # Act
        sample_professional.suspend(admin_id, reason)

        # Assert
        assert sample_professional.status == ProfessionalStatus.SUSPENDED
        assert sample_professional.rejection_reason == reason

    def test_suspend_pending_fails(self, sample_professional, admin_id):
        """Test that suspending pending professional fails."""
        # Act & Assert
        with pytest.raises(InvalidStatusTransitionError):
            sample_professional.suspend(admin_id, "reason")

    def test_to_dict(self, sample_professional):
        """Test converting professional to dictionary."""
        # Act
        data = sample_professional.to_dict()

        # Assert
        assert data["id"] == sample_professional.id
        assert data["email"] == sample_professional.email
        assert data["status"] == ProfessionalStatus.PENDING_VERIFICATION.value

    def test_from_dict(self, sample_professional):
        """Test creating professional from dictionary."""
        # Arrange
        data = sample_professional.to_dict()

        # Act
        restored = Professional.from_dict(data)

        # Assert
        assert restored.id == sample_professional.id
        assert restored.email == sample_professional.email
        assert restored.status == sample_professional.status
