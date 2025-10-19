import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Server failure (API errors)
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Cache failure (Local storage errors)
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Network failure (No internet connection)
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Validation failure (Input validation errors)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Not found failure (Resource not found)
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Permission failure (Insufficient permissions)
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}
