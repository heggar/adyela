"""Application constants."""

from enum import Enum


class AppointmentStatus(str, Enum):
    """Appointment status enumeration."""

    SCHEDULED = "scheduled"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"


class NotificationType(str, Enum):
    """Notification type enumeration."""

    SMS = "sms"
    EMAIL = "email"
    PUSH = "push"


class UserRole(str, Enum):
    """User role enumeration for RBAC."""

    SUPER_ADMIN = "super_admin"
    ORG_ADMIN = "org_admin"
    DOCTOR = "doctor"
    NURSE = "nurse"
    RECEPTIONIST = "receptionist"
    PATIENT = "patient"


class AppointmentType(str, Enum):
    """Appointment type enumeration."""

    IN_PERSON = "in_person"
    VIDEO_CALL = "video_call"
    PHONE_CALL = "phone_call"


# Collection names
COLLECTIONS = {
    "tenants": "tenants",
    "users": "users",
    "patients": "patients",
    "practitioners": "practitioners",
    "appointments": "appointments",
    "notifications": "notifications",
    "audit_logs": "audit_logs",
}

# Cache keys
CACHE_KEYS = {
    "tenant": "tenant:{tenant_id}",
    "user": "user:{user_id}",
    "appointment": "appointment:{appointment_id}",
}

# Cache TTL (in seconds)
CACHE_TTL = {
    "tenant": 3600,  # 1 hour
    "user": 1800,  # 30 minutes
    "appointment": 300,  # 5 minutes
}

# Pagination
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 100

# Date/Time formats
DATETIME_FORMAT = "%Y-%m-%dT%H:%M:%S%z"
DATE_FORMAT = "%Y-%m-%d"
TIME_FORMAT = "%H:%M:%S"

# Appointment constraints
MIN_APPOINTMENT_DURATION_MINUTES = 15
MAX_APPOINTMENT_DURATION_MINUTES = 240
DEFAULT_APPOINTMENT_DURATION_MINUTES = 30

# Video call
VIDEO_CALL_MAX_DURATION_MINUTES = 120
VIDEO_CALL_ROOM_PREFIX = "adyela"
