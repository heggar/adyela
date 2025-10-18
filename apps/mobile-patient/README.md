# Mobile Patient App (Flutter)

Native mobile application for patients to book appointments and manage their health.

## Platform Support

- ✅ iOS (14.0+)
- ✅ Android (API 24+)
- ✅ Web (Progressive Web App)

## Features

### MVP Features (Phase 1)
- [ ] User authentication (Google, Facebook, Apple, Email)
- [ ] Professional search and discovery
- [ ] Professional profile view
- [ ] Appointment booking (3-tap flow)
- [ ] Appointment history
- [ ] Patient profile management
- [ ] Push notifications

### Post-MVP Features (Phase 2)
- [ ] Video consultations (Jitsi integration)
- [ ] Medical records
- [ ] Prescription management
- [ ] Payment integration
- [ ] Chat with professional
- [ ] Appointment ratings and reviews

## Architecture

### Feature-Based Structure

```
mobile-patient/
├── lib/
│   ├── core/
│   │   ├── config/          # App configuration
│   │   ├── constants/       # Constants and enums
│   │   ├── di/              # Dependency injection
│   │   ├── routing/         # Navigation and routing
│   │   ├── theme/           # App theme and styling
│   │   └── utils/           # Helper functions
│   ├── features/
│   │   ├── auth/            # Authentication feature
│   │   │   ├── data/        # Data sources, repositories
│   │   │   ├── domain/      # Entities, use cases
│   │   │   └── presentation/ # UI, BLoC/Cubit
│   │   ├── search/          # Professional search
│   │   ├── appointments/    # Appointment management
│   │   ├── profile/         # Patient profile
│   │   └── notifications/   # Push notifications
│   ├── shared/
│   │   ├── models/          # Shared data models
│   │   ├── widgets/         # Reusable widgets
│   │   └── services/        # Shared services
│   └── main.dart            # App entry point
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── assets/
│   ├── images/
│   ├── fonts/
│   └── icons/
├── pubspec.yaml             # Dependencies
├── analysis_options.yaml    # Linter rules
└── README.md
```

## Tech Stack

- **Framework**: Flutter 3.16+
- **Language**: Dart 3.2+
- **State Management**: flutter_bloc (BLoC pattern)
- **Routing**: go_router
- **HTTP Client**: dio
- **Local Storage**: hive
- **Auth**: firebase_auth
- **Push Notifications**: firebase_messaging
- **Analytics**: firebase_analytics
- **Video Calls**: jitsi_meet_flutter_sdk
- **Dependency Injection**: get_it

## Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5

  # Networking
  dio: ^5.4.0
  retrofit: ^4.0.3

  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2

  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_messaging: ^14.7.9
  firebase_analytics: ^10.8.0

  # UI
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  flutter_svg: ^2.0.9

  # Navigation
  go_router: ^13.0.0

  # Dependency Injection
  get_it: ^7.6.4

  # Utils
  intl: ^0.18.1
  logger: ^2.0.2
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
```

## Getting Started

### Prerequisites

- Flutter SDK 3.16+
- Dart SDK 3.2+
- Android Studio or VS Code with Flutter extensions
- iOS development: Xcode 15+ (macOS only)

### Installation

```bash
# Clone repository
git clone https://github.com/adyela/adyela.git
cd adyela/apps/mobile-patient

# Install dependencies
flutter pub get

# Generate code (for freezed, json_serializable)
flutter pub run build_runner build --delete-conflicting-outputs

# Run on device/emulator
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (requires macOS)
flutter build ios --release

# Web
flutter build web --release
```

## Environment Configuration

### Firebase Setup

1. Create Firebase project at https://console.firebase.google.com
2. Add iOS and Android apps to project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place files in respective platform directories

### Environment Variables

Create `lib/core/config/env.dart`:

```dart
class Environment {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://staging.adyela.care/api',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'staging',
  );
}
```

Run with environment variables:

```bash
flutter run --dart-define=API_BASE_URL=https://staging.adyela.care/api --dart-define=ENVIRONMENT=staging
```

## Screens

### Authentication Flow
1. **Splash Screen** - App loading and initialization
2. **Onboarding** - 3-screen intro for new users
3. **Login** - Email/password or social login
4. **Register** - New user registration
5. **Forgot Password** - Password reset

### Main App Flow
1. **Home** - Professional search and recommendations
2. **Search** - Advanced search with filters
3. **Professional Profile** - View details and availability
4. **Booking** - 3-step appointment booking
5. **Appointments** - List of upcoming/past appointments
6. **Profile** - User profile and settings

## State Management (BLoC)

Example BLoC structure for authentication:

```dart
// auth_event.dart
abstract class AuthEvent extends Equatable {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
}

// auth_state.dart
abstract class AuthState extends Equatable {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
}
class AuthError extends AuthState {
  final String message;
}

// auth_bloc.dart
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;

  AuthBloc({required this.loginUseCase}) : super(AuthInitial());

  @override
  Stream<AuthState> mapEventToState(AuthEvent event) async* {
    if (event is LoginRequested) {
      yield AuthLoading();
      try {
        final user = await loginUseCase(email: event.email, password: event.password);
        yield AuthAuthenticated(user: user);
      } catch (e) {
        yield AuthError(message: e.toString());
      }
    }
  }
}
```

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Test Structure

```dart
// Example widget test
testWidgets('Login button triggers login event', (tester) async {
  final authBloc = MockAuthBloc();

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider.value(
        value: authBloc,
        child: LoginScreen(),
      ),
    ),
  );

  await tester.enterText(find.byKey(Key('email_field')), 'test@example.com');
  await tester.enterText(find.byKey(Key('password_field')), 'password123');
  await tester.tap(find.byKey(Key('login_button')));

  verify(() => authBloc.add(LoginRequested(
    email: 'test@example.com',
    password: 'password123',
  ))).called(1);
});
```

## Performance Targets

- **Cold start**: <3 seconds
- **Frame rate**: 60 FPS (no jank)
- **APK size**: <20 MB
- **Memory usage**: <150 MB
- **Network requests**: <2 seconds p95

## Accessibility

- Screen reader support (TalkBack, VoiceOver)
- Minimum tap targets: 48x48 dp
- Sufficient color contrast (WCAG AA)
- Font scaling support
- Keyboard navigation (web)

## Localization

Supported languages:
- 🇪🇸 Spanish (primary)
- 🇺🇸 English
- 🇧🇷 Portuguese (future)

Using `intl` package for translations.

## CI/CD

GitHub Actions workflow:
1. Lint and format check
2. Unit and widget tests
3. Build Android APK
4. Build iOS IPA (if on macOS runner)
5. Upload to Firebase App Distribution (staging)
6. Deploy to stores (production)

## Related Documentation

- [Health Platform PRD](../../docs/planning/health-platform-prd.md)
- [Testing Strategy](../../docs/quality/testing-strategy-microservices.md)
- [UX/UI Design System](../../docs/planning/health-platform-strategy.plan.md#9-estrategia-de-uxui-y-design-system)

---

**Version**: 0.1.0
**Platform**: iOS 14+, Android API 24+, Web
**Status**: 🚧 In Development
