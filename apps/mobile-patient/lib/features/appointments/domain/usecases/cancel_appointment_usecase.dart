import 'package:dartz/dartz.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';

/// Use case for cancelling appointments
class CancelAppointmentUseCase {
  final AppointmentRepository repository;

  CancelAppointmentUseCase({required this.repository});

  Future<Either<Failure, Appointment>> call({
    required String id,
    String? reason,
  }) async {
    return await repository.cancelAppointment(
      id: id,
      reason: reason,
    );
  }
}
