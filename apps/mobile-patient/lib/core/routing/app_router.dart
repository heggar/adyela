import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screen imports (to be created)
// import '../../features/auth/presentation/pages/login_page.dart';
// import '../../features/auth/presentation/pages/register_page.dart';
// import '../../features/search/presentation/pages/search_page.dart';
// import '../../features/appointments/presentation/pages/appointments_list_page.dart';
// import '../../features/appointments/presentation/pages/appointment_details_page.dart';
// import '../../features/appointments/presentation/pages/book_appointment_page.dart';
// import '../../features/profile/presentation/pages/profile_page.dart';

/// Application router configuration using GoRouter
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
          path: AppRoutes.home,
          name: AppRouteNames.home,
          builder: (context, state) => const HomePage(),
          routes: [
            // Search
            GoRoute(
              path: AppRoutes.search.substring(1), // Remove leading '/'
              name: AppRouteNames.search,
              builder: (context, state) => const SearchPage(),
            ),

            // Appointments
            GoRoute(
              path: AppRoutes.appointments.substring(1),
              name: AppRouteNames.appointments,
              builder: (context, state) => const AppointmentsListPage(),
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

            // Book appointment
            GoRoute(
              path: AppRoutes.bookAppointment.substring(1),
              name: AppRouteNames.bookAppointment,
              builder: (context, state) {
                final professionalId = state.uri.queryParameters['professionalId'];
                return BookAppointmentPage(professionalId: professionalId);
              },
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
    //   return AppRoutes.home;
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
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
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
  static const String home = '/home';
  static const String search = '/search';
  static const String appointments = '/appointments';
  static const String appointmentDetails = '/appointments/:id';
  static const String bookAppointment = '/book-appointment';
  static const String profile = '/profile';
}

/// Route names for navigation
class AppRouteNames {
  AppRouteNames._();

  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String home = 'home';
  static const String search = 'search';
  static const String appointments = 'appointments';
  static const String appointmentDetails = 'appointment-details';
  static const String bookAppointment = 'book-appointment';
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
      appBar: AppBar(title: const Text('Login')),
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Home Page - To be implemented')),
    );
  }
}

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Professionals')),
      body: const Center(child: Text('Search Page - To be implemented')),
    );
  }
}

class AppointmentsListPage extends StatelessWidget {
  const AppointmentsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Appointments')),
      body: const Center(child: Text('Appointments List - To be implemented')),
    );
  }
}

class AppointmentDetailsPage extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailsPage({super.key, required this.appointmentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment Details')),
      body: Center(child: Text('Appointment $appointmentId - To be implemented')),
    );
  }
}

class BookAppointmentPage extends StatelessWidget {
  final String? professionalId;

  const BookAppointmentPage({super.key, this.professionalId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Appointment')),
      body: const Center(child: Text('Book Appointment - To be implemented')),
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: const Center(child: Text('Profile Page - To be implemented')),
    );
  }
}
