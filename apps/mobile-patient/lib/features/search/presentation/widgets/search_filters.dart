import 'package:flutter/material.dart';

/// Search filters bottom sheet
class SearchFilters extends StatefulWidget {
  final double? minRating;
  final double? maxFee;
  final bool onlyVerified;
  final Function(double?, double?, bool) onApply;

  const SearchFilters({
    super.key,
    this.minRating,
    this.maxFee,
    this.onlyVerified = false,
    required this.onApply,
  });

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters> {
  late double _minRating;
  late double _maxFee;
  late bool _onlyVerified;

  @override
  void initState() {
    super.initState();
    _minRating = widget.minRating ?? 0.0;
    _maxFee = widget.maxFee ?? 200.0;
    _onlyVerified = widget.onlyVerified;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Rating filter
          Text(
            'Calificación mínima',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _minRating,
                  min: 0.0,
                  max: 5.0,
                  divisions: 10,
                  label: _minRating.toStringAsFixed(1),
                  onChanged: (value) {
                    setState(() {
                      _minRating = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    _minRating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Max fee filter
          Text(
            'Tarifa máxima',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _maxFee,
                  min: 0.0,
                  max: 500.0,
                  divisions: 50,
                  label: '\$${_maxFee.round()}',
                  onChanged: (value) {
                    setState(() {
                      _maxFee = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '\$${_maxFee.round()}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Verified filter
          SwitchListTile(
            title: const Text('Solo profesionales verificados'),
            subtitle: const Text('Mostrar solo profesionales con credenciales verificadas'),
            value: _onlyVerified,
            onChanged: (value) {
              setState(() {
                _onlyVerified = value;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _minRating = 0.0;
                      _maxFee = 200.0;
                      _onlyVerified = false;
                    });
                  },
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    widget.onApply(
                      _minRating > 0 ? _minRating : null,
                      _maxFee < 200 ? _maxFee : null,
                      _onlyVerified,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
