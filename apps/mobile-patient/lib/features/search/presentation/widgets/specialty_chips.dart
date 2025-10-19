import 'package:flutter/material.dart';
import 'package:flutter_core/flutter_core.dart';

/// Horizontal scrollable list of specialty filter chips
class SpecialtyChips extends StatelessWidget {
  final Specialty? selectedSpecialty;
  final ValueChanged<Specialty?> onSpecialtySelected;

  const SpecialtyChips({
    super.key,
    this.selectedSpecialty,
    required this.onSpecialtySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All specialties chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Todas'),
              selected: selectedSpecialty == null,
              onSelected: (selected) {
                onSpecialtySelected(null);
              },
            ),
          ),

          // Individual specialty chips
          ...Specialty.values.map((specialty) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(specialty.displayName),
                selected: selectedSpecialty == specialty,
                onSelected: (selected) {
                  onSpecialtySelected(selected ? specialty : null);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
