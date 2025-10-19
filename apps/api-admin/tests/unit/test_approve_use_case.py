"""Unit tests for ApproveProfessionalUseCase."""

import pytest
from unittest.mock import AsyncMock

from adyela_api_admin.application.use_cases.professionals import ApproveProfessionalUseCase
from adyela_api_admin.domain.exceptions import ProfessionalNotFoundError


class TestApproveProfessionalUseCase:
    """Test suite for ApproveProfessionalUseCase."""

    @pytest.fixture
    def mock_professional_repo(self):
        """Mock professional repository."""
        return AsyncMock()

    @pytest.fixture
    def mock_audit_repo(self):
        """Mock audit log repository."""
        return AsyncMock()

    @pytest.fixture
    def use_case(self, mock_professional_repo, mock_audit_repo):
        """Create use case with mocked dependencies."""
        return ApproveProfessionalUseCase(
            professional_repository=mock_professional_repo,
            audit_repository=mock_audit_repo,
        )

    @pytest.mark.asyncio
    async def test_approve_professional_success(
        self, use_case, mock_professional_repo, mock_audit_repo, sample_professional, admin_id
    ):
        """Test successfully approving a professional."""
        # Arrange
        mock_professional_repo.get_by_id.return_value = sample_professional

        def update_side_effect(prof):
            return prof

        mock_professional_repo.update.side_effect = update_side_effect

        # Act
        result = await use_case.execute(
            professional_id=sample_professional.id,
            admin_id=admin_id,
        )

        # Assert
        assert result.status.value == "approved"
        assert result.reviewed_by == admin_id
        mock_professional_repo.get_by_id.assert_called_once()
        mock_professional_repo.update.assert_called_once()
        mock_audit_repo.create.assert_called_once()

    @pytest.mark.asyncio
    async def test_approve_not_found_fails(
        self, use_case, mock_professional_repo, admin_id
    ):
        """Test approving non-existent professional fails."""
        # Arrange
        mock_professional_repo.get_by_id.return_value = None

        # Act & Assert
        with pytest.raises(ProfessionalNotFoundError):
            await use_case.execute(
                professional_id="nonexistent",
                admin_id=admin_id,
            )
