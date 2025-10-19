"""
Unit tests for RegisterUserUseCase
"""
from datetime import datetime
from uuid import uuid4

import pytest
from unittest.mock import AsyncMock, MagicMock

from adyela_api_auth.application.use_cases.register_user import RegisterUserUseCase
from adyela_api_auth.domain.entities.user import User, UserRole, UserStatus


@pytest.fixture
def mock_user_repository():
    """Mock user repository"""
    repo = AsyncMock()
    repo.exists_by_email = AsyncMock(return_value=False)
    repo.create = AsyncMock()
    return repo


@pytest.fixture
def mock_auth_service():
    """Mock Firebase auth service"""
    service = AsyncMock()
    service.create_user_with_email_password = AsyncMock()
    service.send_email_verification = AsyncMock(return_value=True)
    return service


@pytest.fixture
def mock_token_service():
    """Mock JWT token service"""
    service = MagicMock()
    service.create_access_token = MagicMock(return_value="access_token_123")
    service.create_refresh_token = MagicMock(return_value="refresh_token_456")
    return service


@pytest.fixture
def register_use_case(mock_user_repository, mock_auth_service, mock_token_service):
    """Create RegisterUserUseCase with mocked dependencies"""
    return RegisterUserUseCase(
        user_repository=mock_user_repository,
        auth_service=mock_auth_service,
        token_service=mock_token_service,
    )


class TestRegisterUserUseCase:
    """Test suite for RegisterUserUseCase"""

    @pytest.mark.asyncio
    async def test_register_user_success(
        self,
        register_use_case,
        mock_user_repository,
        mock_auth_service,
        mock_token_service,
    ):
        """Test successful user registration"""
        # Arrange
        email = "patient@example.com"
        password = "SecurePass123!"
        full_name = "John Doe"
        role = UserRole.PATIENT

        firebase_uid = "firebase_abc123"
        mock_auth_service.create_user_with_email_password.return_value = {
            "firebase_uid": firebase_uid,
            "id_token": "id_token_123",
            "refresh_token": "firebase_refresh_123",
            "expires_in": 3600,
            "email": email,
        }

        def create_user_side_effect(user):
            """Side effect to return the created user"""
            return user

        mock_user_repository.create.side_effect = create_user_side_effect

        # Act
        result = await register_use_case.execute(
            email=email,
            password=password,
            full_name=full_name,
            role=role,
        )

        # Assert
        assert result is not None
        assert result["user"]["email"] == email
        assert result["user"]["full_name"] == full_name
        assert result["user"]["roles"] == [role.value]
        assert result["user"]["status"] == UserStatus.PENDING_VERIFICATION.value
        assert result["access_token"] == "access_token_123"
        assert result["refresh_token"] == "refresh_token_456"
        assert result["token_type"] == "Bearer"

        # Verify interactions
        mock_user_repository.exists_by_email.assert_called_once_with(email)
        mock_auth_service.create_user_with_email_password.assert_called_once_with(
            email=email, password=password
        )
        mock_user_repository.create.assert_called_once()
        mock_token_service.create_access_token.assert_called_once()
        mock_token_service.create_refresh_token.assert_called_once()

    @pytest.mark.asyncio
    async def test_register_user_email_already_exists(
        self,
        register_use_case,
        mock_user_repository,
    ):
        """Test registration with existing email"""
        # Arrange
        email = "existing@example.com"
        password = "SecurePass123!"
        full_name = "Jane Doe"

        # Mock: Email already exists
        mock_user_repository.exists_by_email.return_value = True

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await register_use_case.execute(
                email=email,
                password=password,
                full_name=full_name,
                role=UserRole.PATIENT,
            )

        assert "already exists" in str(exc_info.value).lower()
        mock_user_repository.exists_by_email.assert_called_once_with(email)

    @pytest.mark.asyncio
    async def test_register_user_firebase_error(
        self,
        register_use_case,
        mock_user_repository,
        mock_auth_service,
    ):
        """Test registration when Firebase returns an error"""
        # Arrange
        email = "test@example.com"
        password = "SecurePass123!"
        full_name = "Test User"

        mock_user_repository.exists_by_email.return_value = False
        mock_auth_service.create_user_with_email_password.side_effect = ValueError(
            "WEAK_PASSWORD"
        )

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await register_use_case.execute(
                email=email,
                password=password,
                full_name=full_name,
                role=UserRole.PATIENT,
            )

        assert "WEAK_PASSWORD" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_register_professional(
        self,
        register_use_case,
        mock_user_repository,
        mock_auth_service,
        mock_token_service,
    ):
        """Test registration with professional role"""
        # Arrange
        email = "doctor@example.com"
        password = "SecurePass123!"
        full_name = "Dr. Smith"
        role = UserRole.PROFESSIONAL

        firebase_uid = "firebase_prof_123"
        mock_auth_service.create_user_with_email_password.return_value = {
            "firebase_uid": firebase_uid,
            "id_token": "id_token_prof",
            "refresh_token": "firebase_refresh_prof",
            "expires_in": 3600,
            "email": email,
        }

        def create_user_side_effect(user):
            return user

        mock_user_repository.create.side_effect = create_user_side_effect

        # Act
        result = await register_use_case.execute(
            email=email,
            password=password,
            full_name=full_name,
            role=role,
        )

        # Assert
        assert result["user"]["roles"] == [UserRole.PROFESSIONAL.value]
        assert result["user"]["email"] == email

    @pytest.mark.asyncio
    async def test_register_user_email_verification_fails(
        self,
        register_use_case,
        mock_user_repository,
        mock_auth_service,
        mock_token_service,
    ):
        """Test registration continues even if email verification fails"""
        # Arrange
        email = "test@example.com"
        password = "SecurePass123!"
        full_name = "Test User"

        firebase_uid = "firebase_123"
        mock_auth_service.create_user_with_email_password.return_value = {
            "firebase_uid": firebase_uid,
            "id_token": "id_token_123",
            "refresh_token": "firebase_refresh_123",
            "expires_in": 3600,
            "email": email,
        }

        # Email verification fails
        mock_auth_service.send_email_verification.side_effect = Exception(
            "Email service unavailable"
        )

        def create_user_side_effect(user):
            return user

        mock_user_repository.create.side_effect = create_user_side_effect

        # Act - Should not raise exception
        result = await register_use_case.execute(
            email=email,
            password=password,
            full_name=full_name,
            role=UserRole.PATIENT,
        )

        # Assert - Registration completes successfully
        assert result is not None
        assert result["user"]["email"] == email
        assert result["access_token"] == "access_token_123"
