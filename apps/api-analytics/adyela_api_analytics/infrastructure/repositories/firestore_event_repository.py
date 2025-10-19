"""Firestore event repository implementation."""

from datetime import datetime

from google.cloud import firestore

from adyela_api_analytics.application.ports import EventRepository
from adyela_api_analytics.domain.entities import Event, EventType
from adyela_api_analytics.domain.exceptions import EventNotFoundException


class FirestoreEventRepository(EventRepository):
    """Firestore implementation of EventRepository."""

    def __init__(self, db: firestore.Client) -> None:
        self.db = db
        self.collection = "analytics_events"

    async def create(self, event: Event) -> Event:
        """Create a new event."""
        doc_ref = self.db.collection(self.collection).document(event.event_id)

        event_dict = {
            "event_id": event.event_id,
            "event_type": event.event_type.value,
            "timestamp": event.timestamp,
            "tenant_id": event.tenant_id,
            "user_id": event.user_id,
            "entity_id": event.entity_id,
            "properties": event.properties,
            "metadata": event.metadata,
        }

        doc_ref.set(event_dict)
        return event

    async def find_by_id(self, event_id: str) -> Event:
        """Find an event by ID."""
        doc_ref = self.db.collection(self.collection).document(event_id)
        doc = doc_ref.get()

        if not doc.exists:
            raise EventNotFoundException(event_id)

        data = doc.to_dict()
        return Event(
            event_id=data["event_id"],
            event_type=EventType(data["event_type"]),
            timestamp=data["timestamp"],
            tenant_id=data["tenant_id"],
            user_id=data.get("user_id"),
            entity_id=data["entity_id"],
            properties=data.get("properties", {}),
            metadata=data.get("metadata", {}),
        )

    async def find_by_type(
        self, event_type: EventType, start_date: datetime, end_date: datetime, limit: int = 100
    ) -> list[Event]:
        """Find events by type within a date range."""
        query = (
            self.db.collection(self.collection)
            .where("event_type", "==", event_type.value)
            .where("timestamp", ">=", start_date)
            .where("timestamp", "<=", end_date)
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )

        docs = query.stream()
        events = []

        for doc in docs:
            data = doc.to_dict()
            events.append(
                Event(
                    event_id=data["event_id"],
                    event_type=EventType(data["event_type"]),
                    timestamp=data["timestamp"],
                    tenant_id=data["tenant_id"],
                    user_id=data.get("user_id"),
                    entity_id=data["entity_id"],
                    properties=data.get("properties", {}),
                    metadata=data.get("metadata", {}),
                )
            )

        return events

    async def find_by_tenant(
        self, tenant_id: str, start_date: datetime, end_date: datetime, limit: int = 100
    ) -> list[Event]:
        """Find events by tenant within a date range."""
        query = (
            self.db.collection(self.collection)
            .where("tenant_id", "==", tenant_id)
            .where("timestamp", ">=", start_date)
            .where("timestamp", "<=", end_date)
            .order_by("timestamp", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )

        docs = query.stream()
        events = []

        for doc in docs:
            data = doc.to_dict()
            events.append(
                Event(
                    event_id=data["event_id"],
                    event_type=EventType(data["event_type"]),
                    timestamp=data["timestamp"],
                    tenant_id=data["tenant_id"],
                    user_id=data.get("user_id"),
                    entity_id=data["entity_id"],
                    properties=data.get("properties", {}),
                    metadata=data.get("metadata", {}),
                )
            )

        return events
