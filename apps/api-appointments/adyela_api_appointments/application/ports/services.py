"""Service interfaces."""

from abc import ABC, abstractmethod
from typing import Any


class EventPublisher(ABC):
    """Event publisher interface for Pub/Sub."""

    @abstractmethod
    async def publish(self, event_type: str, data: dict[str, Any]) -> str:
        """
        Publish an event.

        Args:
            event_type: Type of event (e.g., "AppointmentCreated")
            data: Event payload

        Returns:
            Message ID from Pub/Sub
        """
        pass
