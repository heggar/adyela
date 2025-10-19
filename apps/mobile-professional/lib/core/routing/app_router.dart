import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screen imports
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/appointments/presentation/pages/appointments_page.dart';
import '../../features/appointments/presentation/pages/appointment_details_page.dart';
import '../../features/patients/presentation/pages/patients_page.dart';
import '../../features/patients/presentation/pages/patient_details_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
// import '../../features/auth/presentation/pages/login_page.dart';

/// Application router configuration using GoRouter for professional app
class AppRouter {
  late final GoRouter router;

  AppRouter() {
    router = GoRouter(
      debugLogDiagnostics: true,
      initialLocation: AppRoutes.splash,
      routes: _routes,
      redirect: _redirect,
      errorBuilder: _errorBuilder,
    );
  }

  /// Route definitions
  List<RouteBase> get _routes => [
        // Splash
        GoRoute(
          path: AppRoutes.splash,
          name: AppRouteNames.splash,
          builder: (context, state) => const SplashPage(),
        ),

        // Auth routes
        GoRoute(
          path: AppRoutes.login,
          name: AppRouteNames.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.register,
          name: AppRouteNames.register,
          builder: (context, state) => const RegisterPage(),
        ),

        // Main navigation routes
        GoRoute(
          path: AppRoutes.dashboard,
          name: AppRouteNames.dashboard,
          builder: (context, state) => const DashboardPage(),
          routes: [
            // Appointments
            GoRoute(
              path: AppRoutes.appointments.substring(1),
              name: AppRouteNames.appointments,
              builder: (context, state) => const AppointmentsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: AppRouteNames.appointmentDetails,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return AppointmentDetailsPage(appointmentId: id);
                  },
                ),
              ],
            ),

            // Patients
            GoRoute(
              path: AppRoutes.patients.substring(1),
              name: AppRouteNames.patients,
              builder: (context, state) => const PatientsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: AppRouteNames.patientDetails,
                  builder: (context, state) {
                    final id = state.pathParameters['id']!;
                    return PatientDetailsPage(patientId: id);
                  },
                ),
              ],
            ),

            // Calendar
            GoRoute(
              path: AppRoutes.calendar.substring(1),
              name: AppRouteNames.calendar,
              builder: (context, state) => const CalendarPage(),
            ),

            // Profile
            GoRoute(
              path: AppRoutes.profile.substring(1),
              name: AppRouteNames.profile,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ];

  /// Redirect logic for authentication
  String? _redirect(BuildContext context, GoRouterState state) {
    // TODO: Implement authentication state check
    // final isAuthenticated = authState.isAuthenticated;
    // final isAuthRoute = state.matchedLocation.startsWith('/auth');

    // if (!isAuthenticated && !isAuthRoute) {
    //   return AppRoutes.login;
    // }
    // if (isAuthenticated && isAuthRoute) {
    //   return AppRoutes.dashboard;
    // }

    return null; // No redirect
  }

  /// Error page builder
  Widget _errorBuilder(BuildContext context, GoRouterState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Route paths
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String appointments = '/appointments';
  static const String appointmentDetails = '/appointments/:id';
  static const String patients = '/patients';
  static const String patientDetails = '/patients/:id';
  static const String calendar = '/calendar';
  static const String profile = '/profile';
}

/// Route names for navigation
class AppRouteNames {
  AppRouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String dashboard = 'dashboard';
  static const String appointments = 'appointments';
  static const String appointmentDetails = 'appointment-details';
  static const String patients = 'patients';
  static const String patientDetails = 'patient-details';
  static const String calendar = 'calendar';
  static const String profile = 'profile';
}

// Placeholder pages (to be replaced with actual implementations)

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Professional')),
      body: const Center(child: Text('Login Page - To be implemented')),
    );
  }
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: const Center(child: Text('Register Page - To be implemented')),
    );
  }
}

// DashboardPage moved to features/dashboard/presentation/pages/dashboard_page.dart

// AppointmentsPage and AppointmentDetailsPage moved to features/appointments/presentation/pages/

// PatientsPage and PatientDetailsPage moved to features/patients/presentation/pages/

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const Center(child: Text('Calendar - To be implemented')),
    );
  }
}

// ProfilePage moved to features/profile/presentation/pages/profile_page.dart
