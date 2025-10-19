import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final firebase_auth.FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.firebaseAuth,
    required this.googleSignIn,
  });

  @override
  Future<Either<Failure, User>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in with Firebase
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get ID token
      final idToken = await credential.user?.getIdToken();
      if (idToken == null) {
        return const Left(AuthFailure('Failed to get authentication token'));
      }

      // Cache token
      await localDataSource.cacheAuthToken(idToken);

      // Get user from backend
      final user = await remoteDataSource.getCurrentUser(idToken);

      // Cache user
      await localDataSource.cacheUser(user);

      return Right(user.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_getFirebaseAuthErrorMessage(e)));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      // Create user in Firebase
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name if provided
      if (displayName != null) {
        await credential.user?.updateDisplayName(displayName);
      }

      // Get ID token
      final idToken = await credential.user?.getIdToken();
      if (idToken == null) {
        return const Left(AuthFailure('Failed to get authentication token'));
      }

      // Cache token
      await localDataSource.cacheAuthToken(idToken);

      // Register with backend
      final user = await remoteDataSource.signUpWithEmailPassword(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Cache user
      await localDataSource.cacheUser(user);

      return Right(user.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_getFirebaseAuthErrorMessage(e)));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithGoogle() async {
    try {
      // Trigger Google Sign In
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const Left(AuthFailure('Google sign in cancelled'));
      }

      // Get auth details
      final googleAuth = await googleUser.authentication;

      // Create credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await firebaseAuth.signInWithCredential(credential);

      // Get ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        return const Left(AuthFailure('Failed to get authentication token'));
      }

      // Cache token
      await localDataSource.cacheAuthToken(idToken);

      // Authenticate with backend
      final user = await remoteDataSource.signInWithOAuth(
        provider: 'google',
        token: idToken,
      );

      // Cache user
      await localDataSource.cacheUser(user);

      return Right(user.toEntity());
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_getFirebaseAuthErrorMessage(e)));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithFacebook() async {
    // TODO: Implement Facebook sign in
    return const Left(AuthFailure('Facebook sign in not implemented yet'));
  }

  @override
  Future<Either<Failure, User>> signInWithApple() async {
    // TODO: Implement Apple sign in
    return const Left(AuthFailure('Apple sign in not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      // Get token
      final token = await localDataSource.getAuthToken();

      // Sign out from Firebase
      await firebaseAuth.signOut();
      await googleSignIn.signOut();

      // Sign out from backend (if token exists)
      if (token != null) {
        await remoteDataSource.signOut(token);
      }

      // Clear local data
      await localDataSource.clearAll();

      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      // Check if user is signed in with Firebase
      final firebaseUser = firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return const Right(null);
      }

      // Try to get cached user first
      final cachedUser = await localDataSource.getCachedUser();
      if (cachedUser != null) {
        return Right(cachedUser.toEntity());
      }

      // Get token
      final token = await localDataSource.getAuthToken();
      if (token == null) {
        return const Right(null);
      }

      // Fetch user from backend
      final user = await remoteDataSource.getCurrentUser(token);

      // Cache user
      await localDataSource.cacheUser(user);

      return Right(user.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final user = firebaseAuth.currentUser;
      final token = await localDataSource.getAuthToken();
      return user != null && token != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_getFirebaseAuthErrorMessage(e)));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, User>> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    try {
      // Get token
      final token = await localDataSource.getAuthToken();
      if (token == null) {
        return const Left(AuthFailure('Not authenticated'));
      }

      // Update Firebase profile
      final firebaseUser = firebaseAuth.currentUser;
      if (displayName != null) {
        await firebaseUser?.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await firebaseUser?.updatePhotoURL(photoUrl);
      }

      // Update backend profile
      final user = await remoteDataSource.updateProfile(
        token: token,
        displayName: displayName,
        photoUrl: photoUrl,
        phoneNumber: phoneNumber,
      );

      // Cache updated user
      await localDataSource.cacheUser(user);

      return Right(user.toEntity());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      // Delete Firebase account
      await firebaseAuth.currentUser?.delete();

      // Clear local data
      await localDataSource.clearAll();

      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(_getFirebaseAuthErrorMessage(e)));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  /// Get user-friendly error message from Firebase Auth exception
  String _getFirebaseAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      case 'requires-recent-login':
        return 'Please sign in again to perform this action';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
