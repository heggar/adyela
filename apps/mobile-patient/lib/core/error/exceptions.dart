/// Base exception class
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Server exception (API errors)
class ServerException extends AppException {
  const ServerException(super.message);
}

/// Cache exception (Local storage errors)
class CacheException extends AppException {
  const CacheException(super.message);
}

/// Network exception (No internet connection)
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Authentication exception
class AuthException extends AppException {
  const AuthException(super.message);
}

/// Validation exception (Input validation errors)
class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Not found exception (Resource not found)
class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Permission exception (Insufficient permissions)
class PermissionException extends AppException {
  const PermissionException(super.message);
}
