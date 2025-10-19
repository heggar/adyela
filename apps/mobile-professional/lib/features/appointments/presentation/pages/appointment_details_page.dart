import 'package:flutter/material.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:intl/intl.dart';

/// Appointment details page for professionals
class AppointmentDetailsPage extends StatelessWidget {
  final String appointmentId;

  const AppointmentDetailsPage({
    super.key,
    required this.appointmentId,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with BLoC/repository data
    final appointment = _getMockAppointment();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Cita'),
        actions: [
          if (appointment.status == AppointmentStatus.pending ||
              appointment.status == AppointmentStatus.confirmed)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showOptionsMenu(context, appointment),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            _buildStatusCard(context, appointment),
            const SizedBox(height: 24),

            // Patient information
            _buildSection(
              context,
              title: 'Información del Paciente',
              child: _buildPatientInfo(context),
            ),
            const SizedBox(height: 24),

            // Appointment details
            _buildSection(
              context,
              title: 'Detalles de la Cita',
              child: _buildAppointmentDetails(context, appointment),
            ),
            const SizedBox(height: 24),

            // Notes section
            _buildSection(
              context,
              title: 'Notas',
              child: _buildNotes(context, appointment),
            ),
            const SizedBox(height: 24),

            // Actions
            if (appointment.status == AppointmentStatus.confirmed)
              _buildActions(context, appointment),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Appointment appointment) {
    final statusColors = {
      AppointmentStatus.pending: Colors.orange,
      AppointmentStatus.confirmed: Colors.blue,
      AppointmentStatus.inProgress: Colors.green,
      AppointmentStatus.completed: Colors.grey,
      AppointmentStatus.cancelled: Colors.red,
      AppointmentStatus.noShow: Colors.deepOrange,
    };

    final statusLabels = {
      AppointmentStatus.pending: 'Pendiente',
      AppointmentStatus.confirmed: 'Confirmada',
      AppointmentStatus.inProgress: 'En Progreso',
      AppointmentStatus.completed: 'Completada',
      AppointmentStatus.cancelled: 'Cancelada',
      AppointmentStatus.noShow: 'No Asistió',
    };

    final color = statusColors[appointment.status] ?? Colors.grey;
    final label = statusLabels[appointment.status] ?? 'Desconocido';

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estado: $label',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy - HH:mm', 'es')
                        .format(appointment.scheduledAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfo(BuildContext context) {
    // TODO: Get patient data from repository
    return Column(
      children: [
        _buildInfoRow(
          context,
          icon: Icons.person,
          label: 'Nombre',
          value: 'María García López',
        ),
        const Divider(height: 24),
        _buildInfoRow(
          context,
          icon: Icons.calendar_today,
          label: 'Edad',
          value: '32 años',
        ),
        const Divider(height: 24),
        _buildInfoRow(
          context,
          icon: Icons.phone,
          label: 'Teléfono',
          value: '+34 612 345 678',
        ),
        const Divider(height: 24),
        _buildInfoRow(
          context,
          icon: Icons.email,
          label: 'Email',
          value: 'maria.garcia@example.com',
        ),
      ],
    );
  }

  Widget _buildAppointmentDetails(BuildContext context, Appointment appointment) {
    return Column(
      children: [
        _buildInfoRow(
          context,
          icon: Icons.access_time,
          label: 'Hora',
          value: DateFormat('HH:mm', 'es').format(appointment.scheduledAt),
        ),
        const Divider(height: 24),
        _buildInfoRow(
          context,
          icon: Icons.timelapse,
          label: 'Duración',
          value: '30 minutos',
        ),
        const Divider(height: 24),
        _buildInfoRow(
          context,
          icon: Icons.videocam,
          label: 'Tipo',
          value: 'Videoconsulta',
        ),
        if (appointment.reason != null) ...[
          const Divider(height: 24),
          _buildInfoRow(
            context,
            icon: Icons.note,
            label: 'Motivo',
            value: appointment.reason!,
          ),
        ],
      ],
    );
  }

  Widget _buildNotes(BuildContext context, Appointment appointment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (appointment.notes != null && appointment.notes!.isNotEmpty)
          Text(
            appointment.notes!,
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          Text(
            'No hay notas para esta cita',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Add/edit notes
          },
          icon: const Icon(Icons.edit_note),
          label: Text(
            appointment.notes != null && appointment.notes!.isNotEmpty
                ? 'Editar Notas'
                : 'Agregar Notas',
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, Appointment appointment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            // TODO: Join video call
          },
          icon: const Icon(Icons.videocam),
          label: const Text('Iniciar Videoconsulta'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            // TODO: Send message to patient
          },
          icon: const Icon(Icons.message),
          label: const Text('Enviar Mensaje'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu(BuildContext context, Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (appointment.status == AppointmentStatus.pending)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Confirmar Cita'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Confirm appointment
                },
              ),
            if (appointment.status == AppointmentStatus.pending ||
                appointment.status == AppointmentStatus.confirmed)
              ListTile(
                leading: const Icon(Icons.schedule, color: Colors.blue),
                title: const Text('Reprogramar'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Reschedule appointment
                },
              ),
            if (appointment.status == AppointmentStatus.pending ||
                appointment.status == AppointmentStatus.confirmed)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancelar Cita'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Cancel appointment
                },
              ),
            if (appointment.status == AppointmentStatus.confirmed)
              ListTile(
                leading: const Icon(Icons.person_off, color: Colors.orange),
                title: const Text('Marcar como No Asistió'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Mark as no-show
                },
              ),
          ],
        ),
      ),
    );
  }

  // Mock data - TODO: Remove when integrating with repository
  Appointment _getMockAppointment() {
    return Appointment(
      id: appointmentId,
      patientId: 'patient-123',
      professionalId: 'prof-456',
      scheduledAt: DateTime.now().add(const Duration(hours: 2)),
      status: AppointmentStatus.confirmed,
      reason: 'Consulta de seguimiento',
      notes: null,
      meetingUrl: null,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    );
  }
}
