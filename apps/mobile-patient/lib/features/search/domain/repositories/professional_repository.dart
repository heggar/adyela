import 'package:dartz/dartz.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/failures.dart';

/// Professional repository interface
abstract class ProfessionalRepository {
  /// Search professionals by name, specialty, or location
  Future<Either<Failure, List<Professional>>> searchProfessionals({
    String? query,
    Specialty? specialty,
    double? minRating,
    double? maxFee,
    bool? onlyVerified,
    int? limit,
    int? offset,
  });

  /// Get professional by ID
  Future<Either<Failure, Professional>> getProfessionalById(String id);

  /// Get featured professionals
  Future<Either<Failure, List<Professional>>> getFeaturedProfessionals({
    int limit = 10,
  });

  /// Get professionals by specialty
  Future<Either<Failure, List<Professional>>> getProfessionalsBySpecialty(
    Specialty specialty, {
    int limit = 20,
  });
}
