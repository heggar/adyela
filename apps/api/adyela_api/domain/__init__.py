"""Domain layer."""

from .entities import Appointment, Patient, Practitioner, Tenant
from .exceptions import (
    AuthenticationError,
    AuthorizationError,
    BusinessRuleViolationError,
    ConflictError,
    DomainException,
    EntityNotFoundError,
    ValidationError,
)
from .value_objects import Address, DateTimeRange, Email, PhoneNumber, TenantId

__all__ = [
    # Entities
    "Tenant",
    "Patient",
    "Practitioner",
    "Appointment",
    # Value Objects
    "Email",
    "PhoneNumber",
    "TenantId",
    "Address",
    "DateTimeRange",
    # Exceptions
    "DomainException",
    "EntityNotFoundError",
    "ValidationError",
    "AuthenticationError",
    "AuthorizationError",
    "ConflictError",
    "BusinessRuleViolationError",
]
