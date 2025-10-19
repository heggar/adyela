import 'package:equatable/equatable.dart';
import 'package:flutter_core/flutter_core.dart';

/// Base search state
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SearchInitial extends SearchState {
  const SearchInitial();
}

/// Loading state
class SearchLoading extends SearchState {
  const SearchLoading();
}

/// Search results loaded
class SearchLoaded extends SearchState {
  final List<Professional> professionals;
  final String? query;
  final Specialty? specialty;

  const SearchLoaded({
    required this.professionals,
    this.query,
    this.specialty,
  });

  @override
  List<Object?> get props => [professionals, query, specialty];

  bool get hasResults => professionals.isNotEmpty;
}

/// Search error
class SearchError extends SearchState {
  final String message;

  const SearchError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Featured professionals loaded
class FeaturedProfessionalsLoaded extends SearchState {
  final List<Professional> professionals;

  const FeaturedProfessionalsLoaded({required this.professionals});

  @override
  List<Object?> get props => [professionals];
}
