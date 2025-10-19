"""Domain exceptions."""


class DomainException(Exception):
    """Base exception for domain layer."""

    pass


class ProfessionalNotFoundError(DomainException):
    """Raised when a professional is not found."""

    pass


class InvalidStatusTransitionError(DomainException):
    """Raised when an invalid status transition is attempted."""

    pass


class UnauthorizedOperationError(DomainException):
    """Raised when user lacks permission for operation."""

    pass


class TenantNotFoundError(DomainException):
    """Raised when a tenant is not found."""

    pass
