"""Application constants."""

from enum import Enum


class ProfessionalStatus(str, Enum):
    """Professional verification status options."""

    PENDING_VERIFICATION = "pending_verification"
    APPROVED = "approved"
    REJECTED = "rejected"
    SUSPENDED = "suspended"


class UserRole(str, Enum):
    """User role options."""

    ADMIN = "admin"
    PROFESSIONAL = "professional"
    PATIENT = "patient"


class AuditAction(str, Enum):
    """Audit log action types."""

    PROFESSIONAL_APPROVED = "professional_approved"
    PROFESSIONAL_REJECTED = "professional_rejected"
    PROFESSIONAL_SUSPENDED = "professional_suspended"
    USER_CREATED = "user_created"
    USER_UPDATED = "user_updated"
    USER_DELETED = "user_deleted"
