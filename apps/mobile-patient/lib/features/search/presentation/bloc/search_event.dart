import 'package:equatable/equatable.dart';
import 'package:flutter_core/flutter_core.dart';

/// Base search event
abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => [];
}

/// Search professionals
class SearchProfessionalsEvent extends SearchEvent {
  final String? query;
  final Specialty? specialty;
  final double? minRating;
  final double? maxFee;
  final bool? onlyVerified;

  const SearchProfessionalsEvent({
    this.query,
    this.specialty,
    this.minRating,
    this.maxFee,
    this.onlyVerified,
  });

  @override
  List<Object?> get props => [query, specialty, minRating, maxFee, onlyVerified];
}

/// Load featured professionals
class LoadFeaturedProfessionalsEvent extends SearchEvent {
  const LoadFeaturedProfessionalsEvent();
}

/// Load professionals by specialty
class LoadProfessionalsBySpecialtyEvent extends SearchEvent {
  final Specialty specialty;

  const LoadProfessionalsBySpecialtyEvent(this.specialty);

  @override
  List<Object?> get props => [specialty];
}

/// Clear search
class ClearSearchEvent extends SearchEvent {
  const ClearSearchEvent();
}
