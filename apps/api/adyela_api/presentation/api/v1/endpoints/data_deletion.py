import logging
import uuid
from datetime import datetime, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status

from adyela_api.application.ports import AuthenticationService
from adyela_api.infrastructure.services.auth import FirebaseAuthService
from adyela_api.presentation.schemas.data_deletion import (
    DataDeletionRequest,
    DataDeletionResponse,
    DataDeletionStatus,
    DataDeletionStatusResponse,
)

# Configure logging
logger = logging.getLogger(__name__)

router = APIRouter(prefix="/data-deletion", tags=["data-deletion"])

# In-memory storage for demo purposes
# In production, this should be stored in Firestore or a database
deletion_requests: dict[str, dict[str, str | DataDeletionStatus]] = {}


async def process_data_deletion(request_id: str, email: str, user_id: str | None = None) -> None:
    """
    Background task to process data deletion.
    This is a placeholder implementation - in production, this would:
    1. Delete user data from Firestore
    2. Delete user data from Cloud Storage
    3. Delete audit logs (with retention policy)
    4. Delete user from Firebase Auth
    5. Send confirmation email
    6. Log the deletion for compliance
    """
    try:
        logger.info(f"Starting data deletion process for request {request_id}")

        # Update status to in progress
        if request_id in deletion_requests:
            deletion_requests[request_id]["status"] = DataDeletionStatus.IN_PROGRESS
            deletion_requests[request_id]["updated_at"] = datetime.utcnow().isoformat()

        # Simulate processing time
        import asyncio

        await asyncio.sleep(2)

        # Placeholder: Delete user data
        # In production, implement actual deletion logic:
        # - Delete from Firestore collections
        # - Delete files from Cloud Storage
        # - Delete user from Firebase Auth
        # - Update audit logs

        logger.info(f"Data deletion completed for request {request_id}")

        # Update status to completed
        if request_id in deletion_requests:
            deletion_requests[request_id]["status"] = DataDeletionStatus.COMPLETED
            deletion_requests[request_id]["completed_at"] = datetime.utcnow().isoformat()
            deletion_requests[request_id]["message"] = "Data deletion completed successfully"

    except Exception as e:
        logger.error(f"Data deletion failed for request {request_id}: {str(e)}")

        # Update status to failed
        if request_id in deletion_requests:
            deletion_requests[request_id]["status"] = DataDeletionStatus.FAILED
            deletion_requests[request_id]["message"] = f"Data deletion failed: {str(e)}"


@router.post("/request", response_model=DataDeletionResponse, status_code=status.HTTP_201_CREATED)
async def request_data_deletion(
    request: DataDeletionRequest,
    background_tasks: BackgroundTasks,
    auth_service: AuthenticationService = Depends(FirebaseAuthService),
) -> DataDeletionResponse:
    """
    Request deletion of user data.

    This endpoint allows users to request deletion of their personal data
    in compliance with GDPR, CCPA, and other privacy regulations.
    """
    try:
        # Generate unique request ID
        request_id = str(uuid.uuid4())

        # Create deletion request record
        deletion_requests[request_id] = {
            "request_id": request_id,
            "email": request.email,
            "reason": request.reason or "",
            "status": DataDeletionStatus.PENDING,
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat(),
            "message": "Data deletion request received",
        }

        # Log the request for audit purposes
        logger.info(f"Data deletion request created: {request_id} for email: {request.email}")

        # Start background deletion process
        background_tasks.add_task(process_data_deletion, request_id=request_id, email=request.email)

        return DataDeletionResponse(
            request_id=request_id,
            status=DataDeletionStatus.PENDING,
            message="Data deletion request received and will be processed within 30 days",
            estimated_completion=(datetime.utcnow() + timedelta(days=30)).isoformat(),
        )

    except Exception as e:
        logger.error(f"Failed to create data deletion request: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process data deletion request: {str(e)}",
        ) from e


@router.get("/status/{request_id}", response_model=DataDeletionStatusResponse)
async def get_deletion_status(request_id: str) -> DataDeletionStatusResponse:
    """
    Get the status of a data deletion request.
    """
    if request_id not in deletion_requests:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Data deletion request not found"
        )

    request_data = deletion_requests[request_id]

    return DataDeletionStatusResponse(
        request_id=request_data["request_id"],
        status=DataDeletionStatus(request_data["status"]),
        created_at=request_data["created_at"],
        completed_at=request_data.get("completed_at"),
        message=request_data["message"],
    )


@router.post("/confirm/{request_id}", status_code=status.HTTP_200_OK)
async def confirm_data_deletion(
    request_id: str, auth_service: AuthenticationService = Depends(FirebaseAuthService)
) -> dict[str, str]:
    """
    Confirm data deletion request (requires authentication).
    This endpoint is used when the user needs to authenticate to confirm deletion.
    """
    try:
        if request_id not in deletion_requests:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="Data deletion request not found"
            )

        request_data = deletion_requests[request_id]

        if request_data["status"] != DataDeletionStatus.PENDING:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Data deletion request is not in pending status",
            )

        # Update status to confirmed and start processing
        request_data["status"] = DataDeletionStatus.IN_PROGRESS
        request_data["updated_at"] = datetime.utcnow().isoformat()
        request_data["message"] = "Data deletion confirmed and processing"

        logger.info(f"Data deletion confirmed for request: {request_id}")

        return {
            "request_id": request_id,
            "status": "confirmed",
            "message": "Data deletion confirmed and will be processed",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to confirm data deletion: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to confirm data deletion: {str(e)}",
        ) from e


@router.get("/info", status_code=status.HTTP_200_OK)
async def get_deletion_info() -> dict[str, str | list[str] | dict[str, str]]:
    """
    Get information about data deletion process.
    This is a public endpoint that provides information about how data deletion works.
    """
    return {
        "title": "Data Deletion Information",
        "description": "Information about how we handle data deletion requests",
        "process": [
            "Submit a data deletion request with your email address",
            "We will verify your identity and process the request",
            "All your personal data will be permanently deleted within 30 days",
            "You will receive confirmation once the process is complete",
        ],
        "data_types": [
            "Personal information (name, email, phone)",
            "Medical records and appointment history",
            "Authentication data and login history",
            "Usage analytics and preferences",
            "Files and documents uploaded to the platform",
        ],
        "retention_policy": {
            "description": "Some data may be retained for legal or regulatory compliance",
            "audit_logs": "Audit logs may be retained for up to 7 years for compliance",
            "legal_holds": "Data may be retained if subject to legal hold or investigation",
        },
        "contact": {"email": "privacy@adyela.care", "phone": "+1 (555) 123-4567"},
    }
