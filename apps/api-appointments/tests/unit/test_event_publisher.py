"""
Unit tests for PubSubEventPublisher
"""
from unittest.mock import MagicMock, patch

import pytest

from adyela_api_appointments.infrastructure.pubsub import PubSubEventPublisher


class TestPubSubEventPublisher:
    """Test suite for PubSubEventPublisher"""

    @pytest.fixture
    def project_id(self):
        """Test project ID"""
        return "test-project-id"

    @pytest.fixture
    def topic_name(self):
        """Test topic name"""
        return "test-appointments-events"

    @pytest.fixture
    def mock_publisher_client(self):
        """Mock Pub/Sub publisher client"""
        with patch("adyela_api_appointments.infrastructure.pubsub.event_publisher.pubsub_v1.PublisherClient") as mock:
            publisher_instance = MagicMock()
            mock.return_value = publisher_instance

            # Mock topic_path method
            publisher_instance.topic_path.return_value = (
                "projects/test-project-id/topics/test-appointments-events"
            )

            # Mock publish method with future
            future = MagicMock()
            future.result.return_value = "message-id-12345"
            publisher_instance.publish.return_value = future

            yield mock

    @pytest.mark.asyncio
    async def test_publish_event_success(
        self, mock_publisher_client, project_id, topic_name
    ):
        """Test successfully publishing an event"""
        # Arrange
        publisher = PubSubEventPublisher(
            project_id=project_id,
            topic_name=topic_name,
        )

        event_data = {
            "appointment_id": "apt-123",
            "tenant_id": "tenant-456",
            "patient_id": "patient-789",
        }

        # Act
        message_id = await publisher.publish(
            event_type="AppointmentCreated",
            data=event_data,
        )

        # Assert
        assert message_id == "message-id-12345"

        # Verify publish was called
        publisher_client_instance = mock_publisher_client.return_value
        publisher_client_instance.publish.assert_called_once()

        # Verify the call arguments
        call_args = publisher_client_instance.publish.call_args
        topic_path_arg = call_args[0][0]
        message_data_arg = call_args[0][1]

        assert topic_path_arg == "projects/test-project-id/topics/test-appointments-events"
        assert b"AppointmentCreated" in message_data_arg
        assert b"apt-123" in message_data_arg

    @pytest.mark.asyncio
    async def test_publish_event_with_attributes(
        self, mock_publisher_client, project_id, topic_name
    ):
        """Test that event_type is added as message attribute"""
        # Arrange
        publisher = PubSubEventPublisher(
            project_id=project_id,
            topic_name=topic_name,
        )

        # Act
        await publisher.publish(
            event_type="AppointmentCancelled",
            data={"appointment_id": "apt-456"},
        )

        # Assert
        publisher_client_instance = mock_publisher_client.return_value
        call_kwargs = publisher_client_instance.publish.call_args.kwargs

        assert "event_type" in call_kwargs
        assert call_kwargs["event_type"] == "AppointmentCancelled"

    @pytest.mark.asyncio
    async def test_publish_multiple_events(
        self, mock_publisher_client, project_id, topic_name
    ):
        """Test publishing multiple events"""
        # Arrange
        publisher = PubSubEventPublisher(
            project_id=project_id,
            topic_name=topic_name,
        )

        # Act
        message_id_1 = await publisher.publish(
            event_type="AppointmentCreated",
            data={"appointment_id": "apt-1"},
        )
        message_id_2 = await publisher.publish(
            event_type="AppointmentConfirmed",
            data={"appointment_id": "apt-2"},
        )

        # Assert
        assert message_id_1 == "message-id-12345"
        assert message_id_2 == "message-id-12345"

        publisher_client_instance = mock_publisher_client.return_value
        assert publisher_client_instance.publish.call_count == 2

    @pytest.mark.asyncio
    async def test_topic_path_initialization(
        self, mock_publisher_client, project_id, topic_name
    ):
        """Test that topic path is correctly initialized"""
        # Arrange & Act
        publisher = PubSubEventPublisher(
            project_id=project_id,
            topic_name=topic_name,
        )

        # Assert
        publisher_client_instance = mock_publisher_client.return_value
        publisher_client_instance.topic_path.assert_called_once_with(
            project_id, topic_name
        )
        assert (
            publisher.topic_path
            == "projects/test-project-id/topics/test-appointments-events"
        )
