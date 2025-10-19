"""
Firestore implementation of User Repository
"""
import logging
from datetime import datetime
from typing import Optional
from uuid import UUID

from google.cloud import firestore
from google.cloud.firestore_v1.base_query import FieldFilter

from adyela_api_auth.domain.entities.user import User, UserRole, UserStatus
from adyela_api_auth.domain.interfaces.user_repository import IUserRepository

logger = logging.getLogger(__name__)


class FirestoreUserRepository(IUserRepository):
    """
    Firestore implementation of IUserRepository.

    This is an adapter in hexagonal architecture that implements the port
    defined by IUserRepository.
    """

    COLLECTION_NAME = "users"

    def __init__(self, db: firestore.AsyncClient):
        """
        Initialize repository with Firestore client.

        Args:
            db: Firestore async client instance
        """
        self.db = db
        self.collection = db.collection(self.COLLECTION_NAME)

    def _user_to_dict(self, user: User) -> dict:
        """Convert User entity to Firestore document dict."""
        return {
            "id": str(user.id),
            "email": user.email,
            "email_verified": user.email_verified,
            "full_name": user.full_name,
            "phone": user.phone,
            "phone_verified": user.phone_verified,
            "roles": [role.value for role in user.roles],
            "status": user.status.value,
            "tenant_id": str(user.tenant_id) if user.tenant_id else None,
            "firebase_uid": user.firebase_uid,
            "photo_url": user.photo_url,
            "created_at": user.created_at,
            "updated_at": user.updated_at,
            "last_login_at": user.last_login_at,
            "metadata": user.metadata,
        }

    def _dict_to_user(self, doc_dict: dict) -> User:
        """Convert Firestore document dict to User entity."""
        return User(
            id=UUID(doc_dict["id"]),
            email=doc_dict["email"],
            email_verified=doc_dict.get("email_verified", False),
            full_name=doc_dict["full_name"],
            phone=doc_dict.get("phone"),
            phone_verified=doc_dict.get("phone_verified", False),
            roles=[UserRole(role) for role in doc_dict.get("roles", ["patient"])],
            status=UserStatus(doc_dict.get("status", "pending_verification")),
            tenant_id=UUID(doc_dict["tenant_id"]) if doc_dict.get("tenant_id") else None,
            firebase_uid=doc_dict.get("firebase_uid"),
            photo_url=doc_dict.get("photo_url"),
            created_at=doc_dict.get("created_at", datetime.utcnow()),
            updated_at=doc_dict.get("updated_at", datetime.utcnow()),
            last_login_at=doc_dict.get("last_login_at"),
            metadata=doc_dict.get("metadata", {}),
        )

    async def create(self, user: User) -> User:
        """Create a new user in Firestore."""
        # Check if user with email already exists
        if await self.exists_by_email(user.email):
            raise ValueError(f"User with email {user.email} already exists")

        user_dict = self._user_to_dict(user)
        user_id = str(user.id)

        # Create document with user ID as document ID
        await self.collection.document(user_id).set(user_dict)

        logger.info(f"Created user {user_id} with email {user.email}")
        return user

    async def get_by_id(self, user_id: UUID) -> Optional[User]:
        """Get user by ID from Firestore."""
        doc = await self.collection.document(str(user_id)).get()

        if not doc.exists:
            return None

        return self._dict_to_user(doc.to_dict())

    async def get_by_email(self, email: str) -> Optional[User]:
        """Get user by email from Firestore."""
        query = self.collection.where(
            filter=FieldFilter("email", "==", email)
        ).limit(1)

        docs = [doc async for doc in query.stream()]

        if not docs:
            return None

        return self._dict_to_user(docs[0].to_dict())

    async def get_by_firebase_uid(self, firebase_uid: str) -> Optional[User]:
        """Get user by Firebase UID from Firestore."""
        query = self.collection.where(
            filter=FieldFilter("firebase_uid", "==", firebase_uid)
        ).limit(1)

        docs = [doc async for doc in query.stream()]

        if not docs:
            return None

        return self._dict_to_user(docs[0].to_dict())

    async def update(self, user: User) -> User:
        """Update existing user in Firestore."""
        user_id = str(user.id)
        doc_ref = self.collection.document(user_id)

        # Check if user exists
        doc = await doc_ref.get()
        if not doc.exists:
            raise ValueError(f"User {user_id} not found")

        # Update timestamp
        user.updated_at = datetime.utcnow()
        user_dict = self._user_to_dict(user)

        await doc_ref.update(user_dict)

        logger.info(f"Updated user {user_id}")
        return user

    async def delete(self, user_id: UUID) -> bool:
        """Delete user from Firestore."""
        doc_ref = self.collection.document(str(user_id))

        # Check if user exists
        doc = await doc_ref.get()
        if not doc.exists:
            return False

        await doc_ref.delete()

        logger.info(f"Deleted user {user_id}")
        return True

    async def exists_by_email(self, email: str) -> bool:
        """Check if user exists by email."""
        user = await self.get_by_email(email)
        return user is not None
