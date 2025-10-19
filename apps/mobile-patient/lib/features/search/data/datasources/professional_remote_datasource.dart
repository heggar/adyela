import 'package:dio/dio.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/exceptions.dart';

/// Abstract interface for professional remote data source
abstract class ProfessionalRemoteDataSource {
  Future<List<Professional>> searchProfessionals({
    String? query,
    Specialty? specialty,
    double? minRating,
    double? maxFee,
    bool? onlyVerified,
    int? limit,
    int? offset,
  });

  Future<Professional> getProfessionalById(String id);

  Future<List<Professional>> getFeaturedProfessionals({int limit = 10});

  Future<List<Professional>> getProfessionalsBySpecialty(
    Specialty specialty, {
    int limit = 20,
  });
}

/// Implementation of professional remote data source using Dio
class ProfessionalRemoteDataSourceImpl
    implements ProfessionalRemoteDataSource {
  final Dio dio;

  ProfessionalRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Professional>> searchProfessionals({
    String? query,
    Specialty? specialty,
    double? minRating,
    double? maxFee,
    bool? onlyVerified,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (query != null) queryParams['q'] = query;
      if (specialty != null) queryParams['specialty'] = specialty.value;
      if (minRating != null) queryParams['min_rating'] = minRating;
      if (maxFee != null) queryParams['max_fee'] = maxFee;
      if (onlyVerified != null) queryParams['verified'] = onlyVerified;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await dio.get(
        '/professionals/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final professionals = (response.data['professionals'] as List)
            .map((json) => Professional.fromJson(json as Map<String, dynamic>))
            .toList();
        return professionals;
      } else {
        throw ServerException('Failed to search professionals: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<Professional> getProfessionalById(String id) async {
    try {
      final response = await dio.get('/professionals/$id');

      if (response.statusCode == 200) {
        return Professional.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to get professional: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<Professional>> getFeaturedProfessionals({int limit = 10}) async {
    try {
      final response = await dio.get(
        '/professionals/featured',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final professionals = (response.data['professionals'] as List)
            .map((json) => Professional.fromJson(json as Map<String, dynamic>))
            .toList();
        return professionals;
      } else {
        throw ServerException('Failed to get featured professionals: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<Professional>> getProfessionalsBySpecialty(
    Specialty specialty, {
    int limit = 20,
  }) async {
    try {
      final response = await dio.get(
        '/professionals/specialty/${specialty.value}',
        queryParameters: {'limit': limit},
      );

      if (response.statusCode == 200) {
        final professionals = (response.data['professionals'] as List)
            .map((json) => Professional.fromJson(json as Map<String, dynamic>))
            .toList();
        return professionals;
      } else {
        throw ServerException('Failed to get professionals by specialty: ${response.statusMessage}');
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
          return NotFoundException('Professional not found');
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
