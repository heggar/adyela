import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/search_professionals_usecase.dart';
import 'search_event.dart';
import 'search_state.dart';

/// Search BLoC for professional search functionality
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchProfessionalsUseCase searchProfessionalsUseCase;

  SearchBloc({
    required this.searchProfessionalsUseCase,
  }) : super(const SearchInitial()) {
    on<SearchProfessionalsEvent>(_onSearchProfessionals);
    on<LoadFeaturedProfessionalsEvent>(_onLoadFeaturedProfessionals);
    on<LoadProfessionalsBySpecialtyEvent>(_onLoadProfessionalsBySpecialty);
    on<ClearSearchEvent>(_onClearSearch);
  }

  /// Handle search professionals
  Future<void> _onSearchProfessionals(
    SearchProfessionalsEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());

    final result = await searchProfessionalsUseCase(
      query: event.query,
      specialty: event.specialty,
      minRating: event.minRating,
      maxFee: event.maxFee,
      onlyVerified: event.onlyVerified,
      limit: 20,
    );

    result.fold(
      (failure) => emit(SearchError(message: failure.message)),
      (professionals) => emit(SearchLoaded(
        professionals: professionals,
        query: event.query,
        specialty: event.specialty,
      )),
    );
  }

  /// Handle load featured professionals
  Future<void> _onLoadFeaturedProfessionals(
    LoadFeaturedProfessionalsEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());

    final result = await searchProfessionalsUseCase(
      onlyVerified: true,
      limit: 10,
    );

    result.fold(
      (failure) => emit(SearchError(message: failure.message)),
      (professionals) => emit(FeaturedProfessionalsLoaded(
        professionals: professionals,
      )),
    );
  }

  /// Handle load professionals by specialty
  Future<void> _onLoadProfessionalsBySpecialty(
    LoadProfessionalsBySpecialtyEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchLoading());

    final result = await searchProfessionalsUseCase(
      specialty: event.specialty,
      limit: 20,
    );

    result.fold(
      (failure) => emit(SearchError(message: failure.message)),
      (professionals) => emit(SearchLoaded(
        professionals: professionals,
        specialty: event.specialty,
      )),
    );
  }

  /// Handle clear search
  Future<void> _onClearSearch(
    ClearSearchEvent event,
    Emitter<SearchState> emit,
  ) async {
    emit(const SearchInitial());
  }
}
