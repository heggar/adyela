import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for email/password signup
class SignUpWithEmailUseCase {
  final AuthRepository repository;

  SignUpWithEmailUseCase({required this.repository});

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return await repository.signUpWithEmailPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
