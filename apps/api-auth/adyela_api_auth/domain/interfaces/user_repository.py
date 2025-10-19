"""
User repository interface (Port)
"""
from abc import ABC, abstractmethod
from typing import Optional
from uuid import UUID

from adyela_api_auth.domain.entities.user import User


class IUserRepository(ABC):
    """
    Interface for User repository.

    This is a port in hexagonal architecture that defines the contract
    for user data persistence operations.
    """

    @abstractmethod
    async def create(self, user: User) -> User:
        """
        Create a new user.

        Args:
            user: User entity to create

        Returns:
            Created user with persisted data

        Raises:
            ValueError: If user with email already exists
        """
        pass

    @abstractmethod
    async def get_by_id(self, user_id: UUID) -> Optional[User]:
        """
        Get user by ID.

        Args:
            user_id: User UUID

        Returns:
            User if found, None otherwise
        """
        pass

    @abstractmethod
    async def get_by_email(self, email: str) -> Optional[User]:
        """
        Get user by email address.

        Args:
            email: User email

        Returns:
            User if found, None otherwise
        """
        pass

    @abstractmethod
    async def get_by_firebase_uid(self, firebase_uid: str) -> Optional[User]:
        """
        Get user by Firebase UID.

        Args:
            firebase_uid: Firebase authentication UID

        Returns:
            User if found, None otherwise
        """
        pass

    @abstractmethod
    async def update(self, user: User) -> User:
        """
        Update existing user.

        Args:
            user: User entity with updated data

        Returns:
            Updated user

        Raises:
            ValueError: If user not found
        """
        pass

    @abstractmethod
    async def delete(self, user_id: UUID) -> bool:
        """
        Delete user by ID.

        Args:
            user_id: User UUID

        Returns:
            True if deleted, False if not found
        """
        pass

    @abstractmethod
    async def exists_by_email(self, email: str) -> bool:
        """
        Check if user exists by email.

        Args:
            email: User email

        Returns:
            True if user exists, False otherwise
        """
        pass
