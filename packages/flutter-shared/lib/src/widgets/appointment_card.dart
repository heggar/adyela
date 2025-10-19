import 'package:flutter/material.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:intl/intl.dart';

/// Reusable appointment card widget
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final String professionalName;
  final String? professionalPhotoUrl;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onJoinMeeting;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.professionalName,
    this.professionalPhotoUrl,
    this.onTap,
    this.onCancel,
    this.onJoinMeeting,
  });

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.inProgress:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.grey;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.noShow:
        return Colors.red.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM', 'es');
    final timeFormat = DateFormat('h:mm a', 'es');

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(
                      appointment.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(appointment.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor:
                        _getStatusColor(appointment.status).withOpacity(0.1),
                    side: BorderSide(
                      color: _getStatusColor(appointment.status),
                    ),
                  ),
                  if (appointment.isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'HOY',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Professional info
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: professionalPhotoUrl != null
                        ? NetworkImage(professionalPhotoUrl!)
                        : null,
                    child: professionalPhotoUrl == null
                        ? Text(professionalName[0])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          professionalName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (appointment.reason != null)
                          Text(
                            appointment.reason!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Date and time
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(appointment.scheduledAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    timeFormat.format(appointment.scheduledAt),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),

              // Actions
              if (appointment.status.canCancel ||
                  (appointment.meetingUrl != null &&
                      appointment.status == AppointmentStatus.confirmed))
                ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (appointment.status.canCancel && onCancel != null)
                        OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text('Cancelar'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                      if (appointment.meetingUrl != null &&
                          appointment.status == AppointmentStatus.confirmed &&
                          onJoinMeeting != null)
                        ...[
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: onJoinMeeting,
                            icon: const Icon(Icons.videocam, size: 18),
                            label: const Text('Unirse'),
                          ),
                        ],
                    ],
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
