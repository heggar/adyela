"""Firestore implementation of ProfessionalRepository."""

from google.cloud import firestore  # type: ignore

from adyela_api_admin.application.ports import ProfessionalRepository
from adyela_api_admin.config import ProfessionalStatus
from adyela_api_admin.domain.entities import Professional


class FirestoreProfessionalRepository(ProfessionalRepository):
    """Firestore implementation of professional repository."""

    def __init__(self, db: firestore.Client) -> None:
        """Initialize repository."""
        self.db = db
        self.collection = db.collection("professionals")

    async def create(self, professional: Professional) -> Professional:
        """Create a new professional."""
        doc_ref = self.collection.document(professional.id)
        data = professional.to_dict()
        doc_ref.set(data)
        return professional

    async def get_by_id(self, professional_id: str) -> Professional | None:
        """Get professional by ID."""
        doc = self.collection.document(professional_id).get()
        if not doc.exists:
            return None
        data = doc.to_dict()
        return Professional.from_dict(data) if data else None

    async def update(self, professional: Professional) -> Professional:
        """Update a professional."""
        doc_ref = self.collection.document(professional.id)
        data = professional.to_dict()
        doc_ref.update(data)
        return professional

    async def list_by_status(
        self, status: ProfessionalStatus, limit: int = 50
    ) -> list[Professional]:
        """List professionals by status."""
        query = (
            self.collection.where("status", "==", status.value)
            .order_by("submitted_at", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )
        docs = query.stream()
        professionals = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                professionals.append(Professional.from_dict(data))
        return professionals

    async def count_by_status(self, status: ProfessionalStatus) -> int:
        """Count professionals by status."""
        query = self.collection.where("status", "==", status.value)
        docs = query.stream()
        return sum(1 for _ in docs)
