"""Configuration module."""

from .constants import AppointmentStatus, AppointmentType
from .settings import Settings, get_settings

__all__ = ["AppointmentStatus", "AppointmentType", "Settings", "get_settings"]
