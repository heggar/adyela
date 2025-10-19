import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

/// Abstract interface for auth remote data source
abstract class AuthRemoteDataSource {
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  Future<UserModel> signInWithOAuth({
    required String provider,
    required String token,
  });

  Future<void> signOut(String token);

  Future<UserModel> getCurrentUser(String token);

  Future<void> sendPasswordResetEmail({required String email});

  Future<UserModel> updateProfile({
    required String token,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  });
}

/// Implementation of auth remote data source using Dio
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to sign in: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await dio.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          if (displayName != null) 'display_name': displayName,
        },
      );

      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to sign up: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> signInWithOAuth({
    required String provider,
    required String token,
  }) async {
    try {
      final response = await dio.post(
        '/auth/oauth/$provider',
        data: {
          'token': token,
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to sign in with $provider: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<void> signOut(String token) async {
    try {
      final response = await dio.post(
        '/auth/logout',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to sign out: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> getCurrentUser(String token) async {
    try {
      final response = await dio.get(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to get user: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      final response = await dio.post(
        '/auth/reset-password',
        data: {'email': email},
      );

      if (response.statusCode != 200) {
        throw ServerException('Failed to send password reset email: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String token,
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    try {
      final response = await dio.patch(
        '/auth/profile',
        data: {
          if (displayName != null) 'display_name': displayName,
          if (photoUrl != null) 'photo_url': photoUrl,
          if (phoneNumber != null) 'phone_number': phoneNumber,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException('Failed to update profile: ${response.statusMessage}');
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

        if (statusCode == 401) {
          return AuthException('Invalid credentials or token expired');
        } else if (statusCode == 403) {
          return PermissionException('Insufficient permissions');
        } else if (statusCode == 404) {
          return NotFoundException('Resource not found');
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
