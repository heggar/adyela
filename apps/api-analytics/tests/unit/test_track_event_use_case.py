"""Unit tests for TrackEventUseCase."""

from datetime import datetime
from uuid import uuid4

import pytest
from unittest.mock import AsyncMock, MagicMock

from adyela_api_analytics.application.ports import BigQueryClient, EventRepository
from adyela_api_analytics.application.use_cases.track_event import TrackEventUseCase
from adyela_api_analytics.domain.entities import Event, EventType


@pytest.fixture
def mock_event_repository():
    """Create mock event repository."""
    return AsyncMock(spec=EventRepository)


@pytest.fixture
def mock_bigquery_client():
    """Create mock BigQuery client."""
    return AsyncMock(spec=BigQueryClient)


@pytest.fixture
def track_event_use_case(mock_event_repository, mock_bigquery_client):
    """Create TrackEventUseCase with mocked dependencies."""
    return TrackEventUseCase(mock_event_repository, mock_bigquery_client)


@pytest.mark.asyncio
async def test_track_event_success(track_event_use_case, mock_event_repository, mock_bigquery_client):
    """Test tracking an event successfully."""
    # Arrange
    event_type = EventType.APPOINTMENT_CREATED
    tenant_id = "tenant_123"
    entity_id = "appt_456"
    user_id = "user_789"
    properties = {"status": "scheduled", "date": "2025-01-20"}
    metadata = {"source": "web_app"}

    created_event = Event(
        event_id=str(uuid4()),
        event_type=event_type,
        timestamp=datetime.utcnow(),
        tenant_id=tenant_id,
        user_id=user_id,
        entity_id=entity_id,
        properties=properties,
        metadata=metadata,
    )

    mock_event_repository.create.return_value = created_event
    mock_bigquery_client.insert_event.return_value = None

    # Act
    result = await track_event_use_case.execute(
        event_type=event_type,
        tenant_id=tenant_id,
        entity_id=entity_id,
        user_id=user_id,
        properties=properties,
        metadata=metadata,
    )

    # Assert
    assert result.event_type == event_type
    assert result.tenant_id == tenant_id
    assert result.entity_id == entity_id
    assert result.user_id == user_id
    assert result.properties == properties
    assert result.metadata == metadata

    mock_event_repository.create.assert_called_once()
    mock_bigquery_client.insert_event.assert_called_once()


@pytest.mark.asyncio
async def test_track_event_without_optional_fields(track_event_use_case, mock_event_repository, mock_bigquery_client):
    """Test tracking an event without optional fields."""
    # Arrange
    event_type = EventType.PAYMENT_SUCCEEDED
    tenant_id = "tenant_123"
    entity_id = "payment_456"

    created_event = Event(
        event_id=str(uuid4()),
        event_type=event_type,
        timestamp=datetime.utcnow(),
        tenant_id=tenant_id,
        user_id=None,
        entity_id=entity_id,
        properties={},
        metadata={},
    )

    mock_event_repository.create.return_value = created_event
    mock_bigquery_client.insert_event.return_value = None

    # Act
    result = await track_event_use_case.execute(
        event_type=event_type,
        tenant_id=tenant_id,
        entity_id=entity_id,
    )

    # Assert
    assert result.event_type == event_type
    assert result.user_id is None
    assert result.properties == {}
    assert result.metadata == {}


@pytest.mark.asyncio
async def test_track_event_generates_unique_id(track_event_use_case, mock_event_repository, mock_bigquery_client):
    """Test that each tracked event has a unique ID."""
    # Arrange
    mock_event_repository.create.side_effect = lambda e: e
    mock_bigquery_client.insert_event.return_value = None

    # Act
    result1 = await track_event_use_case.execute(
        event_type=EventType.APPOINTMENT_CREATED,
        tenant_id="tenant_123",
        entity_id="entity_1",
    )

    result2 = await track_event_use_case.execute(
        event_type=EventType.APPOINTMENT_CREATED,
        tenant_id="tenant_123",
        entity_id="entity_2",
    )

    # Assert
    assert result1.event_id != result2.event_id
