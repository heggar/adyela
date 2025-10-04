"""Firestore implementation of AppointmentRepository."""

from datetime import datetime

from google.cloud import firestore  # type: ignore

from adyela_api.application.ports import AppointmentRepository
from adyela_api.config import COLLECTIONS
from adyela_api.domain import Appointment


class FirestoreAppointmentRepository(AppointmentRepository):
    """Firestore implementation of appointment repository."""

    def __init__(self, db: firestore.Client) -> None:
        self.db = db
        self.collection = COLLECTIONS["appointments"]

    async def create(self, entity: Appointment) -> Appointment:
        """Create a new appointment."""
        doc_ref = self.db.collection(self.collection).document()
        entity.id = doc_ref.id
        doc_ref.set(entity.to_dict())
        return entity

    async def get_by_id(self, entity_id: str) -> Appointment | None:
        """Get appointment by ID."""
        doc = self.db.collection(self.collection).document(entity_id).get()
        if not doc.exists:
            return None
        return Appointment.from_dict({"id": doc.id, **doc.to_dict()})

    async def update(self, entity: Appointment) -> Appointment:
        """Update an existing appointment."""
        doc_ref = self.db.collection(self.collection).document(entity.id)
        doc_ref.update(entity.to_dict())
        return entity

    async def delete(self, entity_id: str) -> bool:
        """Delete an appointment."""
        self.db.collection(self.collection).document(entity_id).delete()
        return True

    async def list(
        self, skip: int = 0, limit: int = 100, filters: dict | None = None
    ) -> list[Appointment]:
        """List appointments with pagination."""
        query = self.db.collection(self.collection)

        if filters:
            for key, value in filters.items():
                query = query.where(key, "==", value)

        docs = query.offset(skip).limit(limit).stream()
        return [Appointment.from_dict({"id": doc.id, **doc.to_dict()}) for doc in docs]

    async def list_by_patient(
        self, tenant_id: str, patient_id: str, skip: int = 0, limit: int = 100
    ) -> list[Appointment]:
        """List appointments for a patient."""
        docs = (
            self.db.collection(self.collection)
            .where("tenant_id", "==", tenant_id)
            .where("patient_id", "==", patient_id)
            .offset(skip)
            .limit(limit)
            .stream()
        )
        return [Appointment.from_dict({"id": doc.id, **doc.to_dict()}) for doc in docs]

    async def list_by_practitioner(
        self, tenant_id: str, practitioner_id: str, skip: int = 0, limit: int = 100
    ) -> list[Appointment]:
        """List appointments for a practitioner."""
        docs = (
            self.db.collection(self.collection)
            .where("tenant_id", "==", tenant_id)
            .where("practitioner_id", "==", practitioner_id)
            .offset(skip)
            .limit(limit)
            .stream()
        )
        return [Appointment.from_dict({"id": doc.id, **doc.to_dict()}) for doc in docs]

    async def list_by_date_range(
        self,
        tenant_id: str,
        start_date: str,
        end_date: str,
        skip: int = 0,
        limit: int = 100,
    ) -> list[Appointment]:
        """List appointments within a date range."""
        docs = (
            self.db.collection(self.collection)
            .where("tenant_id", "==", tenant_id)
            .where("start_time", ">=", start_date)
            .where("start_time", "<=", end_date)
            .offset(skip)
            .limit(limit)
            .stream()
        )
        return [Appointment.from_dict({"id": doc.id, **doc.to_dict()}) for doc in docs]

    async def check_availability(
        self, tenant_id: str, practitioner_id: str, start_time: str, end_time: str
    ) -> bool:
        """Check if practitioner is available."""
        # Query for overlapping appointments
        docs = (
            self.db.collection(self.collection)
            .where("tenant_id", "==", tenant_id)
            .where("practitioner_id", "==", practitioner_id)
            .where("start_time", "<", end_time)
            .where("end_time", ">", start_time)
            .where("status", "in", ["scheduled", "confirmed", "in_progress"])
            .stream()
        )

        return not any(docs)
