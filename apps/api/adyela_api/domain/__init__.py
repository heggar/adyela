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
    "Address",
    "Appointment",
    "AuthenticationError",
    "AuthorizationError",
    "BusinessRuleViolationError",
    "ConflictError",
    "DateTimeRange",
    # Exceptions
    "DomainException",
    # Value Objects
    "Email",
    "EntityNotFoundError",
    "Patient",
    "PhoneNumber",
    "Practitioner",
    # Entities
    "Tenant",
    "TenantId",
    "ValidationError",
]
