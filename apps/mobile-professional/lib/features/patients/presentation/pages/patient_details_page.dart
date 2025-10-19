import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:flutter_core/flutter_core.dart';

/// Patient details page for professionals
class PatientDetailsPage extends StatefulWidget {
  final String patientId;

  const PatientDetailsPage({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage>
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
    // TODO: Replace with actual patient data
    final patientName = 'María García López';

    return Scaffold(
      appBar: AppBar(
        title: Text(patientName),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              // TODO: Send message to patient
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Patient header
          _buildPatientHeader(context),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Info'),
              Tab(text: 'Historial'),
              Tab(text: 'Notas'),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(context),
                _buildHistoryTab(context),
                _buildNotesTab(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Schedule new appointment
        },
        icon: const Icon(Icons.add),
        label: const Text('Nueva Cita'),
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              'MG',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'María García López',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 4),
                    const Text('32 años'),
                    const SizedBox(width: 16),
                    const Icon(Icons.medical_services, size: 16),
                    const SizedBox(width: 4),
                    const Text('5 consultas'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            context,
            title: 'Información Personal',
            child: Column(
              children: [
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
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.cake,
                  label: 'Fecha de Nacimiento',
                  value: '15/05/1992',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.transgender,
                  label: 'Género',
                  value: 'Femenino',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context,
            title: 'Información Médica',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context,
                  icon: Icons.bloodtype,
                  label: 'Grupo Sanguíneo',
                  value: 'A+',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.warning,
                  label: 'Alergias',
                  value: 'Penicilina',
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.medication,
                  label: 'Medicación Actual',
                  value: 'Ninguna',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    // TODO: Replace with actual appointments data
    final mockAppointments = <Appointment>[];

    if (mockAppointments.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'Sin historial',
        message: 'No hay citas previas con este paciente',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockAppointments.length,
      itemBuilder: (context, index) {
        final appointment = mockAppointments[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: AppointmentCard(
            appointment: appointment,
            professionalName: 'María García López',
            onTap: () {
              // TODO: Navigate to appointment details
            },
          ),
        );
      },
    );
  }

  Widget _buildNotesTab(BuildContext context) {
    // TODO: Replace with actual notes data
    final mockNotes = <Map<String, dynamic>>[];

    if (mockNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyState(
              icon: Icons.note,
              title: 'Sin notas',
              message: 'No hay notas sobre este paciente',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                // TODO: Add note
              },
              icon: const Icon(Icons.add),
              label: const Text('Agregar Nota'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mockNotes.length,
      itemBuilder: (context, index) {
        final note = mockNotes[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.note, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      note['date'],
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(note['content']),
              ],
            ),
          ),
        );
      },
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
}
