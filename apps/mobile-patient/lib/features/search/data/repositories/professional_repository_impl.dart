import 'package:dartz/dartz.dart';
import 'package:flutter_core/flutter_core.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/professional_repository.dart';
import '../datasources/professional_remote_datasource.dart';

/// Implementation of ProfessionalRepository
class ProfessionalRepositoryImpl implements ProfessionalRepository {
  final ProfessionalRemoteDataSource remoteDataSource;

  ProfessionalRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Professional>>> searchProfessionals({
    String? query,
    Specialty? specialty,
    double? minRating,
    double? maxFee,
    bool? onlyVerified,
    int? limit,
    int? offset,
  }) async {
    try {
      final professionals = await remoteDataSource.searchProfessionals(
        query: query,
        specialty: specialty,
        minRating: minRating,
        maxFee: maxFee,
        onlyVerified: onlyVerified,
        limit: limit,
        offset: offset,
      );
      return Right(professionals);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, Professional>> getProfessionalById(String id) async {
    try {
      final professional = await remoteDataSource.getProfessionalById(id);
      return Right(professional);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Professional>>> getFeaturedProfessionals({
    int limit = 10,
  }) async {
    try {
      final professionals = await remoteDataSource.getFeaturedProfessionals(
        limit: limit,
      );
      return Right(professionals);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Professional>>> getProfessionalsBySpecialty(
    Specialty specialty, {
    int limit = 20,
  }) async {
    try {
      final professionals = await remoteDataSource.getProfessionalsBySpecialty(
        specialty,
        limit: limit,
      );
      return Right(professionals);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }
}
