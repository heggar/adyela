import 'package:dartz/dartz.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';

/// Use case for creating appointments
class CreateAppointmentUseCase {
  final AppointmentRepository repository;

  CreateAppointmentUseCase({required this.repository});

  Future<Either<Failure, Appointment>> call({
    required String professionalId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? reason,
  }) async {
    // Validation: scheduled time must be in the future
    if (scheduledAt.isBefore(DateTime.now())) {
      return const Left(ValidationFailure('La fecha debe ser en el futuro'));
    }

    // Validation: minimum advance booking time (2 hours)
    final minAdvanceTime = DateTime.now().add(const Duration(hours: 2));
    if (scheduledAt.isBefore(minAdvanceTime)) {
      return const Left(
        ValidationFailure('Debes reservar con al menos 2 horas de anticipación'),
      );
    }

    return await repository.createAppointment(
      professionalId: professionalId,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      reason: reason,
    );
  }
}
