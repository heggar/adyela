"""Configuration module."""

from .constants import (
    CACHE_KEYS,
    CACHE_TTL,
    COLLECTIONS,
    AppointmentStatus,
    AppointmentType,
    NotificationType,
    UserRole,
)
from .settings import Settings, get_settings

__all__ = [
    "Settings",
    "get_settings",
    "AppointmentStatus",
    "AppointmentType",
    "NotificationType",
    "UserRole",
    "COLLECTIONS",
    "CACHE_KEYS",
    "CACHE_TTL",
]
