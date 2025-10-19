"""
Unit tests for JWTTokenService
"""
from datetime import datetime, timedelta
from uuid import uuid4

import jwt
import pytest

from adyela_api_auth.domain.entities.user import User, UserRole, UserStatus
from adyela_api_auth.infrastructure.security.jwt_token_service import JWTTokenService


@pytest.fixture
def token_service():
    """Create JWTTokenService with test secret"""
    return JWTTokenService(
        secret_key="test_secret_key_12345",
        algorithm="HS256",
        access_token_expire_minutes=30,
        refresh_token_expire_days=7,
    )


@pytest.fixture
def sample_user():
    """Create a sample user"""
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


class TestJWTTokenService:
    """Test suite for JWTTokenService"""

    def test_create_access_token(self, token_service, sample_user):
        """Test creating an access token"""
        # Act
        token = token_service.create_access_token(sample_user)

        # Assert
        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

        # Decode and verify payload
        payload = jwt.decode(
            token, "test_secret_key_12345", algorithms=["HS256"]
        )

        assert payload["user_id"] == str(sample_user.id)
        assert payload["email"] == sample_user.email
        assert payload["roles"] == [UserRole.PATIENT.value]
        assert payload["token_type"] == "access"
        assert "exp" in payload
        assert "iat" in payload

    def test_create_refresh_token(self, token_service, sample_user):
        """Test creating a refresh token"""
        # Act
        token = token_service.create_refresh_token(sample_user)

        # Assert
        assert token is not None
        assert isinstance(token, str)

        # Decode and verify payload
        payload = jwt.decode(
            token, "test_secret_key_12345", algorithms=["HS256"]
        )

        assert payload["user_id"] == str(sample_user.id)
        assert payload["token_type"] == "refresh"
        assert "exp" in payload
        assert "iat" in payload
        # Refresh token should not contain sensitive data
        assert "email" not in payload
        assert "roles" not in payload

    def test_create_access_token_with_custom_expiration(
        self, token_service, sample_user
    ):
        """Test creating access token with custom expiration"""
        # Arrange
        custom_expiration = timedelta(minutes=60)

        # Act
        token = token_service.create_access_token(
            sample_user, expires_delta=custom_expiration
        )

        # Assert
        payload = jwt.decode(
            token, "test_secret_key_12345", algorithms=["HS256"]
        )

        exp_datetime = datetime.fromtimestamp(payload["exp"])
        iat_datetime = datetime.fromtimestamp(payload["iat"])
        actual_delta = exp_datetime - iat_datetime

        # Allow 1 second tolerance
        assert abs(actual_delta.total_seconds() - 3600) < 1

    def test_decode_valid_token(self, token_service, sample_user):
        """Test decoding a valid token"""
        # Arrange
        token = token_service.create_access_token(sample_user)

        # Act
        payload = token_service.decode_token(token)

        # Assert
        assert payload["user_id"] == str(sample_user.id)
        assert payload["email"] == sample_user.email
        assert payload["token_type"] == "access"

    def test_decode_expired_token(self, token_service, sample_user):
        """Test decoding an expired token"""
        # Arrange - Create token with expired timestamp
        expired_payload = {
            "user_id": str(sample_user.id),
            "email": sample_user.email,
            "token_type": "access",
            "exp": datetime.utcnow() - timedelta(hours=1),  # Expired
            "iat": datetime.utcnow() - timedelta(hours=2),
        }

        expired_token = jwt.encode(
            expired_payload, "test_secret_key_12345", algorithm="HS256"
        )

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            token_service.decode_token(expired_token)

        assert "expired" in str(exc_info.value).lower()

    def test_decode_invalid_token(self, token_service):
        """Test decoding an invalid token"""
        # Arrange
        invalid_token = "invalid.token.here"

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            token_service.decode_token(invalid_token)

        assert "invalid" in str(exc_info.value).lower()

    def test_decode_token_with_wrong_secret(self, token_service, sample_user):
        """Test decoding a token with wrong secret"""
        # Arrange - Create token with different secret
        wrong_payload = {
            "user_id": str(sample_user.id),
            "email": sample_user.email,
            "token_type": "access",
            "exp": datetime.utcnow() + timedelta(minutes=30),
            "iat": datetime.utcnow(),
        }

        wrong_token = jwt.encode(
            wrong_payload, "wrong_secret_key", algorithm="HS256"
        )

        # Act & Assert
        with pytest.raises(ValueError) as exc_info:
            token_service.decode_token(wrong_token)

        assert "invalid" in str(exc_info.value).lower()

    def test_get_user_id_from_token(self, token_service, sample_user):
        """Test extracting user ID from token"""
        # Arrange
        token = token_service.create_access_token(sample_user)

        # Act
        user_id = token_service.get_user_id_from_token(token)

        # Assert
        assert user_id == sample_user.id

    def test_get_user_id_from_invalid_token(self, token_service):
        """Test extracting user ID from invalid token"""
        # Arrange
        invalid_token = "invalid.token.here"

        # Act & Assert
        with pytest.raises(ValueError):
            token_service.get_user_id_from_token(invalid_token)

    def test_verify_access_token(self, token_service, sample_user):
        """Test verifying an access token"""
        # Arrange
        token = token_service.create_access_token(sample_user)

        # Act
        is_valid = token_service.verify_token(token, token_type="access")

        # Assert
        assert is_valid is True

    def test_verify_refresh_token(self, token_service, sample_user):
        """Test verifying a refresh token"""
        # Arrange
        token = token_service.create_refresh_token(sample_user)

        # Act
        is_valid = token_service.verify_token(token, token_type="refresh")

        # Assert
        assert is_valid is True

    def test_verify_token_with_wrong_type(self, token_service, sample_user):
        """Test verifying token with wrong type"""
        # Arrange
        access_token = token_service.create_access_token(sample_user)

        # Act - Try to verify as refresh token
        is_valid = token_service.verify_token(
            access_token, token_type="refresh"
        )

        # Assert
        assert is_valid is False

    def test_verify_expired_token(self, token_service, sample_user):
        """Test verifying an expired token"""
        # Arrange
        expired_payload = {
            "user_id": str(sample_user.id),
            "token_type": "access",
            "exp": datetime.utcnow() - timedelta(hours=1),
            "iat": datetime.utcnow() - timedelta(hours=2),
        }

        expired_token = jwt.encode(
            expired_payload, "test_secret_key_12345", algorithm="HS256"
        )

        # Act
        is_valid = token_service.verify_token(expired_token, token_type="access")

        # Assert
        assert is_valid is False

    def test_token_contains_tenant_id(self, token_service, sample_user):
        """Test that token contains tenant_id when present"""
        # Arrange
        tenant_id = uuid4()
        sample_user.tenant_id = tenant_id

        # Act
        token = token_service.create_access_token(sample_user)

        # Assert
        payload = jwt.decode(
            token, "test_secret_key_12345", algorithms=["HS256"]
        )

        assert payload["tenant_id"] == str(tenant_id)

    def test_token_without_tenant_id(self, token_service, sample_user):
        """Test that token handles None tenant_id"""
        # Arrange
        sample_user.tenant_id = None

        # Act
        token = token_service.create_access_token(sample_user)

        # Assert
        payload = jwt.decode(
            token, "test_secret_key_12345", algorithms=["HS256"]
        )

        assert payload["tenant_id"] is None
