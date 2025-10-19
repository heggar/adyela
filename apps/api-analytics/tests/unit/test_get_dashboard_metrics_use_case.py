"""Unit tests for GetDashboardMetricsUseCase."""

from datetime import datetime, timedelta

import pytest
from unittest.mock import AsyncMock

from adyela_api_analytics.application.ports import BigQueryClient
from adyela_api_analytics.application.use_cases.get_dashboard_metrics import (
    GetDashboardMetricsUseCase,
)
from adyela_api_analytics.domain.entities import AggregationPeriod, MetricType


@pytest.fixture
def mock_bigquery_client():
    """Create mock BigQuery client."""
    return AsyncMock(spec=BigQueryClient)


@pytest.fixture
def get_dashboard_metrics_use_case(mock_bigquery_client):
    """Create GetDashboardMetricsUseCase with mocked dependencies."""
    return GetDashboardMetricsUseCase(mock_bigquery_client)


@pytest.mark.asyncio
async def test_get_dashboard_metrics_success(get_dashboard_metrics_use_case, mock_bigquery_client):
    """Test getting dashboard metrics successfully."""
    # Arrange
    tenant_id = "tenant_123"
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=30)

    # Mock responses for different metric types
    mock_bigquery_client.aggregate_metrics.side_effect = [
        # APPOINTMENTS_BY_STATUS
        [
            {"status": "confirmed", "count": 50},
            {"status": "cancelled", "count": 10},
            {"status": "scheduled", "count": 20},
        ],
        # REVENUE_TOTAL
        [{"revenue": 5000.0}],
        # REVENUE_BY_PERIOD (current month)
        [{"revenue": 1500.0}],
        # PROFESSIONALS_COUNT
        [{"count": 25, "active_count": 20}],
        # PATIENTS_COUNT
        [{"count": 150, "active_count": 120}],
        # NOTIFICATIONS_SENT
        [{"count": 45}],
    ]

    # Act
    result = await get_dashboard_metrics_use_case.execute(
        tenant_id=tenant_id,
        start_date=start_date,
        end_date=end_date,
    )

    # Assert
    assert result.total_appointments == 80  # 50 + 10 + 20
    assert result.confirmed_appointments == 50
    assert result.cancelled_appointments == 10
    assert result.total_revenue == 5000.0
    assert result.revenue_this_month == 1500.0
    assert result.total_professionals == 25
    assert result.active_professionals == 20
    assert result.total_patients == 150
    assert result.active_patients == 120
    assert result.notifications_sent_today == 45
    assert result.conversion_rate == pytest.approx(62.5)  # 50/80 * 100
    assert result.period_start == start_date
    assert result.period_end == end_date


@pytest.mark.asyncio
async def test_get_dashboard_metrics_no_appointments(get_dashboard_metrics_use_case, mock_bigquery_client):
    """Test getting dashboard metrics with no appointments."""
    # Arrange
    tenant_id = "tenant_123"
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=30)

    # Mock responses with zero appointments
    mock_bigquery_client.aggregate_metrics.side_effect = [
        [],  # APPOINTMENTS_BY_STATUS
        [{"revenue": 0}],  # REVENUE_TOTAL
        [],  # REVENUE_BY_PERIOD
        [{"count": 10, "active_count": 8}],  # PROFESSIONALS_COUNT
        [{"count": 50, "active_count": 40}],  # PATIENTS_COUNT
        [],  # NOTIFICATIONS_SENT
    ]

    # Act
    result = await get_dashboard_metrics_use_case.execute(
        tenant_id=tenant_id,
        start_date=start_date,
        end_date=end_date,
    )

    # Assert
    assert result.total_appointments == 0
    assert result.confirmed_appointments == 0
    assert result.cancelled_appointments == 0
    assert result.conversion_rate == 0.0  # Avoid division by zero


@pytest.mark.asyncio
async def test_get_dashboard_metrics_calls_bigquery_correctly(get_dashboard_metrics_use_case, mock_bigquery_client):
    """Test that BigQuery is called with correct parameters."""
    # Arrange
    tenant_id = "tenant_123"
    end_date = datetime.utcnow()
    start_date = end_date - timedelta(days=30)

    mock_bigquery_client.aggregate_metrics.return_value = []

    # Act
    await get_dashboard_metrics_use_case.execute(
        tenant_id=tenant_id,
        start_date=start_date,
        end_date=end_date,
    )

    # Assert
    calls = mock_bigquery_client.aggregate_metrics.call_args_list

    # Verify first call (appointments by status)
    assert calls[0].kwargs["metric_type"] == MetricType.APPOINTMENTS_BY_STATUS
    assert calls[0].kwargs["period"] == AggregationPeriod.DAY
    assert calls[0].kwargs["tenant_id"] == tenant_id

    # Verify revenue calls
    assert calls[1].kwargs["metric_type"] == MetricType.REVENUE_TOTAL
    assert calls[2].kwargs["metric_type"] == MetricType.REVENUE_BY_PERIOD
