"""Firestore implementation of AppointmentRepository.

MULTI-TENANT ARCHITECTURE:
This repository implements tenant-scoped queries using nested Firestore collections.
Structure: /tenants/{tenantId}/appointments/{appointmentId}

All methods require tenant_id to enforce tenant isolation at the database level.
"""

from __future__ import annotations

from typing import TYPE_CHECKING

from adyela_api.application.ports import AppointmentRepository
from adyela_api.config import COLLECTIONS
from adyela_api.domain import Appointment

if TYPE_CHECKING:
    import builtins

    from google.cloud import firestore  # type: ignore


class FirestoreAppointmentRepository(AppointmentRepository):
    """
    Firestore implementation of appointment repository.

    Implements multi-tenant architecture with tenant-scoped collections.
    Each tenant's appointments are stored in /tenants/{tenantId}/appointments/
    """

    def __init__(self, db: firestore.Client) -> None:
        self.db = db
        self.collection_name = COLLECTIONS["appointments"]

    def _get_collection(self, tenant_id: str):
        """
        Get tenant-scoped appointments collection.

        Args:
            tenant_id: Tenant identifier

        Returns:
            Firestore CollectionReference for tenant's appointments
        """
        return (
            self.db.collection(COLLECTIONS["tenants"])
            .document(tenant_id)
            .collection(self.collection_name)
        )

    async def create(self, entity: Appointment) -> Appointment:
        """
        Create a new appointment in tenant-scoped collection.

        Args:
            entity: Appointment entity with tenant_id populated

        Returns:
            Created appointment with generated ID
        """
        tenant_id = str(entity.tenant_id)
        collection = self._get_collection(tenant_id)
        doc_ref = collection.document()
        entity.id = doc_ref.id
        doc_ref.set(entity.to_dict())
        return entity

    async def get_by_id(self, entity_id: str, tenant_id: str) -> Appointment | None:
        """
        Get appointment by ID within tenant scope.

        Args:
            entity_id: Appointment ID
            tenant_id: Tenant ID for scoping

        Returns:
            Appointment if found in tenant's collection, None otherwise
        """
        collection = self._get_collection(tenant_id)
        doc = collection.document(entity_id).get()
        if not doc.exists:
            return None
        return Appointment.from_dict({"id": doc.id, **doc.to_dict()})

    async def update(self, entity: Appointment) -> Appointment:
        """
        Update an existing appointment in tenant-scoped collection.

        Args:
            entity: Appointment entity with tenant_id and id

        Returns:
            Updated appointment
        """
        tenant_id = str(entity.tenant_id)
        collection = self._get_collection(tenant_id)
        doc_ref = collection.document(entity.id)
        doc_ref.update(entity.to_dict())
        return entity

    async def delete(self, entity_id: str, tenant_id: str) -> bool:
        """
        Delete an appointment from tenant-scoped collection.

        Args:
            entity_id: Appointment ID
            tenant_id: Tenant ID for scoping

        Returns:
            True if deleted successfully
        """
        collection = self._get_collection(tenant_id)
        collection.document(entity_id).delete()
        return True

    async def list(
        self, tenant_id: str, skip: int = 0, limit: int = 100, filters: dict | None = None
    ) -> builtins.list[Appointment]:
        """
        List appointments in tenant-scoped collection with pagination.

        Args:
            tenant_id: Tenant ID for scoping
            skip: Number of results to skip
            limit: Maximum number of results
            filters: Additional filters to apply

        Returns:
            List of appointments for the tenant
        """
        collection = self._get_collection(tenant_id)
        query = collection

        if filters:
            for key, value in filters.items():
                query = query.where(key, "==", value)

        docs = query.offset(skip).limit(limit).stream()
        return [Appointment.from_dict({"id": doc.id, **doc.to_dict()}) for doc in docs]

    async def list_by_patient(
        self, tenant_id: str, patient_id: str, skip: int = 0, limit: int = 100
    ) -> builtins.list[Appointment]:
        """
        List appointments for a patient in tenant-scoped collection.

        Tenant isolation is enforced at collection level - no need for tenant_id filter.

        Args:
            tenant_id: Tenant ID for scoping
            patient_id: Patient ID to filter by
            skip: Number of results to skip
            limit: Maximum number of results

        Returns:
            List of patient's appointments within tenant
        """
        collection = self._get_collection(tenant_id)
        docs = (
            collection.where("patient_id", "==", patient_id)
            .offset(skip)
            .limit(limit)
            .stream()
        )
        return [Appointment.from_dict({"id": doc.id, **doc.to_dict()}) for doc in docs]

    async def list_by_practitioner(
        self, tenant_id: str, practitioner_id: str, skip: int = 0, limit: int = 100
    ) -> builtins.list[Appointment]:
        """
        List appointments for a practitioner in tenant-scoped collection.

        Tenant isolation is enforced at collection level - no need for tenant_id filter.

        Args:
            tenant_id: Tenant ID for scoping
            practitioner_id: Practitioner ID to filter by
            skip: Number of results to skip
            limit: Maximum number of results

        Returns:
            List of practitioner's appointments within tenant
        """
        collection = self._get_collection(tenant_id)
        docs = (
            collection.where("practitioner_id", "==", practitioner_id)
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
    ) -> builtins.list[Appointment]:
        """
        List appointments within a date range in tenant-scoped collection.

        Tenant isolation is enforced at collection level - no need for tenant_id filter.

        Args:
            tenant_id: Tenant ID for scoping
            start_date: Start date (ISO format)
            end_date: End date (ISO format)
            skip: Number of results to skip
            limit: Maximum number of results

        Returns:
            List of appointments within date range for tenant
        """
        collection = self._get_collection(tenant_id)
        docs = (
            collection.where("start_time", ">=", start_date)
            .where("start_time", "<=", end_date)
            .offset(skip)
            .limit(limit)
            .stream()
        )
        return [Appointment.from_dict({"id": doc.id, **doc.to_dict()}) for doc in docs]

    async def check_availability(
        self, tenant_id: str, practitioner_id: str, start_time: str, end_time: str
    ) -> bool:
        """
        Check if practitioner is available in tenant-scoped collection.

        Tenant isolation is enforced at collection level - no need for tenant_id filter.

        Args:
            tenant_id: Tenant ID for scoping
            practitioner_id: Practitioner ID to check
            start_time: Start time of desired slot (ISO format)
            end_time: End time of desired slot (ISO format)

        Returns:
            True if practitioner is available, False if slot is occupied
        """
        collection = self._get_collection(tenant_id)

        # Query for overlapping appointments
        docs = (
            collection.where("practitioner_id", "==", practitioner_id)
            .where("start_time", "<", end_time)
            .where("end_time", ">", start_time)
            .where("status", "in", ["scheduled", "confirmed", "in_progress"])
            .stream()
        )

        return not any(docs)
