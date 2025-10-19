import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, User>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, User>> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign in with Google
  Future<Either<Failure, User>> signInWithGoogle();

  /// Sign in with Facebook
  Future<Either<Failure, User>> signInWithFacebook();

  /// Sign in with Apple
  Future<Either<Failure, User>> signInWithApple();

  /// Sign out
  Future<Either<Failure, void>> signOut();

  /// Get current user
  Future<Either<Failure, User?>> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });

  /// Update user profile
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  });

  /// Delete account
  Future<Either<Failure, void>> deleteAccount();
}
