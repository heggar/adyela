import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';

/// Professional dashboard page with metrics and upcoming appointments
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Refresh dashboard data
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              Text(
                'Bienvenido, Dr. Nombre',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Aquí está tu resumen de hoy',
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 24),

              // Metrics cards
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.event,
                      label: 'Hoy',
                      value: '5',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.people_outline,
                      label: 'Pacientes',
                      value: '42',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.star_outline,
                      label: 'Rating',
                      value: '4.8',
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      context,
                      icon: Icons.attach_money,
                      label: 'Este Mes',
                      value: '\$2.5K',
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Upcoming appointments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Próximas Citas',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all appointments
                    },
                    child: const Text('Ver todas'),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Mock upcoming appointments (using shared AppointmentCard)
              EmptyState(
                icon: Icons.calendar_today,
                title: 'No hay citas próximas',
                message: 'No tienes citas programadas para hoy',
              ),

              // TODO: Replace with actual AppointmentCard widgets
              // ListView.builder(
              //   shrinkWrap: true,
              //   physics: const NeverScrollableScrollPhysics(),
              //   itemCount: upcomingAppointments.length,
              //   itemBuilder: (context, index) {
              //     return Padding(
              //       padding: const EdgeInsets.only(bottom: 16),
              //       child: AppointmentCard(
              //         appointment: upcomingAppointments[index],
              //         professionalName: 'Patient Name',
              //         onTap: () => navigateToDetails(),
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Navigate to create availability
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Disponibilidad'),
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
