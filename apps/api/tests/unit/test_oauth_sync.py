"""Unit tests for OAuth synchronization endpoint."""

from unittest.mock import AsyncMock, Mock, patch

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from adyela_api.infrastructure.services.auth.firebase_auth_service import FirebaseAuthService
from adyela_api.main import app
from adyela_api.presentation.api.v1.endpoints.auth import sync_oauth_user
from adyela_api.presentation.schemas.auth import OAuthSyncRequest, OAuthUserData


class TestOAuthSync:
    """Test cases for OAuth synchronization."""

    @pytest.fixture
    def client(self):
        """Create test client."""
        return TestClient(app)

    @pytest.fixture
    def mock_auth_service(self):
        """Create mock auth service."""
        service = Mock(spec=FirebaseAuthService)
        service.verify_token = AsyncMock()
        return service

    @pytest.fixture
    def valid_oauth_request(self):
        """Create valid OAuth sync request."""
        return OAuthSyncRequest(
            user_data=OAuthUserData(
                uid="test-uid-123",
                email="test@example.com",
                displayName="Test User",
                photoURL="https://example.com/photo.jpg",
                provider="google",
                emailVerified=True,
            )
        )

    @pytest.fixture
    def valid_firebase_claims(self):
        """Create valid Firebase claims."""
        return {
            "uid": "test-uid-123",
            "email": "test@example.com",
            "name": "Test User",
            "email_verified": True,
            "tenant_id": "default",
            "roles": ["patient"],
            "firebase": {"sign_in_provider": "google.com"},
        }

    @pytest.mark.asyncio
    async def test_sync_oauth_user_success(
        self, mock_auth_service, valid_oauth_request, valid_firebase_claims
    ):
        """Test successful OAuth user synchronization."""
        # Arrange
        mock_auth_service.verify_token.return_value = valid_firebase_claims
        authorization = "Bearer valid-firebase-token"

        # Act
        with patch("adyela_api.presentation.api.v1.endpoints.auth.datetime") as mock_datetime:
            mock_datetime.utcnow.return_value.isoformat.return_value = "2024-01-01T00:00:00"

            result = await sync_oauth_user(
                request=valid_oauth_request,
                authorization=authorization,
                auth_service=mock_auth_service,
            )

        # Assert
        assert result.tenant_id == "default"
        assert result.roles == ["patient"]
        assert result.user["uid"] == "test-uid-123"
        assert result.user["email"] == "test@example.com"
        assert result.user["displayName"] == "Test User"
        assert result.user["provider"] == "google"
        assert result.user["emailVerified"] is True
        mock_auth_service.verify_token.assert_called_once_with("valid-firebase-token")

    @pytest.mark.asyncio
    async def test_sync_oauth_user_invalid_token(self, mock_auth_service, valid_oauth_request):
        """Test OAuth sync with invalid token."""
        # Arrange
        mock_auth_service.verify_token.side_effect = Exception("Invalid token")
        authorization = "Bearer invalid-token"

        # Act & Assert
        with pytest.raises(HTTPException) as exc_info:
            await sync_oauth_user(
                request=valid_oauth_request,
                authorization=authorization,
                auth_service=mock_auth_service,
            )

        assert exc_info.value.status_code == 401
        assert "Authentication failed" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_sync_oauth_user_missing_email(self, mock_auth_service, valid_firebase_claims):
        """Test OAuth sync with missing email."""
        # Arrange
        oauth_request = OAuthSyncRequest(
            user_data=OAuthUserData(
                uid="test-uid-123",
                email=None,
                displayName="Test User",
                photoURL=None,
                provider="google",
                emailVerified=False,
            )
        )
        valid_firebase_claims["email"] = "fallback@example.com"
        mock_auth_service.verify_token.return_value = valid_firebase_claims
        authorization = "Bearer valid-token"

        # Act
        with patch("adyela_api.presentation.api.v1.endpoints.auth.datetime") as mock_datetime:
            mock_datetime.utcnow.return_value.isoformat.return_value = "2024-01-01T00:00:00"

            result = await sync_oauth_user(
                request=oauth_request, authorization=authorization, auth_service=mock_auth_service
            )

        # Assert
        assert result.user["email"] == "fallback@example.com"

    @pytest.mark.asyncio
    async def test_sync_oauth_user_default_tenant(self, mock_auth_service, valid_oauth_request):
        """Test OAuth sync with default tenant assignment."""
        # Arrange
        claims_without_tenant = {
            "uid": "test-uid-123",
            "email": "test@example.com",
            "name": "Test User",
            "email_verified": True,
            "roles": ["patient"],
            "firebase": {"sign_in_provider": "google.com"},
        }
        mock_auth_service.verify_token.return_value = claims_without_tenant
        authorization = "Bearer valid-token"

        # Act
        with patch("adyela_api.presentation.api.v1.endpoints.auth.datetime") as mock_datetime:
            mock_datetime.utcnow.return_value.isoformat.return_value = "2024-01-01T00:00:00"

            result = await sync_oauth_user(
                request=valid_oauth_request,
                authorization=authorization,
                auth_service=mock_auth_service,
            )

        # Assert
        assert result.tenant_id == "default"
        assert result.user["tenant_id"] == "default"

    @pytest.mark.asyncio
    async def test_sync_oauth_user_default_roles(self, mock_auth_service, valid_oauth_request):
        """Test OAuth sync with default role assignment."""
        # Arrange
        claims_without_roles = {
            "uid": "test-uid-123",
            "email": "test@example.com",
            "name": "Test User",
            "email_verified": True,
            "tenant_id": "default",
            "firebase": {"sign_in_provider": "google.com"},
        }
        mock_auth_service.verify_token.return_value = claims_without_roles
        authorization = "Bearer valid-token"

        # Act
        with patch("adyela_api.presentation.api.v1.endpoints.auth.datetime") as mock_datetime:
            mock_datetime.utcnow.return_value.isoformat.return_value = "2024-01-01T00:00:00"

            result = await sync_oauth_user(
                request=valid_oauth_request,
                authorization=authorization,
                auth_service=mock_auth_service,
            )

        # Assert
        assert result.roles == ["patient"]
        assert result.user["roles"] == ["patient"]

    @pytest.mark.asyncio
    async def test_sync_oauth_user_different_providers(
        self, mock_auth_service, valid_firebase_claims
    ):
        """Test OAuth sync with different providers."""
        providers = ["google", "facebook", "apple", "microsoft"]

        for provider in providers:
            # Arrange
            oauth_request = OAuthSyncRequest(
                user_data=OAuthUserData(
                    uid="test-uid-123",
                    email="test@example.com",
                    displayName="Test User",
                    photoURL=None,
                    provider=provider,
                    emailVerified=True,
                )
            )
            mock_auth_service.verify_token.return_value = valid_firebase_claims
            authorization = "Bearer valid-token"

            # Act
            with patch("adyela_api.presentation.api.v1.endpoints.auth.datetime") as mock_datetime:
                mock_datetime.utcnow.return_value.isoformat.return_value = "2024-01-01T00:00:00"

                result = await sync_oauth_user(
                    request=oauth_request,
                    authorization=authorization,
                    auth_service=mock_auth_service,
                )

            # Assert
            assert result.user["provider"] == provider

    def test_oauth_sync_endpoint_integration(self, client, valid_oauth_request):
        """Test OAuth sync endpoint integration."""
        # This would require mocking the entire authentication flow
        # For now, we'll test the endpoint structure
        response = client.post(
            "/api/v1/auth/sync",
            json=valid_oauth_request.model_dump(),
            headers={"Authorization": "Bearer mock-token"},
        )

        # Should return 401 without proper authentication
        # Note: May return 400 if request validation fails before auth check
        assert response.status_code in [400, 401]
