"""Domain exceptions."""


class DomainException(Exception):
    """Base domain exception."""

    pass


class EntityNotFoundError(DomainException):
    """Raised when an entity is not found."""

    def __init__(self, entity_type: str, entity_id: str) -> None:
        self.entity_type = entity_type
        self.entity_id = entity_id
        super().__init__(f"{entity_type} with id '{entity_id}' not found")


class ValidationError(DomainException):
    """Raised when domain validation fails."""

    pass


class AuthenticationError(DomainException):
    """Raised when authentication fails."""

    pass


class AuthorizationError(DomainException):
    """Raised when authorization fails."""

    pass


class ConflictError(DomainException):
    """Raised when there's a conflict (e.g., duplicate entity)."""

    pass


class BusinessRuleViolationError(DomainException):
    """Raised when a business rule is violated."""

    pass
