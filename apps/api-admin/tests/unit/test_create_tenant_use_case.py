"""Tests for CreateTenantUseCase."""

from unittest.mock import AsyncMock, MagicMock

import pytest

from adyela_api_admin.application.use_cases.tenants import CreateTenantUseCase
from adyela_api_admin.domain.entities import Tenant


@pytest.fixture
def tenant_repository():
    """Mock tenant repository."""
    return AsyncMock()


@pytest.fixture
def audit_repository():
    """Mock audit log repository."""
    return AsyncMock()


@pytest.fixture
def use_case(tenant_repository, audit_repository):
    """Create use case instance."""
    return CreateTenantUseCase(
        tenant_repository=tenant_repository,
        audit_repository=audit_repository,
    )


class TestCreateTenantUseCase:
    """Test suite for CreateTenantUseCase."""

    @pytest.mark.asyncio
    async def test_create_tenant_success(self, use_case, tenant_repository, audit_repository):
        """Test successful tenant creation."""
        # Arrange
        owner_id = "user_dr_test_123"
        name = "Test Clinic"
        email = "test@clinic.com"
        phone = "+57 300 123 4567"

        tenant_repository.create.return_value = MagicMock(spec=Tenant)

        # Act
        result = await use_case.execute(
            owner_id=owner_id,
            name=name,
            email=email,
            phone=phone,
            tier="free",
        )

        # Assert
        tenant_repository.create.assert_called_once()
        audit_repository.create.assert_called_once()
        assert result is not None

    @pytest.mark.asyncio
    async def test_create_tenant_invalid_tier(
        self, use_case, tenant_repository, audit_repository
    ):
        """Test tenant creation with invalid tier."""
        # Act & Assert
        with pytest.raises(ValueError, match="Invalid tier"):
            await use_case.execute(
                owner_id="user_test",
                name="Test",
                email="test@test.com",
                phone="+123",
                tier="invalid_tier",  # Invalid
            )

        # Verify repository not called
        tenant_repository.create.assert_not_called()
        audit_repository.create.assert_not_called()

    @pytest.mark.asyncio
    async def test_create_tenant_generates_id(self, use_case, tenant_repository):
        """Test that tenant ID is generated correctly."""
        # Arrange
        captured_tenant = None

        async def capture_tenant(tenant):
            nonlocal captured_tenant
            captured_tenant = tenant
            return tenant

        tenant_repository.create.side_effect = capture_tenant

        # Act
        await use_case.execute(
            owner_id="user_test",
            name="Dr. Carlos García - Psicología",
            email="test@test.com",
            phone="+123",
        )

        # Assert
        assert captured_tenant is not None
        assert captured_tenant.id.startswith("tenant_")
        assert len(captured_tenant.id) > len("tenant_")

    @pytest.mark.asyncio
    async def test_create_tenant_with_organization(
        self, use_case, tenant_repository, audit_repository
    ):
        """Test creating enterprise tenant with organization."""
        # Arrange
        organization_id = "org_hospital_san_jose"

        # Act
        result = await use_case.execute(
            owner_id="user_test",
            name="Test Hospital",
            email="test@hospital.com",
            phone="+123",
            tier="enterprise",
            organization_id=organization_id,
        )

        # Assert
        tenant_repository.create.assert_called_once()
        audit_repository.create.assert_called_once()
