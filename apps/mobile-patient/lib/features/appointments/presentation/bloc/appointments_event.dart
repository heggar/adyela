import 'package:equatable/equatable.dart';
import 'package:flutter_core/flutter_core.dart';

/// Base appointments event
abstract class AppointmentsEvent extends Equatable {
  const AppointmentsEvent();

  @override
  List<Object?> get props => [];
}

/// Load user appointments
class LoadUserAppointmentsEvent extends AppointmentsEvent {
  final AppointmentStatus? status;

  const LoadUserAppointmentsEvent({this.status});

  @override
  List<Object?> get props => [status];
}

/// Create appointment
class CreateAppointmentEvent extends AppointmentsEvent {
  final String professionalId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? reason;

  const CreateAppointmentEvent({
    required this.professionalId,
    required this.scheduledAt,
    this.durationMinutes = 30,
    this.reason,
  });

  @override
  List<Object?> get props => [professionalId, scheduledAt, durationMinutes, reason];
}

/// Cancel appointment
class CancelAppointmentEvent extends AppointmentsEvent {
  final String id;
  final String? reason;

  const CancelAppointmentEvent({
    required this.id,
    this.reason,
  });

  @override
  List<Object?> get props => [id, reason];
}
