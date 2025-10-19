"""Firestore implementation of AppointmentRepository."""

from datetime import datetime

from google.cloud import firestore  # type: ignore

from adyela_api_appointments.application.ports import AppointmentRepository
from adyela_api_appointments.config import AppointmentStatus
from adyela_api_appointments.domain.entities import Appointment
from adyela_api_appointments.domain.value_objects import DateTimeRange, TenantId


class FirestoreAppointmentRepository(AppointmentRepository):
    """Firestore implementation of appointment repository."""

    def __init__(self, db: firestore.Client) -> None:
        """Initialize repository."""
        self.db = db

    def _collection(self, tenant_id: TenantId) -> firestore.CollectionReference:
        """Get appointments collection for a tenant."""
        return self.db.collection("tenants").document(str(tenant_id)).collection("appointments")

    async def create(self, appointment: Appointment) -> Appointment:
        """Create a new appointment."""
        collection = self._collection(appointment.tenant_id)
        doc_ref = collection.document(appointment.id)

        data = appointment.to_dict()
        doc_ref.set(data)

        return appointment

    async def get_by_id(self, appointment_id: str, tenant_id: TenantId) -> Appointment | None:
        """Get appointment by ID."""
        collection = self._collection(tenant_id)
        doc = collection.document(appointment_id).get()

        if not doc.exists:
            return None

        data = doc.to_dict()
        if data is None:
            return None

        return Appointment.from_dict(data)

    async def list_by_tenant(
        self,
        tenant_id: TenantId,
        limit: int = 20,
        offset: int = 0,
    ) -> list[Appointment]:
        """List appointments for a tenant."""
        collection = self._collection(tenant_id)

        query = collection.order_by("created_at", direction=firestore.Query.DESCENDING).limit(limit)

        if offset > 0:
            query = query.offset(offset)

        docs = query.stream()

        appointments = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                appointments.append(Appointment.from_dict(data))

        return appointments

    async def list_by_patient(
        self,
        patient_id: str,
        tenant_id: TenantId,
        limit: int = 20,
        offset: int = 0,
    ) -> list[Appointment]:
        """List appointments for a patient."""
        collection = self._collection(tenant_id)

        query = (
            collection.where("patient_id", "==", patient_id)
            .order_by("created_at", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )

        if offset > 0:
            query = query.offset(offset)

        docs = query.stream()

        appointments = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                appointments.append(Appointment.from_dict(data))

        return appointments

    async def list_by_practitioner(
        self,
        practitioner_id: str,
        tenant_id: TenantId,
        limit: int = 20,
        offset: int = 0,
    ) -> list[Appointment]:
        """List appointments for a practitioner."""
        collection = self._collection(tenant_id)

        query = (
            collection.where("practitioner_id", "==", practitioner_id)
            .order_by("created_at", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )

        if offset > 0:
            query = query.offset(offset)

        docs = query.stream()

        appointments = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                appointments.append(Appointment.from_dict(data))

        return appointments

    async def update(self, appointment: Appointment) -> Appointment:
        """Update an existing appointment."""
        collection = self._collection(appointment.tenant_id)
        doc_ref = collection.document(appointment.id)

        data = appointment.to_dict()
        doc_ref.update(data)

        return appointment

    async def delete(self, appointment_id: str, tenant_id: TenantId) -> bool:
        """Delete an appointment."""
        collection = self._collection(tenant_id)
        doc_ref = collection.document(appointment_id)

        # Check if exists
        doc = doc_ref.get()
        if not doc.exists:
            return False

        doc_ref.delete()
        return True

    async def find_conflicts(
        self,
        practitioner_id: str,
        tenant_id: TenantId,
        time_range: DateTimeRange,
        exclude_appointment_id: str | None = None,
    ) -> list[Appointment]:
        """Find conflicting appointments for a practitioner in a time range."""
        collection = self._collection(tenant_id)

        # Query for appointments by this practitioner
        query = collection.where("practitioner_id", "==", practitioner_id).where(
            "status",
            "in",
            [
                AppointmentStatus.SCHEDULED.value,
                AppointmentStatus.CONFIRMED.value,
                AppointmentStatus.IN_PROGRESS.value,
            ],
        )

        docs = query.stream()

        conflicts = []
        for doc in docs:
            data = doc.to_dict()
            if not data:
                continue

            # Skip excluded appointment
            if exclude_appointment_id and data["id"] == exclude_appointment_id:
                continue

            appointment = Appointment.from_dict(data)

            # Check for time overlap
            if appointment.schedule.overlaps_with(time_range):
                conflicts.append(appointment)

        return conflicts

    async def count_by_tenant(self, tenant_id: TenantId) -> int:
        """Count total appointments for a tenant."""
        collection = self._collection(tenant_id)

        # Firestore doesn't have a native count, so we need to fetch all
        # In production, you might want to maintain a counter in a separate document
        docs = collection.stream()

        count = sum(1 for _ in docs)
        return count

    async def find_upcoming(
        self,
        tenant_id: TenantId,
        start_date: datetime,
        limit: int = 100,
    ) -> list[Appointment]:
        """Find upcoming appointments starting from a specific date."""
        collection = self._collection(tenant_id)

        query = (
            collection.where("start_time", ">=", start_date.isoformat())
            .where(
                "status",
                "in",
                [
                    AppointmentStatus.SCHEDULED.value,
                    AppointmentStatus.CONFIRMED.value,
                ],
            )
            .order_by("start_time")
            .limit(limit)
        )

        docs = query.stream()

        appointments = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                appointments.append(Appointment.from_dict(data))

        return appointments
