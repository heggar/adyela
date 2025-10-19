import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_core/flutter_core.dart';

/// Professional appointments page with status filtering
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pendientes'),
            Tab(text: 'Confirmadas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList(AppointmentStatus.pending),
          _buildAppointmentsList(AppointmentStatus.confirmed),
          _buildAppointmentsList(AppointmentStatus.completed),
        ],
      ),
    );
  }

  Widget _buildAppointmentsList(AppointmentStatus status) {
    // TODO: Replace with BLoC integration
    final mockAppointments = <Appointment>[];

    if (mockAppointments.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today,
        title: 'No hay citas',
        message: _getEmptyMessage(status),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh appointments
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockAppointments.length,
        itemBuilder: (context, index) {
          final appointment = mockAppointments[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AppointmentCard(
              appointment: appointment,
              professionalName: 'Nombre del Paciente', // TODO: Get from patient data
              onTap: () {
                // TODO: Navigate to appointment details
              },
              onCancel: status == AppointmentStatus.pending ||
                      status == AppointmentStatus.confirmed
                  ? () => _showConfirmDialog(appointment, 'cancelar')
                  : null,
              onJoinMeeting: status == AppointmentStatus.confirmed
                  ? () {
                      // TODO: Join video call
                    }
                  : null,
            ),
          );
        },
      ),
    );
  }

  String _getEmptyMessage(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return 'No tienes citas pendientes de confirmar';
      case AppointmentStatus.confirmed:
        return 'No tienes citas confirmadas próximamente';
      case AppointmentStatus.completed:
        return 'Aún no has completado ninguna cita';
      default:
        return 'No hay citas para mostrar';
    }
  }

  Future<void> _showConfirmDialog(Appointment appointment, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿$action cita?'),
        content: Text('¿Estás seguro que deseas $action esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement cancel/confirm logic
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cita ${action}da exitosamente')),
        );
      }
    }
  }
}
