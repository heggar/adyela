"""Pytest configuration and fixtures."""

import pytest
from fastapi.testclient import TestClient

from adyela_api.main import app


@pytest.fixture
def client() -> TestClient:
    """Create a test client."""
    return TestClient(app)


@pytest.fixture
def tenant_id() -> str:
    """Return a test tenant ID."""
    return "test-tenant-123"


@pytest.fixture
def headers(tenant_id: str) -> dict[str, str]:
    """Return test headers with tenant ID."""
    return {"X-Tenant-ID": tenant_id}
