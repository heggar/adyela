import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core/flutter_core.dart';
import 'package:flutter_shared/flutter_shared.dart';
import 'package:go_router/go_router.dart';

import '../bloc/search_bloc.dart';
import '../bloc/search_event.dart';
import '../bloc/search_state.dart';
import '../widgets/search_filters.dart';
import '../widgets/specialty_chips.dart';

/// Search page for finding healthcare professionals
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  Specialty? _selectedSpecialty;
  double? _minRating;
  double? _maxFee;
  bool _onlyVerified = false;

  @override
  void initState() {
    super.initState();
    // Load featured professionals on init
    context.read<SearchBloc>().add(const LoadFeaturedProfessionalsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    context.read<SearchBloc>().add(
          SearchProfessionalsEvent(
            query: query.isEmpty ? null : query,
            specialty: _selectedSpecialty,
            minRating: _minRating,
            maxFee: _maxFee,
            onlyVerified: _onlyVerified,
          ),
        );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedSpecialty = null;
      _minRating = null;
      _maxFee = null;
      _onlyVerified = false;
    });
    context.read<SearchBloc>().add(const LoadFeaturedProfessionalsEvent());
  }

  void _onSpecialtySelected(Specialty? specialty) {
    setState(() {
      _selectedSpecialty = specialty;
    });
    if (specialty != null) {
      context
          .read<SearchBloc>()
          .add(LoadProfessionalsBySpecialtyEvent(specialty));
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SearchFilters(
        minRating: _minRating,
        maxFee: _maxFee,
        onlyVerified: _onlyVerified,
        onApply: (minRating, maxFee, onlyVerified) {
          setState(() {
            _minRating = minRating;
            _maxFee = maxFee;
            _onlyVerified = onlyVerified;
          });
          _performSearch();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Profesionales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o especialidad',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {});
                if (value.length >= 3 || value.isEmpty) {
                  _performSearch();
                }
              },
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          // Specialty chips
          SpecialtyChips(
            selectedSpecialty: _selectedSpecialty,
            onSpecialtySelected: _onSpecialtySelected,
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: 'Error',
                    message: state.message,
                    actionLabel: 'Reintentar',
                    onAction: _performSearch,
                  );
                }

                if (state is SearchLoaded) {
                  if (!state.hasResults) {
                    return EmptyState(
                      icon: Icons.search_off,
                      title: 'No hay resultados',
                      message: 'No se encontraron profesionales con los filtros aplicados',
                      actionLabel: 'Limpiar filtros',
                      onAction: _clearSearch,
                    );
                  }

                  return _buildProfessionalsList(state.professionals);
                }

                if (state is FeaturedProfessionalsLoaded) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Profesionales Destacados',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Expanded(
                        child: _buildProfessionalsList(state.professionals),
                      ),
                    ],
                  );
                }

                return EmptyState(
                  icon: Icons.search,
                  title: 'Busca profesionales',
                  message: 'Encuentra médicos, fisioterapeutas, psicólogos y más',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalsList(List<Professional> professionals) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: professionals.length,
      itemBuilder: (context, index) {
        final professional = professionals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProfessionalCard(
            professional: professional,
            onTap: () {
              context.push('/professionals/${professional.id}');
            },
            showBookButton: true,
          ),
        );
      },
    );
  }
}
