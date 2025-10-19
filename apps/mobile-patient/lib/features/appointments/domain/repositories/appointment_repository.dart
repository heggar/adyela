import 'package:dartz/dartz.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/failures.dart';

/// Appointment repository interface
abstract class AppointmentRepository {
  /// Create new appointment
  Future<Either<Failure, Appointment>> createAppointment({
    required String professionalId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? reason,
  });

  /// Get appointment by ID
  Future<Either<Failure, Appointment>> getAppointmentById(String id);

  /// Get user appointments
  Future<Either<Failure, List<Appointment>>> getUserAppointments({
    AppointmentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  /// Cancel appointment
  Future<Either<Failure, Appointment>> cancelAppointment({
    required String id,
    String? reason,
  });

  /// Update appointment
  Future<Either<Failure, Appointment>> updateAppointment({
    required String id,
    DateTime? scheduledAt,
    String? reason,
    String? notes,
  });

  /// Get professional available slots
  Future<Either<Failure, List<DateTime>>> getAvailableSlots({
    required String professionalId,
    required DateTime date,
    int durationMinutes = 30,
  });
}
