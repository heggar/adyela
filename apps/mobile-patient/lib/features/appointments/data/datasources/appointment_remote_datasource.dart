import 'package:dio/dio.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/exceptions.dart';

/// Abstract interface for appointment remote data source
abstract class AppointmentRemoteDataSource {
  Future<Appointment> createAppointment({
    required String professionalId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? reason,
  });

  Future<Appointment> getAppointmentById(String id);

  Future<List<Appointment>> getUserAppointments({
    AppointmentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  });

  Future<Appointment> cancelAppointment({
    required String id,
    String? reason,
  });

  Future<List<DateTime>> getAvailableSlots({
    required String professionalId,
    required DateTime date,
    int durationMinutes = 30,
  });
}

/// Implementation of appointment remote data source using Dio
class AppointmentRemoteDataSourceImpl implements AppointmentRemoteDataSource {
  final Dio dio;

  AppointmentRemoteDataSourceImpl({required this.dio});

  @override
  Future<Appointment> createAppointment({
    required String professionalId,
    required DateTime scheduledAt,
    required int durationMinutes,
    String? reason,
  }) async {
    try {
      final response = await dio.post(
        '/appointments',
        data: {
          'professional_id': professionalId,
          'scheduled_at': scheduledAt.toIso8601String(),
          'duration_minutes': durationMinutes,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 201) {
        return Appointment.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to create appointment: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Appointment> getAppointmentById(String id) async {
    try {
      final response = await dio.get('/appointments/$id');

      if (response.statusCode == 200) {
        return Appointment.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to get appointment: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<Appointment>> getUserAppointments({
    AppointmentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status.value;
      if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await dio.get(
        '/appointments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final appointments = (response.data['appointments'] as List)
            .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
            .toList();
        return appointments;
      } else {
        throw ServerException('Failed to get appointments: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Appointment> cancelAppointment({
    required String id,
    String? reason,
  }) async {
    try {
      final response = await dio.post(
        '/appointments/$id/cancel',
        data: {
          if (reason != null) 'cancellation_reason': reason,
        },
      );

      if (response.statusCode == 200) {
        return Appointment.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to cancel appointment: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<DateTime>> getAvailableSlots({
    required String professionalId,
    required DateTime date,
    int durationMinutes = 30,
  }) async {
    try {
      final response = await dio.get(
        '/professionals/$professionalId/available-slots',
        queryParameters: {
          'date': date.toIso8601String(),
          'duration': durationMinutes,
        },
      );

      if (response.statusCode == 200) {
        final slots = (response.data['slots'] as List)
            .map((slot) => DateTime.parse(slot as String))
            .toList();
        return slots;
      } else {
        throw ServerException('Failed to get available slots: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  /// Handle Dio errors and convert to appropriate exceptions
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException('Connection timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data['message'] as String? ?? 'Unknown error';

        if (statusCode == 404) {
          return NotFoundException('Appointment not found');
        } else if (statusCode == 409) {
          return ValidationException('Time slot not available');
        } else if (statusCode == 422) {
          return ValidationException(message);
        } else {
          return ServerException(message);
        }
      case DioExceptionType.cancel:
        return ServerException('Request cancelled');
      case DioExceptionType.connectionError:
        return NetworkException('No internet connection');
      default:
        return ServerException('Unexpected error: ${error.message}');
    }
  }
}
