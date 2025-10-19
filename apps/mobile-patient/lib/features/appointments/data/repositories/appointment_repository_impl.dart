import 'package:dartz/dartz.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';

/// Implementation of AppointmentRepository
class AppointmentRepositoryImpl implements AppointmentRepository {
  final AppointmentRemoteDataSource remoteDataSource;

  AppointmentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Appointment>> createAppointment({
    required String professionalId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? reason,
  }) async {
    try {
      final appointment = await remoteDataSource.createAppointment(
        professionalId: professionalId,
        scheduledAt: scheduledAt,
        durationMinutes: durationMinutes,
        reason: reason,
      );
      return Right(appointment);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Appointment>> getAppointmentById(String id) async {
    try {
      final appointment = await remoteDataSource.getAppointmentById(id);
      return Right(appointment);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Appointment>>> getUserAppointments({
    AppointmentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final appointments = await remoteDataSource.getUserAppointments(
        status: status,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
        offset: offset,
      );
      return Right(appointments);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Appointment>> cancelAppointment({
    required String id,
    String? reason,
  }) async {
    try {
      final appointment = await remoteDataSource.cancelAppointment(
        id: id,
        reason: reason,
      );
      return Right(appointment);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Appointment>> updateAppointment({
    required String id,
    DateTime? scheduledAt,
    String? reason,
    String? notes,
  }) async {
    // TODO: Implement updateAppointment in remote datasource
    return const Left(ServerFailure('Not implemented'));
  }

  @override
  Future<Either<Failure, List<DateTime>>> getAvailableSlots({
    required String professionalId,
    required DateTime date,
    int durationMinutes = 30,
  }) async {
    try {
      final slots = await remoteDataSource.getAvailableSlots(
        professionalId: professionalId,
        date: date,
        durationMinutes: durationMinutes,
      );
      return Right(slots);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }
}
