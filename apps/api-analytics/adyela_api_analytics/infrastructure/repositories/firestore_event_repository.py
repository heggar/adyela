"""Firestore event repository implementation.

ANALYTICS ARCHITECTURE:
Analytics events use a hybrid approach:
- Events stored in global "analytics_events" collection for cross-tenant analysis
- Events always include tenant_id for filtering and isolation
- Future: Events exported to BigQuery for advanced analytics

This approach allows:
1. Individual tenant analytics (filtered by tenant_id)
2. Global platform analytics (admin/super admin)
3. Efficient export to BigQuery for data warehousing
"""

from datetime import datetime

from google.cloud import firestore

from adyela_api_analytics.application.ports import EventRepository
from adyela_api_analytics.domain.entities import Event, EventType
from adyela_api_analytics.domain.exceptions import EventNotFoundException


class FirestoreEventRepository(EventRepository):
    """
    Firestore implementation of EventRepository.

    Uses global collection with tenant_id filtering for analytics.
    All queries must include tenant_id to ensure data isolation.
    """

    def __init__(self, db: firestore.Client) -> None:
        self.db = db
        self.collection = "analytics_events"

    async def create(self, event: Event) -> Event:
        """
        Create a new analytics event.

        Events are stored in global collection for cross-tenant analytics.
        tenant_id is always included for filtering and isolation.

        Args:
            event: Event entity to create

        Returns:
            Created event
        """
        doc_ref = self.db.collection(self.collection).document(event.event_id)

        event_dict = {
            "event_id": event.event_id,
            "event_type": event.event_type.value,
            "timestamp": event.timestamp,
            "tenant_id": event.tenant_id,  # CRITICAL: Always include for isolation
            "user_id": event.user_id,
            "entity_id": event.entity_id,
            "properties": event.properties,
            "metadata": event.metadata,
        }

        doc_ref.set(event_dict)
        return event

    async def find_by_id(self, event_id: str, tenant_id: str | None = None) -> Event:
        """
        Find an event by ID.

        Args:
            event_id: Event identifier
            tenant_id: Optional tenant ID for validation (recommended for security)

        Returns:
            Event if found

        Raises:
            EventNotFoundException: If event not found
            PermissionError: If event belongs to different tenant (when tenant_id provided)
        """
        doc_ref = self.db.collection(self.collection).document(event_id)
        doc = doc_ref.get()

        if not doc.exists:
            raise EventNotFoundException(event_id)

        data = doc.to_dict()

        # Validate tenant ownership if tenant_id provided
        if tenant_id and data["tenant_id"] != tenant_id:
            raise PermissionError(f"Event {event_id} does not belong to tenant {tenant_id}")

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
        self,
        event_type: EventType,
        start_date: datetime,
        end_date: datetime,
        tenant_id: str | None = None,
        limit: int = 100,
    ) -> list[Event]:
        """
        Find events by type within a date range.

        Args:
            event_type: Type of event to filter by
            start_date: Start of date range
            end_date: End of date range
            tenant_id: Optional tenant ID for filtering (recommended)
            limit: Maximum number of results

        Returns:
            List of events matching criteria
        """
        query = self.db.collection(self.collection).where("event_type", "==", event_type.value)

        # Add tenant filter if provided (recommended for tenant-specific queries)
        if tenant_id:
            query = query.where("tenant_id", "==", tenant_id)

        query = (
            query.where("timestamp", ">=", start_date)
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
        """
        Find events by tenant within a date range.

        TENANT ISOLATION: This query filters by tenant_id to ensure data isolation.

        Args:
            tenant_id: Tenant ID to filter by
            start_date: Start of date range
            end_date: End of date range
            limit: Maximum number of results

        Returns:
            List of events for the specified tenant
        """
        query = (
            self.db.collection(self.collection)
            .where("tenant_id", "==", tenant_id)  # CRITICAL: Tenant isolation
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
