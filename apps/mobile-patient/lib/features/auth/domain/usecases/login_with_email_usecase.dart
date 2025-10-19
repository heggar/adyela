import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Use case for email/password login
class LoginWithEmailUseCase {
  final AuthRepository repository;

  LoginWithEmailUseCase({required this.repository});

  Future<Either<Failure, User>> call({
    required String email,
    required String password,
  }) async {
    return await repository.signInWithEmailPassword(
      email: email,
      password: password,
    );
  }
}
