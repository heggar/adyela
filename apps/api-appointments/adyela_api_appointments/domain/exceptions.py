"""Domain exceptions."""


class DomainException(Exception):
    """Base exception for domain layer."""

    pass


class BusinessRuleViolationError(DomainException):
    """Raised when a business rule is violated."""

    pass


class AppointmentNotFoundError(DomainException):
    """Raised when an appointment is not found."""

    pass


class AppointmentConflictError(DomainException):
    """Raised when there's a scheduling conflict."""

    pass


class InvalidTimeRangeError(DomainException):
    """Raised when a time range is invalid."""

    pass
