"""Dependency injection for FastAPI."""

from functools import lru_cache

from google.cloud import firestore, pubsub_v1  # type: ignore

from adyela_api_appointments.application.ports import AppointmentRepository, EventPublisher
from adyela_api_appointments.application.use_cases.appointments import (
    CancelAppointmentUseCase,
    CheckAvailabilityUseCase,
    ConfirmAppointmentUseCase,
    CreateAppointmentUseCase,
    GetAppointmentUseCase,
    ListAppointmentsUseCase,
)
from adyela_api_appointments.config import get_settings
from adyela_api_appointments.infrastructure.pubsub import PubSubEventPublisher
from adyela_api_appointments.infrastructure.repositories import FirestoreAppointmentRepository


# Repositories
@lru_cache
def get_firestore_client() -> firestore.Client:
    """Get Firestore client instance."""
    settings = get_settings()
    return firestore.Client(
        project=settings.gcp_project_id,
        database=settings.firestore_database,
    )


def get_appointment_repository() -> AppointmentRepository:
    """Get appointment repository instance."""
    db = get_firestore_client()
    return FirestoreAppointmentRepository(db)


# Services
@lru_cache
def get_event_publisher() -> EventPublisher:
    """Get event publisher instance."""
    settings = get_settings()
    return PubSubEventPublisher(
        project_id=settings.gcp_project_id,
        topic_name=settings.pubsub_appointments_topic,
    )


# Use Cases
def get_create_appointment_use_case() -> CreateAppointmentUseCase:
    """Get create appointment use case."""
    return CreateAppointmentUseCase(
        repository=get_appointment_repository(),
        event_publisher=get_event_publisher(),
    )


def get_get_appointment_use_case() -> GetAppointmentUseCase:
    """Get appointment use case."""
    return GetAppointmentUseCase(
        repository=get_appointment_repository(),
    )


def get_list_appointments_use_case() -> ListAppointmentsUseCase:
    """Get list appointments use case."""
    return ListAppointmentsUseCase(
        repository=get_appointment_repository(),
    )


def get_cancel_appointment_use_case() -> CancelAppointmentUseCase:
    """Get cancel appointment use case."""
    return CancelAppointmentUseCase(
        repository=get_appointment_repository(),
        event_publisher=get_event_publisher(),
    )


def get_confirm_appointment_use_case() -> ConfirmAppointmentUseCase:
    """Get confirm appointment use case."""
    return ConfirmAppointmentUseCase(
        repository=get_appointment_repository(),
        event_publisher=get_event_publisher(),
    )


def get_check_availability_use_case() -> CheckAvailabilityUseCase:
    """Get check availability use case."""
    return CheckAvailabilityUseCase(
        repository=get_appointment_repository(),
    )
