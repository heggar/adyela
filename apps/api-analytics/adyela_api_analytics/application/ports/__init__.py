"""Application ports (interfaces) for analytics."""

from abc import ABC, abstractmethod
from datetime import datetime

from adyela_api_analytics.domain.entities import (
    AggregationPeriod,
    DashboardMetrics,
    Event,
    EventType,
    Metric,
    MetricType,
)


class EventRepository(ABC):
    """Repository interface for events."""

    @abstractmethod
    async def create(self, event: Event) -> Event:
        """Create a new event."""
        pass

    @abstractmethod
    async def find_by_id(self, event_id: str) -> Event:
        """Find an event by ID."""
        pass

    @abstractmethod
    async def find_by_type(
        self, event_type: EventType, start_date: datetime, end_date: datetime, limit: int = 100
    ) -> list[Event]:
        """Find events by type within a date range."""
        pass

    @abstractmethod
    async def find_by_tenant(
        self, tenant_id: str, start_date: datetime, end_date: datetime, limit: int = 100
    ) -> list[Event]:
        """Find events by tenant within a date range."""
        pass


class MetricRepository(ABC):
    """Repository interface for metrics."""

    @abstractmethod
    async def create(self, metric: Metric) -> Metric:
        """Create a new metric."""
        pass

    @abstractmethod
    async def find_by_id(self, metric_id: str) -> Metric:
        """Find a metric by ID."""
        pass

    @abstractmethod
    async def find_by_type(
        self,
        metric_type: MetricType,
        period: AggregationPeriod,
        start_date: datetime,
        end_date: datetime,
        tenant_id: str | None = None,
    ) -> list[Metric]:
        """Find metrics by type and period."""
        pass

    @abstractmethod
    async def update(self, metric: Metric) -> Metric:
        """Update an existing metric."""
        pass


class BigQueryClient(ABC):
    """BigQuery client interface."""

    @abstractmethod
    async def insert_event(self, event: Event) -> None:
        """Insert an event into BigQuery."""
        pass

    @abstractmethod
    async def insert_metric(self, metric: Metric) -> None:
        """Insert a metric into BigQuery."""
        pass

    @abstractmethod
    async def query_events(
        self,
        event_type: EventType | None,
        start_date: datetime,
        end_date: datetime,
        tenant_id: str | None = None,
        limit: int = 100,
    ) -> list[dict]:
        """Query events from BigQuery."""
        pass

    @abstractmethod
    async def aggregate_metrics(
        self,
        metric_type: MetricType,
        period: AggregationPeriod,
        start_date: datetime,
        end_date: datetime,
        tenant_id: str | None = None,
    ) -> list[dict]:
        """Aggregate metrics from BigQuery."""
        pass


class PubSubSubscriber(ABC):
    """Pub/Sub subscriber interface."""

    @abstractmethod
    async def start_listening(self, subscription_name: str, callback: callable) -> None:
        """Start listening to a Pub/Sub subscription."""
        pass

    @abstractmethod
    async def stop_listening(self) -> None:
        """Stop listening to Pub/Sub subscriptions."""
        pass
