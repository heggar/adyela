"""Google Cloud Pub/Sub event publisher implementation."""

import json
from typing import Any

from google.cloud import pubsub_v1  # type: ignore

from adyela_api_appointments.application.ports import EventPublisher


class PubSubEventPublisher(EventPublisher):
    """Google Cloud Pub/Sub implementation of event publisher."""

    def __init__(self, project_id: str, topic_name: str) -> None:
        """
        Initialize Pub/Sub publisher.

        Args:
            project_id: GCP project ID
            topic_name: Pub/Sub topic name
        """
        self.project_id = project_id
        self.topic_name = topic_name
        self.publisher = pubsub_v1.PublisherClient()
        self.topic_path = self.publisher.topic_path(project_id, topic_name)

    async def publish(self, event_type: str, data: dict[str, Any]) -> str:
        """
        Publish an event to Pub/Sub.

        Args:
            event_type: Type of event (e.g., "AppointmentCreated")
            data: Event payload

        Returns:
            Message ID from Pub/Sub
        """
        # Create event envelope
        event = {
            "event_type": event_type,
            "data": data,
            "timestamp": data.get("timestamp"),  # Can be added by caller
        }

        # Convert to JSON bytes
        message_data = json.dumps(event).encode("utf-8")

        # Publish to Pub/Sub
        future = self.publisher.publish(
            self.topic_path,
            message_data,
            event_type=event_type,  # Add as attribute for filtering
        )

        # Wait for result (in production, you might not want to wait)
        message_id = future.result()

        return message_id
