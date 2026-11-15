import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/preferences_service.dart';
import '../bloc/property_catalog_bloc.dart';
import '../widgets/filter_bar.dart';
import '../widgets/property_card.dart';
import 'property_detail_view.dart';

class PropertyCatalogView extends StatelessWidget {
  const PropertyCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPkr = sl<PreferencesService>().isPkrCurrency;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocBuilder<PropertyCatalogBloc, PropertyCatalogState>(
      builder: (context, state) {
        if (state.isLoading && state.properties.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          );
        }

        return Column(
          children: [
            // Filter Bar
            const FilterBar(),

            // Catalog Header with result count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Curated Portfolios (${state.properties.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (state.shortlistCount > 0)
                    Row(
                      children: [
                        Icon(Icons.favorite, size: 14, color: colors.error),
                        const SizedBox(width: 4),
                        Text(
                          '${state.shortlistCount} shortlisted',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Content Grid or Empty View
            Expanded(
              child: state.properties.isEmpty
                  ? _buildEmptyState(context)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive crossAxisCount based on width
                        final crossAxisCount = constraints.maxWidth > 900
                            ? 3
                            : (constraints.maxWidth > 600 || isLandscape
                                  ? 2
                                  : 1);

                        return GridView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                // Strict rule: mainAxisExtent prevents RenderFlex overflow
                                mainAxisExtent: 240,
                              ),
                          itemCount: state.properties.length,
                          itemBuilder: (context, index) {
                            final property = state.properties[index];
                            return PropertyCard(
                              property: property,
                              isPkr: isPkr,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PropertyDetailView(property: property),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 56,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No properties match current criteria',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try resetting your filters or adjusting price and bedrooms.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<PropertyCatalogBloc>().add(
                  const FilterPropertiesEvent(
                    query: '',
                    listingType: 'all',
                    propertyType: 'All Types',
                    minBedrooms: 0,
                  ),
                );
              },
              child: const Text('Reset All Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
