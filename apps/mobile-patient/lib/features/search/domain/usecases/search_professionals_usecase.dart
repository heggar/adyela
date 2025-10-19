import 'package:dartz/dartz.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/failures.dart';
import '../repositories/professional_repository.dart';

/// Use case for searching professionals
class SearchProfessionalsUseCase {
  final ProfessionalRepository repository;

  SearchProfessionalsUseCase({required this.repository});

  Future<Either<Failure, List<Professional>>> call({
    String? query,
    Specialty? specialty,
    double? minRating,
    double? maxFee,
    bool? onlyVerified,
    int? limit,
    int? offset,
  }) async {
    return await repository.searchProfessionals(
      query: query,
      specialty: specialty,
      minRating: minRating,
      maxFee: maxFee,
      onlyVerified: onlyVerified,
      limit: limit,
      offset: offset,
    );
  }
}
