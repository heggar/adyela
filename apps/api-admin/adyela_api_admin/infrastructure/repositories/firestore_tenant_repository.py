"""Firestore implementation of TenantRepository."""

from google.cloud import firestore  # type: ignore

from adyela_api_admin.application.ports import TenantRepository
from adyela_api_admin.domain.entities import Tenant


class FirestoreTenantRepository(TenantRepository):
    """
    Firestore implementation of tenant repository.

    Implements multi-tenant architecture with tenant documents at /tenants/{tenantId}.
    Each tenant document contains metadata and has subcollections for appointments,
    patients, practitioners, etc.
    """

    def __init__(self, db: firestore.Client) -> None:
        """Initialize repository."""
        self.db = db
        self.collection = db.collection("tenants")

    async def create(self, tenant: Tenant) -> Tenant:
        """Create a new tenant."""
        doc_ref = self.collection.document(tenant.id)
        data = tenant.to_dict()
        doc_ref.set(data)
        return tenant

    async def get_by_id(self, tenant_id: str) -> Tenant | None:
        """Get tenant by ID."""
        doc = self.collection.document(tenant_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict()
        return Tenant.from_dict(data) if data else None

    async def get_by_owner(self, owner_id: str) -> list[Tenant]:
        """Get all tenants owned by a user."""
        query = self.collection.where("owner_id", "==", owner_id)
        docs = query.stream()
        tenants = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                tenants.append(Tenant.from_dict(data))
        return tenants

    async def update(self, tenant: Tenant) -> Tenant:
        """Update a tenant."""
        doc_ref = self.collection.document(tenant.id)
        data = tenant.to_dict()
        doc_ref.update(data)
        return tenant

    async def delete(self, tenant_id: str) -> None:
        """
        Delete a tenant (hard delete).

        WARNING: This performs a hard delete and removes the tenant document.
        Consider using soft delete (tenant.cancel()) instead for production use.
        This does NOT cascade delete subcollections (appointments, patients, etc.).
        """
        doc_ref = self.collection.document(tenant_id)
        doc_ref.delete()

    async def list_all(self, limit: int = 100, offset: int = 0) -> list[Tenant]:
        """List all tenants with pagination."""
        query = (
            self.collection.order_by("created_at", direction=firestore.Query.DESCENDING)
            .limit(limit)
            .offset(offset)
        )
        docs = query.stream()
        tenants = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                tenants.append(Tenant.from_dict(data))
        return tenants

    async def list_by_status(self, status: str, limit: int = 100) -> list[Tenant]:
        """List tenants by status."""
        query = (
            self.collection.where("status", "==", status)
            .order_by("created_at", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )
        docs = query.stream()
        tenants = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                tenants.append(Tenant.from_dict(data))
        return tenants

    async def list_by_tier(self, tier: str, limit: int = 100) -> list[Tenant]:
        """List tenants by tier."""
        query = (
            self.collection.where("tier", "==", tier)
            .order_by("created_at", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )
        docs = query.stream()
        tenants = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                tenants.append(Tenant.from_dict(data))
        return tenants

    async def count_by_status(self, status: str) -> int:
        """Count tenants by status."""
        query = self.collection.where("status", "==", status)
        docs = query.stream()
        return sum(1 for _ in docs)

    async def count_total(self) -> int:
        """Count total tenants."""
        docs = self.collection.stream()
        return sum(1 for _ in docs)
