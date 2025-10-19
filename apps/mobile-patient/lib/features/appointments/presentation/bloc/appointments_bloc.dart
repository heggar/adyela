import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/cancel_appointment_usecase.dart';
import '../../domain/usecases/create_appointment_usecase.dart';
import '../../domain/usecases/get_user_appointments_usecase.dart';
import 'appointments_event.dart';
import 'appointments_state.dart';

/// Appointments BLoC
class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  final GetUserAppointmentsUseCase getUserAppointmentsUseCase;
  final CreateAppointmentUseCase createAppointmentUseCase;
  final CancelAppointmentUseCase cancelAppointmentUseCase;

  AppointmentsBloc({
    required this.getUserAppointmentsUseCase,
    required this.createAppointmentUseCase,
    required this.cancelAppointmentUseCase,
  }) : super(const AppointmentsInitial()) {
    on<LoadUserAppointmentsEvent>(_onLoadUserAppointments);
    on<CreateAppointmentEvent>(_onCreateAppointment);
    on<CancelAppointmentEvent>(_onCancelAppointment);
  }

  /// Handle load user appointments
  Future<void> _onLoadUserAppointments(
    LoadUserAppointmentsEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(const AppointmentsLoading());

    final result = await getUserAppointmentsUseCase(
      status: event.status,
      limit: 50,
    );

    result.fold(
      (failure) => emit(AppointmentsError(message: failure.message)),
      (appointments) => emit(AppointmentsLoaded(
        appointments: appointments,
        filter: event.status,
      )),
    );
  }

  /// Handle create appointment
  Future<void> _onCreateAppointment(
    CreateAppointmentEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(const AppointmentsLoading());

    final result = await createAppointmentUseCase(
      professionalId: event.professionalId,
      scheduledAt: event.scheduledAt,
      durationMinutes: event.durationMinutes,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(AppointmentsError(message: failure.message)),
      (appointment) => emit(AppointmentCreated(appointment: appointment)),
    );
  }

  /// Handle cancel appointment
  Future<void> _onCancelAppointment(
    CancelAppointmentEvent event,
    Emitter<AppointmentsState> emit,
  ) async {
    emit(const AppointmentsLoading());

    final result = await cancelAppointmentUseCase(
      id: event.id,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(AppointmentsError(message: failure.message)),
      (appointment) => emit(AppointmentCancelled(appointment: appointment)),
    );
  }
}
