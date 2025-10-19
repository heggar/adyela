# flutter-shared

Shared UI widgets, components, and theme utilities for Adyela Flutter apps.

## Features

- **Reusable Widgets**: ProfessionalCard, AppointmentCard, EmptyState
- **Shared Theme**: Consistent styling across apps
- **Image Caching**: Optimized with cached_network_image
- **Loading States**: Shimmer effects for better UX

## Usage

```dart
import 'package:flutter_shared/flutter_shared.dart';

// Use professional card
ProfessionalCard(
  professional: professional,
  onTap: () => navigateTo(professional.id),
  showBookButton: true,
)

// Use appointment card
AppointmentCard(
  appointment: appointment,
  professionalName: 'Dr. Juan Pérez',
  onCancel: () => cancelAppointment(appointment.id),
)

// Use empty state
EmptyState(
  icon: Icons.search_off,
  title: 'No hay resultados',
  message: 'Intenta ajustar tus filtros de búsqueda',
  actionLabel: 'Limpiar filtros',
  onAction: () => clearFilters(),
)
```

## Widgets

### ProfessionalCard

Displays professional information with photo, specialty, rating, and booking
button.

### AppointmentCard

Shows appointment details with status, date/time, and action buttons.

### EmptyState

Generic empty state with icon, message, and optional action button.

## Version

0.1.0
