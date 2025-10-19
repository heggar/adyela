import 'package:flutter/material.dart';

/// Professional profile page
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(context),
            const SizedBox(height: 32),

            // Statistics
            _buildStatistics(context),
            const SizedBox(height: 24),

            // Menu options
            _buildMenuSection(
              context,
              title: 'Información Profesional',
              items: [
                _MenuItem(
                  icon: Icons.medical_services,
                  title: 'Especialidad',
                  subtitle: 'Fisioterapia',
                  onTap: () {
                    // TODO: Edit specialty
                  },
                ),
                _MenuItem(
                  icon: Icons.badge,
                  title: 'Número de Colegiado',
                  subtitle: '12345678',
                  onTap: () {
                    // TODO: Edit license number
                  },
                ),
                _MenuItem(
                  icon: Icons.verified,
                  title: 'Verificación',
                  subtitle: 'Verificado',
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                  onTap: () {
                    // TODO: View verification details
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildMenuSection(
              context,
              title: 'Configuración',
              items: [
                _MenuItem(
                  icon: Icons.calendar_today,
                  title: 'Disponibilidad',
                  subtitle: 'Gestionar horarios',
                  onTap: () {
                    // TODO: Navigate to availability settings
                  },
                ),
                _MenuItem(
                  icon: Icons.attach_money,
                  title: 'Tarifas',
                  subtitle: 'Configurar precios',
                  onTap: () {
                    // TODO: Navigate to pricing settings
                  },
                ),
                _MenuItem(
                  icon: Icons.notifications,
                  title: 'Notificaciones',
                  subtitle: 'Preferencias de notificación',
                  onTap: () {
                    // TODO: Navigate to notification settings
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildMenuSection(
              context,
              title: 'Ayuda y Soporte',
              items: [
                _MenuItem(
                  icon: Icons.help,
                  title: 'Centro de Ayuda',
                  onTap: () {
                    // TODO: Navigate to help center
                  },
                ),
                _MenuItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacidad',
                  onTap: () {
                    // TODO: Navigate to privacy policy
                  },
                ),
                _MenuItem(
                  icon: Icons.description,
                  title: 'Términos y Condiciones',
                  onTap: () {
                    // TODO: Navigate to terms
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Logout button
            OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context),
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
            const SizedBox(height: 16),

            // Version
            Text(
              'Versión 0.1.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                'Dr',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  onPressed: () {
                    // TODO: Change profile photo
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Dr. Juan Pérez',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Fisioterapeuta',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 20),
            const SizedBox(width: 4),
            Text(
              '4.8',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(width: 4),
            Text(
              '(42 valoraciones)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatistics(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.people,
            label: 'Pacientes',
            value: '42',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.calendar_today,
            label: 'Citas',
            value: '156',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.access_time,
            label: 'Años',
            value: '8',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: items
                .asMap()
                .entries
                .map((entry) {
                  final isLast = entry.key == items.length - 1;
                  return Column(
                    children: [
                      ListTile(
                        leading: Icon(entry.value.icon),
                        title: Text(entry.value.title),
                        subtitle: entry.value.subtitle != null
                            ? Text(entry.value.subtitle!)
                            : null,
                        trailing: entry.value.trailing ??
                            const Icon(Icons.chevron_right),
                        onTap: entry.value.onTap,
                      ),
                      if (!isLast) const Divider(height: 1),
                    ],
                  );
                })
                .toList(),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO: Implement logout
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada')),
      );
    }
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });
}
