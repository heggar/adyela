"""
Unit tests for ValidateTokenUseCase and RefreshTokenUseCase
"""
from uuid import uuid4

import pytest
from unittest.mock import AsyncMock, MagicMock

from adyela_api_auth.application.use_cases.validate_token import ValidateTokenUseCase
from adyela_api_auth.application.use_cases.refresh_token import RefreshTokenUseCase
from adyela_api_auth.domain.entities.user import UserStatus


class TestValidateTokenUseCase:
    """Test suite for ValidateTokenUseCase"""

    @pytest.fixture
    def mock_user_repository(self):
        """Mock user repository"""
        return AsyncMock()

    @pytest.fixture
    def mock_token_service(self):
        """Mock JWT token service"""
        return MagicMock()

    @pytest.fixture
    def validate_token_use_case(
        self, mock_user_repository, mock_token_service
    ):
        """Create ValidateTokenUseCase with mocked dependencies"""
        return ValidateTokenUseCase(
            user_repository=mock_user_repository,
            token_service=mock_token_service,
        )

    @pytest.mark.asyncio
    async def test_validate_valid_token(
        self,
        validate_token_use_case,
        mock_user_repository,
        mock_token_service,
        sample_patient,
    ):
        """Test validating a valid token"""
        # Arrange
        token = "valid_token_123"
        user_id = sample_patient.id

        mock_token_service.decode_token.return_value = {
            "user_id": str(user_id),
            "email": sample_patient.email,
            "roles": ["patient"],
            "token_type": "access",
        }

        mock_user_repository.get_by_id.return_value = sample_patient

        # Act
        result = await validate_token_use_case.execute(token=token)

        # Assert
        assert result["valid"] is True
        assert result["user"]["id"] == str(user_id)
        assert result["user"]["email"] == sample_patient.email
        assert "claims" in result

        mock_token_service.decode_token.assert_called_once_with(token)
        mock_user_repository.get_by_id.assert_called_once_with(user_id)

    @pytest.mark.asyncio
    async def test_validate_token_user_not_found(
        self,
        validate_token_use_case,
        mock_user_repository,
        mock_token_service,
    ):
        """Test validating token when user not found"""
        # Arrange
        token = "valid_token_123"
        user_id = uuid4()

        mock_token_service.decode_token.return_value = {
            "user_id": str(user_id),
            "token_type": "access",
        }

        mock_user_repository.get_by_id.return_value = None

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await validate_token_use_case.execute(token=token)

        assert "not found" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_validate_token_inactive_user(
        self,
        validate_token_use_case,
        mock_user_repository,
        mock_token_service,
        sample_patient,
    ):
        """Test validating token for inactive user"""
        # Arrange
        token = "valid_token_123"
        inactive_user = sample_patient
        inactive_user.status = UserStatus.INACTIVE

        mock_token_service.decode_token.return_value = {
            "user_id": str(inactive_user.id),
            "token_type": "access",
        }

        mock_user_repository.get_by_id.return_value = inactive_user

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await validate_token_use_case.execute(token=token)

        assert "not active" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_validate_invalid_token(
        self,
        validate_token_use_case,
        mock_token_service,
    ):
        """Test validating an invalid token"""
        # Arrange
        token = "invalid_token"

        mock_token_service.decode_token.side_effect = ValueError(
            "Token is invalid or expired"
        )

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await validate_token_use_case.execute(token=token)

        assert "invalid" in str(exc_info.value).lower()


class TestRefreshTokenUseCase:
    """Test suite for RefreshTokenUseCase"""

    @pytest.fixture
    def mock_user_repository(self):
        """Mock user repository"""
        return AsyncMock()

    @pytest.fixture
    def mock_token_service(self):
        """Mock JWT token service"""
        service = MagicMock()
        service.verify_token = MagicMock(return_value=True)
        service.get_user_id_from_token = MagicMock()
        service.create_access_token = MagicMock(return_value="new_access_token_123")
        return service

    @pytest.fixture
    def refresh_token_use_case(
        self, mock_user_repository, mock_token_service
    ):
        """Create RefreshTokenUseCase with mocked dependencies"""
        return RefreshTokenUseCase(
            user_repository=mock_user_repository,
            token_service=mock_token_service,
        )

    @pytest.mark.asyncio
    async def test_refresh_token_success(
        self,
        refresh_token_use_case,
        mock_user_repository,
        mock_token_service,
        sample_patient,
    ):
        """Test successful token refresh"""
        # Arrange
        refresh_token = "refresh_token_123"
        user_id = sample_patient.id

        mock_token_service.get_user_id_from_token.return_value = user_id
        mock_user_repository.get_by_id.return_value = sample_patient

        # Act
        result = await refresh_token_use_case.execute(
            refresh_token=refresh_token
        )

        # Assert
        assert result["access_token"] == "new_access_token_123"
        assert result["token_type"] == "Bearer"

        mock_token_service.verify_token.assert_called_once_with(
            refresh_token, token_type="refresh"
        )
        mock_user_repository.get_by_id.assert_called_once_with(user_id)
        mock_token_service.create_access_token.assert_called_once()

    @pytest.mark.asyncio
    async def test_refresh_token_invalid(
        self,
        refresh_token_use_case,
        mock_token_service,
    ):
        """Test refresh with invalid token"""
        # Arrange
        refresh_token = "invalid_refresh_token"

        mock_token_service.verify_token.return_value = False

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await refresh_token_use_case.execute(refresh_token=refresh_token)

        assert "invalid" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_refresh_token_user_not_found(
        self,
        refresh_token_use_case,
        mock_user_repository,
        mock_token_service,
    ):
        """Test refresh when user not found"""
        # Arrange
        refresh_token = "refresh_token_123"
        user_id = uuid4()

        mock_token_service.get_user_id_from_token.return_value = user_id
        mock_user_repository.get_by_id.return_value = None

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await refresh_token_use_case.execute(refresh_token=refresh_token)

        assert "not found" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_refresh_token_inactive_user(
        self,
        refresh_token_use_case,
        mock_user_repository,
        mock_token_service,
        sample_patient,
    ):
        """Test refresh for inactive user"""
        # Arrange
        refresh_token = "refresh_token_123"
        inactive_user = sample_patient
        inactive_user.status = UserStatus.SUSPENDED

        mock_token_service.get_user_id_from_token.return_value = inactive_user.id
        mock_user_repository.get_by_id.return_value = inactive_user

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await refresh_token_use_case.execute(refresh_token=refresh_token)

        assert "not active" in str(exc_info.value).lower()
