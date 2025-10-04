"""Domain entities."""

from .appointment import Appointment
from .patient import Patient
from .practitioner import Practitioner
from .tenant import Tenant

__all__ = ["Tenant", "Patient", "Practitioner", "Appointment"]
