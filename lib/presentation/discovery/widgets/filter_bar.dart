import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/property_catalog_bloc.dart';

class FilterBar extends StatefulWidget {
  const FilterBar({super.key});

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  final TextEditingController _searchController = TextEditingController();

  final List<String> _propertyTypes = [
    'All Types',
    'Villa',
    'Penthouse',
    'Townhouse',
    'Commercial',
    'Apartment',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return BlocBuilder<PropertyCatalogBloc, PropertyCatalogState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input & Buy/Rent Segmented Control
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        context.read<PropertyCatalogBloc>().add(
                          FilterPropertiesEvent(query: val),
                        );
                      },
                      decoration: InputDecoration(
                        hintText: 'Search DHA, Gulberg, Bahria...',
                        hintStyle: TextStyle(
                          color: colors.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<PropertyCatalogBloc>().add(
                                    const FilterPropertiesEvent(query: ''),
                                  );
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Buy / Rent Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTypeSegment(
                          context,
                          label: 'All',
                          isSelected: state.selectedListingType == 'all',
                          onTap: () {
                            context.read<PropertyCatalogBloc>().add(
                              const FilterPropertiesEvent(listingType: 'all'),
                            );
                          },
                        ),
                        _buildTypeSegment(
                          context,
                          label: 'Buy',
                          isSelected: state.selectedListingType == 'buy',
                          onTap: () {
                            context.read<PropertyCatalogBloc>().add(
                              const FilterPropertiesEvent(listingType: 'buy'),
                            );
                          },
                        ),
                        _buildTypeSegment(
                          context,
                          label: 'Rent',
                          isSelected: state.selectedListingType == 'rent',
                          onTap: () {
                            context.read<PropertyCatalogBloc>().add(
                              const FilterPropertiesEvent(listingType: 'rent'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Property Type Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _propertyTypes.map((type) {
                    final isSelected = state.selectedPropertyType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: colors.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 11,
                        ),
                        onSelected: (selected) {
                          context.read<PropertyCatalogBloc>().add(
                            FilterPropertiesEvent(
                              propertyType: selected ? type : 'All Types',
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypeSegment(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
