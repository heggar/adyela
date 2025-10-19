"""Use case for tracking analytics events."""

from datetime import datetime
from uuid import uuid4

from adyela_api_analytics.application.ports import BigQueryClient, EventRepository
from adyela_api_analytics.domain.entities import Event, EventType


class TrackEventUseCase:
    """Use case for tracking analytics events."""

    def __init__(
        self, event_repository: EventRepository, bigquery_client: BigQueryClient
    ) -> None:
        self.event_repository = event_repository
        self.bigquery_client = bigquery_client

    async def execute(
        self,
        event_type: EventType,
        tenant_id: str,
        entity_id: str,
        user_id: str | None = None,
        properties: dict | None = None,
        metadata: dict | None = None,
    ) -> Event:
        """Execute the use case to track an event."""

        # Create event entity
        event = Event(
            event_id=str(uuid4()),
            event_type=event_type,
            timestamp=datetime.utcnow(),
            tenant_id=tenant_id,
            user_id=user_id,
            entity_id=entity_id,
            properties=properties or {},
            metadata=metadata or {},
        )

        # Store in repository (Firestore for quick access)
        created_event = await self.event_repository.create(event)

        # Insert into BigQuery for analytics
        await self.bigquery_client.insert_event(created_event)

        return created_event
