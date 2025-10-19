"""Tests for Tenant entity."""

from datetime import UTC, datetime

import pytest

from adyela_api_admin.domain.entities import Tenant, TenantStats
from adyela_api_admin.domain.exceptions import InvalidStatusTransitionError


class TestTenantEntity:
    """Test suite for Tenant entity."""

    def test_create_tenant(self):
        """Test tenant creation."""
        tenant = Tenant(
            id="tenant_test_clinic_abc123",
            owner_id="user_dr_test_123",
            name="Test Clinic",
            email="test@clinic.com",
            phone="+57 300 123 4567",
            tier="free",
            status="active",
        )

        assert tenant.id == "tenant_test_clinic_abc123"
        assert tenant.owner_id == "user_dr_test_123"
        assert tenant.name == "Test Clinic"
        assert tenant.tier == "free"
        assert tenant.status == "active"

    def test_suspend_active_tenant(self):
        """Test suspending an active tenant."""
        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            status="active",
        )

        tenant.suspend("Policy violation")

        assert tenant.status == "suspended"
        assert tenant.metadata["suspension_reason"] == "Policy violation"
        assert "suspended_at" in tenant.metadata

    def test_cannot_suspend_non_active_tenant(self):
        """Test that suspended tenant cannot be suspended again."""
        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            status="suspended",
        )

        with pytest.raises(InvalidStatusTransitionError):
            tenant.suspend("Another reason")

    def test_activate_suspended_tenant(self):
        """Test activating a suspended tenant."""
        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            status="suspended",
        )

        tenant.activate()

        assert tenant.status == "active"

    def test_cannot_activate_active_tenant(self):
        """Test that active tenant cannot be activated again."""
        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            status="active",
        )

        with pytest.raises(InvalidStatusTransitionError):
            tenant.activate()

    def test_cancel_tenant(self):
        """Test cancelling a tenant."""
        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            status="active",
        )

        tenant.cancel("User requested cancellation")

        assert tenant.status == "cancelled"
        assert tenant.metadata["cancellation_reason"] == "User requested cancellation"
        assert "cancelled_at" in tenant.metadata

    def test_update_stats(self):
        """Test updating tenant statistics."""
        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
        )

        tenant.update_stats(
            total_appointments=100,
            total_patients=50,
            total_revenue=5000.0,
        )

        assert tenant.stats.total_appointments == 100
        assert tenant.stats.total_patients == 50
        assert tenant.stats.total_revenue == 5000.0

    def test_is_subscription_active_free_tier(self):
        """Test subscription check for free tier."""
        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            tier="free",
        )

        assert tenant.is_subscription_active() is True

    def test_is_subscription_active_with_future_expiration(self):
        """Test subscription check with future expiration date."""
        future_date = datetime.now(UTC).replace(year=datetime.now(UTC).year + 1)

        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            tier="pro",
            subscription_expires_at=future_date,
        )

        assert tenant.is_subscription_active() is True

    def test_is_subscription_expired(self):
        """Test subscription check with past expiration date."""
        past_date = datetime.now(UTC).replace(year=datetime.now(UTC).year - 1)

        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            tier="pro",
            subscription_expires_at=past_date,
        )

        assert tenant.is_subscription_active() is False

    def test_to_dict_and_from_dict(self):
        """Test serialization and deserialization."""
        tenant = Tenant(
            id="tenant_test",
            owner_id="user_test",
            name="Test",
            email="test@test.com",
            phone="+123",
            tier="pro",
            status="active",
        )

        data = tenant.to_dict()
        reconstructed = Tenant.from_dict(data)

        assert reconstructed.id == tenant.id
        assert reconstructed.owner_id == tenant.owner_id
        assert reconstructed.name == tenant.name
        assert reconstructed.email == tenant.email
        assert reconstructed.tier == tenant.tier
        assert reconstructed.status == tenant.status
