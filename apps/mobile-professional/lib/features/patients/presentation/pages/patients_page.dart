import 'package:flutter/material.dart';
import 'package:flutter_shared/flutter_shared.dart';

/// My patients list page for professionals
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  State<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Pacientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar paciente...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Patients list
          Expanded(
            child: _buildPatientsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientsList() {
    // TODO: Replace with BLoC integration
    final mockPatients = <Map<String, dynamic>>[];

    if (mockPatients.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No hay pacientes',
        message: 'Aún no has atendido a ningún paciente',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh patients
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: mockPatients.length,
        itemBuilder: (context, index) {
          final patient = mockPatients[index];
          return _buildPatientCard(patient);
        },
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            patient['name'][0].toUpperCase(),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(patient['name']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text('${patient['appointmentsCount']} citas'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 4),
                Text('Última visita: ${patient['lastVisit']}'),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            // TODO: Navigate to patient details
          },
        ),
        onTap: () {
          // TODO: Navigate to patient details
        },
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Ordenar por',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sort_by_alpha),
              title: const Text('Nombre (A-Z)'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Sort by name
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Última visita'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Sort by last visit
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Más citas'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Sort by appointments count
              },
            ),
          ],
        ),
      ),
    );
  }
}
