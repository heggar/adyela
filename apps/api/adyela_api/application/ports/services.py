"""Service port interfaces."""

from abc import ABC, abstractmethod
from typing import Any


class AuthenticationService(ABC):
    """Authentication service interface."""

    @abstractmethod
    async def verify_token(self, token: str) -> dict[str, Any]:
        """Verify authentication token and return user info."""
        pass

    @abstractmethod
    async def create_custom_token(self, user_id: str) -> str:
        """Create a custom authentication token."""
        pass


class NotificationService(ABC):
    """Notification service interface."""

    @abstractmethod
    async def send_sms(self, phone_number: str, message: str) -> bool:
        """Send SMS notification."""
        pass

    @abstractmethod
    async def send_email(
        self, to_email: str, subject: str, body: str, html_body: str | None = None
    ) -> bool:
        """Send email notification."""
        pass

    @abstractmethod
    async def send_appointment_reminder(
        self, appointment_id: str, recipient_email: str, recipient_phone: str
    ) -> bool:
        """Send appointment reminder via email and SMS."""
        pass


class VideoCallService(ABC):
    """Video call service interface."""

    @abstractmethod
    async def create_room(self, room_name: str, options: dict[str, Any] | None = None) -> str:
        """Create a video call room and return the URL."""
        pass

    @abstractmethod
    async def generate_jwt(self, room_name: str, user_name: str, is_moderator: bool = False) -> str:
        """Generate JWT token for video call authentication."""
        pass

    @abstractmethod
    async def end_room(self, room_name: str) -> bool:
        """End a video call room."""
        pass


class CacheService(ABC):
    """Cache service interface."""

    @abstractmethod
    async def get(self, key: str) -> Any | None:
        """Get value from cache."""
        pass

    @abstractmethod
    async def set(self, key: str, value: Any, ttl: int | None = None) -> bool:
        """Set value in cache with optional TTL."""
        pass

    @abstractmethod
    async def delete(self, key: str) -> bool:
        """Delete value from cache."""
        pass

    @abstractmethod
    async def exists(self, key: str) -> bool:
        """Check if key exists in cache."""
        pass
