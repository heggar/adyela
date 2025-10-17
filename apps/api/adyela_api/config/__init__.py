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
    "CACHE_KEYS",
    "CACHE_TTL",
    "COLLECTIONS",
    "AppointmentStatus",
    "AppointmentType",
    "NotificationType",
    "Settings",
    "UserRole",
    "get_settings",
]
