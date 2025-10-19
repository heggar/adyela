import 'package:equatable/equatable.dart';
import 'package:flutter_core/flutter_core.dart';

/// Base appointments state
abstract class AppointmentsState extends Equatable {
  const AppointmentsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class AppointmentsInitial extends AppointmentsState {
  const AppointmentsInitial();
}

/// Loading state
class AppointmentsLoading extends AppointmentsState {
  const AppointmentsLoading();
}

/// Appointments loaded
class AppointmentsLoaded extends AppointmentsState {
  final List<Appointment> appointments;
  final AppointmentStatus? filter;

  const AppointmentsLoaded({
    required this.appointments,
    this.filter,
  });

  @override
  List<Object?> get props => [appointments, filter];

  List<Appointment> get upcomingAppointments =>
      appointments.where((a) => a.isUpcoming).toList();

  List<Appointment> get pastAppointments =>
      appointments.where((a) => a.isPast && a.status.isFinished).toList();
}

/// Appointment created
class AppointmentCreated extends AppointmentsState {
  final Appointment appointment;

  const AppointmentCreated({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

/// Appointment cancelled
class AppointmentCancelled extends AppointmentsState {
  final Appointment appointment;

  const AppointmentCancelled({required this.appointment});

  @override
  List<Object?> get props => [appointment];
}

/// Error state
class AppointmentsError extends AppointmentsState {
  final String message;

  const AppointmentsError({required this.message});

  @override
  List<Object?> get props => [message];
}
