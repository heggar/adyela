"""Integration tests for health endpoints."""

import pytest
from fastapi import status
from fastapi.testclient import TestClient


class TestHealthEndpoints:
    """Test health check endpoints."""

    def test_health_check(self, client: TestClient) -> None:
        """Test health check endpoint."""
        response = client.get("/health")

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["status"] == "healthy"
        assert "version" in data

    def test_readiness_check(self, client: TestClient) -> None:
        """Test readiness check endpoint."""
        response = client.get("/readiness")

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert "status" in data
        assert "checks" in data
        assert isinstance(data["checks"], dict)
