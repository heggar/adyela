import 'package:dartz/dartz.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/failures.dart';
import '../repositories/appointment_repository.dart';

/// Use case for getting user appointments
class GetUserAppointmentsUseCase {
  final AppointmentRepository repository;

  GetUserAppointmentsUseCase({required this.repository});

  Future<Either<Failure, List<Appointment>>> call({
    AppointmentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    return await repository.getUserAppointments(
      status: status,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }
}
