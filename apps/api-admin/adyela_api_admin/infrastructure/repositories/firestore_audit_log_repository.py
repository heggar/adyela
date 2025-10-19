"""Firestore implementation of AuditLogRepository."""

from google.cloud import firestore  # type: ignore

from adyela_api_admin.application.ports import AuditLogRepository
from adyela_api_admin.domain.entities import AuditLog


class FirestoreAuditLogRepository(AuditLogRepository):
    """Firestore implementation of audit log repository."""

    def __init__(self, db: firestore.Client) -> None:
        """Initialize repository."""
        self.db = db
        self.collection = db.collection("audit_logs")

    async def create(self, log: AuditLog) -> AuditLog:
        """Create audit log entry."""
        doc_ref = self.collection.document(log.id)
        data = log.to_dict()
        doc_ref.set(data)
        return log

    async def list_recent(self, limit: int = 100) -> list[AuditLog]:
        """List recent audit log entries."""
        query = (
            self.collection.order_by("timestamp", direction=firestore.Query.DESCENDING)
            .limit(limit)
        )
        docs = query.stream()
        logs = []
        for doc in docs:
            data = doc.to_dict()
            if data:
                logs.append(AuditLog.from_dict(data))
        return logs
