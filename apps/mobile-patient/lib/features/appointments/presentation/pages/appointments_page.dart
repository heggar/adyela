import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:flutter_shared/flutter_shared.dart';

import '../bloc/appointments_bloc.dart';
import '../bloc/appointments_event.dart';
import '../bloc/appointments_state.dart';

/// Appointments list page
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
    _tabController = TabController(length: 2, vsync: this);
    context.read<AppointmentsBloc>().add(const LoadUserAppointmentsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onCancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppointmentsBloc>().add(
                    CancelAppointmentEvent(id: appointment.id),
                  );
            },
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Próximas'),
            Tab(text: 'Pasadas'),
          ],
        ),
      ),
      body: BlocConsumer<AppointmentsBloc, AppointmentsState>(
        listener: (context, state) {
          if (state is AppointmentCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cita cancelada exitosamente')),
            );
            // Reload appointments
            context
                .read<AppointmentsBloc>()
                .add(const LoadUserAppointmentsEvent());
          }

          if (state is AppointmentsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is AppointmentsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AppointmentsLoaded) {
            return TabBarView(
              controller: _tabController,
              children: [
                // Upcoming appointments
                _buildAppointmentsList(
                  state.upcomingAppointments,
                  emptyMessage: 'No tienes citas próximas',
                  canCancel: true,
                ),

                // Past appointments
                _buildAppointmentsList(
                  state.pastAppointments,
                  emptyMessage: 'No tienes citas pasadas',
                  canCancel: false,
                ),
              ],
            );
          }

          return EmptyState(
            icon: Icons.calendar_today,
            title: 'Sin citas',
            message: 'Aún no has agendado ninguna cita',
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsList(
    List<Appointment> appointments, {
    required String emptyMessage,
    required bool canCancel,
  }) {
    if (appointments.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy,
        title: emptyMessage,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppointmentCard(
            appointment: appointment,
            professionalName: 'Dr. Nombre',  // TODO: Get from professional data
            onTap: () {
              // TODO: Navigate to appointment details
            },
            onCancel: canCancel && appointment.status.canCancel
                ? () => _onCancelAppointment(appointment)
                : null,
            onJoinMeeting: appointment.meetingUrl != null
                ? () {
                    // TODO: Join video meeting
                  }
                : null,
          ),
        );
      },
    );
  }
}
