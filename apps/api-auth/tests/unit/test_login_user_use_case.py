"""
Unit tests for LoginUserUseCase
"""
from datetime import datetime
from uuid import uuid4

import pytest
from unittest.mock import AsyncMock, MagicMock

from adyela_api_auth.application.use_cases.login_user import LoginUserUseCase
from adyela_api_auth.domain.entities.user import User, UserRole, UserStatus


@pytest.fixture
def mock_user_repository():
    """Mock user repository"""
    repo = AsyncMock()
    return repo


@pytest.fixture
def mock_auth_service():
    """Mock Firebase auth service"""
    service = AsyncMock()
    return service


@pytest.fixture
def mock_token_service():
    """Mock JWT token service"""
    service = MagicMock()
    service.create_access_token = MagicMock(return_value="access_token_123")
    service.create_refresh_token = MagicMock(return_value="refresh_token_456")
    return service


@pytest.fixture
def login_use_case(mock_user_repository, mock_auth_service, mock_token_service):
    """Create LoginUserUseCase with mocked dependencies"""
    return LoginUserUseCase(
        user_repository=mock_user_repository,
        auth_service=mock_auth_service,
        token_service=mock_token_service,
    )


@pytest.fixture
def sample_user():
    """Create a sample active user"""
    return User(
        id=uuid4(),
        email="patient@example.com",
        email_verified=True,
        full_name="John Doe",
        roles=[UserRole.PATIENT],
        status=UserStatus.ACTIVE,
        firebase_uid="firebase_123",
        created_at=datetime.utcnow(),
        updated_at=datetime.utcnow(),
    )


class TestLoginUserUseCase:
    """Test suite for LoginUserUseCase"""

    @pytest.mark.asyncio
    async def test_login_success(
        self,
        login_use_case,
        mock_user_repository,
        mock_auth_service,
        mock_token_service,
        sample_user,
    ):
        """Test successful user login"""
        # Arrange
        email = "patient@example.com"
        password = "SecurePass123!"

        mock_auth_service.sign_in_with_email_password.return_value = {
            "firebase_uid": "firebase_123",
            "id_token": "firebase_id_token",
            "refresh_token": "firebase_refresh",
            "expires_in": 3600,
            "email": email,
        }

        mock_user_repository.get_by_email.return_value = sample_user

        async def update_side_effect(user):
            return user

        mock_user_repository.update.side_effect = update_side_effect

        # Act
        result = await login_use_case.execute(email=email, password=password)

        # Assert
        assert result is not None
        assert result["user"]["email"] == email
        assert result["user"]["full_name"] == "John Doe"
        assert result["user"]["roles"] == [UserRole.PATIENT.value]
        assert result["user"]["status"] == UserStatus.ACTIVE.value
        assert result["access_token"] == "access_token_123"
        assert result["refresh_token"] == "refresh_token_456"
        assert result["token_type"] == "Bearer"

        # Verify interactions
        mock_auth_service.sign_in_with_email_password.assert_called_once_with(
            email=email, password=password
        )
        mock_user_repository.get_by_email.assert_called_once_with(email)
        mock_user_repository.update.assert_called_once()
        mock_token_service.create_access_token.assert_called_once()
        mock_token_service.create_refresh_token.assert_called_once()

    @pytest.mark.asyncio
    async def test_login_invalid_credentials(
        self,
        login_use_case,
        mock_auth_service,
    ):
        """Test login with invalid credentials"""
        # Arrange
        email = "patient@example.com"
        password = "WrongPassword"

        mock_auth_service.sign_in_with_email_password.side_effect = ValueError(
            "Invalid email or password"
        )

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await login_use_case.execute(email=email, password=password)

        assert "Invalid email or password" in str(exc_info.value)
        mock_auth_service.sign_in_with_email_password.assert_called_once()

    @pytest.mark.asyncio
    async def test_login_user_not_in_database(
        self,
        login_use_case,
        mock_user_repository,
        mock_auth_service,
    ):
        """Test login when user authenticated but not in our database"""
        # Arrange
        email = "orphan@example.com"
        password = "SecurePass123!"

        mock_auth_service.sign_in_with_email_password.return_value = {
            "firebase_uid": "firebase_orphan",
            "id_token": "firebase_id_token",
            "refresh_token": "firebase_refresh",
            "expires_in": 3600,
            "email": email,
        }

        # User not found in database
        mock_user_repository.get_by_email.return_value = None

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await login_use_case.execute(email=email, password=password)

        assert "not found in system" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_login_suspended_user(
        self,
        login_use_case,
        mock_user_repository,
        mock_auth_service,
        sample_user,
    ):
        """Test login with suspended user account"""
        # Arrange
        email = "suspended@example.com"
        password = "SecurePass123!"

        suspended_user = sample_user
        suspended_user.status = UserStatus.SUSPENDED

        mock_auth_service.sign_in_with_email_password.return_value = {
            "firebase_uid": "firebase_123",
            "id_token": "firebase_id_token",
            "refresh_token": "firebase_refresh",
            "expires_in": 3600,
            "email": email,
        }

        mock_user_repository.get_by_email.return_value = suspended_user

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await login_use_case.execute(email=email, password=password)

        assert "suspended" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_login_inactive_user(
        self,
        login_use_case,
        mock_user_repository,
        mock_auth_service,
        sample_user,
    ):
        """Test login with inactive user account"""
        # Arrange
        email = "inactive@example.com"
        password = "SecurePass123!"

        inactive_user = sample_user
        inactive_user.status = UserStatus.INACTIVE

        mock_auth_service.sign_in_with_email_password.return_value = {
            "firebase_uid": "firebase_123",
            "id_token": "firebase_id_token",
            "refresh_token": "firebase_refresh",
            "expires_in": 3600,
            "email": email,
        }

        mock_user_repository.get_by_email.return_value = inactive_user

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            await login_use_case.execute(email=email, password=password)

        assert "inactive" in str(exc_info.value).lower()

    @pytest.mark.asyncio
    async def test_login_updates_last_login(
        self,
        login_use_case,
        mock_user_repository,
        mock_auth_service,
        sample_user,
    ):
        """Test that login updates last_login_at timestamp"""
        # Arrange
        email = "patient@example.com"
        password = "SecurePass123!"

        original_last_login = sample_user.last_login_at

        mock_auth_service.sign_in_with_email_password.return_value = {
            "firebase_uid": "firebase_123",
            "id_token": "firebase_id_token",
            "refresh_token": "firebase_refresh",
            "expires_in": 3600,
            "email": email,
        }

        mock_user_repository.get_by_email.return_value = sample_user

        updated_user = None

        async def capture_updated_user(user):
            nonlocal updated_user
            updated_user = user
            return user

        mock_user_repository.update.side_effect = capture_updated_user

        # Act
        await login_use_case.execute(email=email, password=password)

        # Assert
        assert updated_user is not None
        assert updated_user.last_login_at is not None
        assert updated_user.last_login_at != original_last_login
        mock_user_repository.update.assert_called_once()
