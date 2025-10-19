# flutter-core

Core models, entities, enums, and business logic shared across Adyela Flutter
apps.

## Features

- **Models**: Professional, Appointment with JSON serialization
- **Enums**: Specialty, AppointmentStatus with utilities
- **Functional Programming**: dartz for Either monad
- **Value Equality**: equatable for immutability

## Usage

```dart
import 'package:flutter_core/flutter_core.dart';

// Use models
final professional = Professional(
  id: 'prof_123',
  firstName: 'Juan',
  lastName: 'Pérez',
  specialty: Specialty.generalMedicine,
  // ...
);

// Use enums
if (appointment.status.canCancel) {
  // Cancel appointment
}
```

## Models

### Professional

Healthcare provider with specialty, ratings, and availability.

### Appointment

Appointment with status, scheduling, and metadata.

## Version

0.1.0
