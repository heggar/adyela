# Mobile Professional App (Flutter)

Native mobile application for healthcare professionals to manage appointments
and patients.

## Platform Support

- ✅ iOS (14.0+)
- ✅ Android (API 24+)
- ✅ Web (admin.adyela.care)

## Features

### MVP Features (Phase 1)

- [ ] Professional registration and verification
- [ ] Professional profile management
- [ ] Availability and schedule management
- [ ] Appointment dashboard
- [ ] Patient management
- [ ] Push notifications
- [ ] Real-time appointment updates

### Post-MVP Features (Phase 2)

- [ ] Video consultations (Jitsi integration)
- [ ] Clinical notes and prescriptions
- [ ] Revenue analytics
- [ ] Patient history and records
- [ ] Multi-location management
- [ ] Team collaboration

## Architecture

Same feature-based structure as patient app, adapted for professional workflows.

```
mobile-professional/
├── lib/
│   ├── core/
│   ├── features/
│   │   ├── auth/             # Professional authentication
│   │   ├── onboarding/       # 5-step professional onboarding
│   │   ├── dashboard/        # Professional dashboard
│   │   ├── schedule/         # Availability management
│   │   ├── appointments/     # Appointment management
│   │   ├── patients/         # Patient management
│   │   ├── analytics/        # Revenue and performance
│   │   └── profile/          # Professional profile
│   ├── shared/
│   └── main.dart
├── test/
├── assets/
├── pubspec.yaml
└── README.md
```

## Key Differences from Patient App

| Feature         | Patient App           | Professional App                           |
| --------------- | --------------------- | ------------------------------------------ |
| **Onboarding**  | 3 steps               | 5 steps (includes credential verification) |
| **Main Screen** | Search                | Dashboard with today's appointments        |
| **Booking**     | Book appointment      | Manage availability                        |
| **Calendar**    | View own appointments | View all appointments                      |
| **Profile**     | Basic profile         | Professional credentials + pricing         |
| **Permissions** | Patient role          | Professional role                          |

## Unique Features

### Professional Dashboard

```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Today's appointments
          TodayAppointmentsList(),

          // Quick actions
          QuickActionsGrid(
            actions: [
              QuickAction(
                icon: Icons.calendar_today,
                title: 'Manage Schedule',
                onTap: () => context.push('/schedule'),
              ),
              QuickAction(
                icon: Icons.people,
                title: 'My Patients',
                onTap: () => context.push('/patients'),
              ),
              QuickAction(
                icon: Icons.analytics,
                title: 'Analytics',
                onTap: () => context.push('/analytics'),
              ),
            ],
          ),

          // Revenue summary
          RevenueSummaryCard(),

          // Upcoming appointments
          UpcomingAppointmentsList(),
        ],
      ),
    );
  }
}
```

### Availability Management

```dart
class AvailabilityScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Availability')),
      body: Column(
        children: [
          // Week calendar view
          WeekCalendarView(),

          // Time slot editor
          TimeSlotEditor(
            onSlotAdded: (slot) {
              context.read<ScheduleBloc>().add(AddTimeSlot(slot));
            },
            onSlotRemoved: (slotId) {
              context.read<ScheduleBloc>().add(RemoveTimeSlot(slotId));
            },
          ),

          // Recurring slots
          RecurringSlotsList(),
        ],
      ),
    );
  }
}
```

## Professional Onboarding Flow

5-step verification process:

1. **Personal Information**
   - Name, email, phone
   - Profile photo

2. **Professional Credentials**
   - Medical license number
   - Specialty
   - Years of experience
   - Upload credential documents

3. **Practice Information**
   - Practice name
   - Address
   - Services offered

4. **Pricing & Availability**
   - Consultation price
   - Default availability
   - Duration per appointment

5. **Verification**
   - Admin review required
   - Email verification
   - SMS verification

## Role-Based Features

Professional-only endpoints:

- `GET /professionals/me/dashboard` - Dashboard data
- `POST /professionals/me/availability` - Set availability
- `GET /professionals/me/patients` - List patients
- `POST /professionals/me/notes` - Add clinical notes
- `GET /professionals/me/analytics` - Revenue analytics

## Testing

Same testing approach as patient app, with additional tests for:

- Schedule management
- Availability conflict detection
- Multi-timezone support
- Professional verification workflow

## CI/CD

Same pipeline as patient app:

- Separate Firebase projects for staging/production
- Firebase App Distribution for internal testing
- App Store Connect and Google Play Console for production

## Related Documentation

- [Health Platform PRD](../../docs/planning/health-platform-prd.md)
- [Multi-Tenancy Model](../../docs/architecture/multi-tenancy-hybrid-model.md)
- [Microservices Architecture](../MICROSERVICES_ARCHITECTURE.md)

---

**Version**: 0.1.0 **Platform**: iOS 14+, Android API 24+, Web **Status**: 🚧 In
Development
