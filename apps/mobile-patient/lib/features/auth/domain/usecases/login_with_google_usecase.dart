import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for Google sign in
class LoginWithGoogleUseCase {
  final AuthRepository repository;

  LoginWithGoogleUseCase({required this.repository});

  Future<Either<Failure, User>> call() async {
    return await repository.signInWithGoogle();
  }
}
