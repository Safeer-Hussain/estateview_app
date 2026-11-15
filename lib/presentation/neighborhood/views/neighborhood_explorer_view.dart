import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/amenity_pin_model.dart';
import '../../../data/models/property_model.dart';
import '../../discovery/bloc/property_catalog_bloc.dart';
import '../bloc/neighborhood_cubit.dart';

class NeighborhoodExplorerView extends StatefulWidget {
  const NeighborhoodExplorerView({super.key});

  @override
  State<NeighborhoodExplorerView> createState() =>
      _NeighborhoodExplorerViewState();
}

class _NeighborhoodExplorerViewState extends State<NeighborhoodExplorerView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPkr = sl<PreferencesService>().isPkrCurrency;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocBuilder<PropertyCatalogBloc, PropertyCatalogState>(
      builder: (context, catalogState) {
        return BlocBuilder<NeighborhoodCubit, NeighborhoodState>(
          builder: (context, nState) {
            final activeProperty =
                nState.selectedProperty ??
                (catalogState.properties.isNotEmpty
                    ? catalogState.properties.first
                    : null);

            final center = activeProperty != null
                ? LatLng(activeProperty.latitude, activeProperty.longitude)
                : nState.mapCenter;

            return isLandscape
                ? _buildLandscapeView(
                    context,
                    colors,
                    activeProperty,
                    catalogState.properties,
                    nState,
                    center,
                    isPkr,
                  )
                : _buildPortraitView(
                    context,
                    colors,
                    activeProperty,
                    catalogState.properties,
                    nState,
                    center,
                    isPkr,
                  );
          },
        );
      },
    );
  }

  Widget _buildPortraitView(
    BuildContext context,
    ColorScheme colors,
    PropertyModel? activeProperty,
    List<PropertyModel> properties,
    NeighborhoodState nState,
    LatLng center,
    bool isPkr,
  ) {
    return Column(
      children: [
        // Map Canvas
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              _buildMap(
                context,
                colors,
                activeProperty,
                properties,
                nState,
                center,
                isPkr,
              ),

              // Amenity Layer Chips at Top
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: _buildAmenityChips(context, colors, nState),
              ),

              // Recenter FAB
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: AppConstants.fabMapRecenter,
                  backgroundColor: colors.surface,
                  foregroundColor: colors.primary,
                  onPressed: () {
                    _mapController.move(center, 13.5);
                  },
                  child: const Icon(Icons.my_location, size: 20),
                ),
              ),
            ],
          ),
        ),

        // Controls & Surrounding Infrastructure Panel
        Expanded(
          flex: 4,
          child: Container(
            color: colors.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Radius Slider Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Neighborhood Radius',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${nState.searchRadiusKm.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: nState.searchRadiusKm,
                    min: 1.0,
                    max: 25.0,
                    divisions: 24,
                    activeColor: colors.primary,
                    inactiveColor: colors.outlineVariant,
                    onChanged: (val) {
                      context.read<NeighborhoodCubit>().setRadius(val);
                    },
                  ),

                  // Nearby Amenities List
                  Text(
                    'Surrounding Infrastructure (${nState.surroundingAmenities.length})',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  ...nState.surroundingAmenities.map((amenity) {
                    return _buildAmenityItem(context, colors, amenity);
                  }),

                  if (nState.surroundingAmenities.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No amenities detected within this radius. Increase the search radius slider.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeView(
    BuildContext context,
    ColorScheme colors,
    PropertyModel? activeProperty,
    List<PropertyModel> properties,
    NeighborhoodState nState,
    LatLng center,
    bool isPkr,
  ) {
    return Row(
      children: [
        // Left Pane: Map
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              _buildMap(
                context,
                colors,
                activeProperty,
                properties,
                nState,
                center,
                isPkr,
              ),
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: _buildAmenityChips(context, colors, nState),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: AppConstants.fabMapRecenter,
                  backgroundColor: colors.surface,
                  foregroundColor: colors.primary,
                  onPressed: () => _mapController.move(center, 13.5),
                  child: const Icon(Icons.my_location, size: 20),
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Pane: Radius and Amenities
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Radius',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      '${nState.searchRadiusKm.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: nState.searchRadiusKm,
                  min: 1.0,
                  max: 25.0,
                  divisions: 24,
                  activeColor: colors.primary,
                  onChanged: (val) {
                    context.read<NeighborhoodCubit>().setRadius(val);
                  },
                ),
                Text(
                  'Nearby Infrastructure (${nState.surroundingAmenities.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                ...nState.surroundingAmenities.map((amenity) {
                  return _buildAmenityItem(context, colors, amenity);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(
    BuildContext context,
    ColorScheme colors,
    PropertyModel? activeProperty,
    List<PropertyModel> properties,
    NeighborhoodState nState,
    LatLng center,
    bool isPkr,
  ) {
    // Convert radius from km to meters for CircleMarker
    final radiusMeters = nState.searchRadiusKm * 1000.0;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: center, initialZoom: 13.0),
      children: [
        // OpenStreetMap Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.estate_view_app',
        ),

        // Search Radius Circle around active property
        CircleLayer(
          circles: [
            CircleMarker(
              point: center,
              radius: radiusMeters,
              useRadiusInMeter: true,
              color: colors.primary.withOpacity(0.12),
              borderColor: colors.primary,
              borderStrokeWidth: 1.5,
            ),
          ],
        ),

        // Amenity Markers
        MarkerLayer(
          markers: nState.surroundingAmenities.map((amenity) {
            return Marker(
              point: amenity.position,
              width: 32,
              height: 32,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.secondary, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(amenity.icon, size: 16, color: colors.secondary),
              ),
            );
          }).toList(),
        ),

        // Property Price-Badge Markers
        MarkerLayer(
          markers: properties.map((prop) {
            final isSelected = activeProperty?.id == prop.id;
            final badgeText = CurrencyFormatter.format(
              usdAmount: prop.priceUsd,
              pkrAmount: prop.pricePkr,
              isPkr: isPkr,
            );

            return Marker(
              point: LatLng(prop.latitude, prop.longitude),
              width: 80,
              height: 34,
              child: GestureDetector(
                onTap: () {
                  context.read<NeighborhoodCubit>().selectProperty(prop);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primary : colors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? colors.onPrimary : colors.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSelected ? colors.onPrimary : colors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenityChips(
    BuildContext context,
    ColorScheme colors,
    NeighborhoodState nState,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AmenityType.values.map((type) {
          final isSelected = nState.activeAmenityTypes.contains(type);
          IconData icon;
          String label;
          switch (type) {
            case AmenityType.school:
              icon = Icons.school_outlined;
              label = 'Schools';
              break;
            case AmenityType.hospital:
              icon = Icons.local_hospital_outlined;
              label = 'Medical';
              break;
            case AmenityType.transit:
              icon = Icons.directions_subway_outlined;
              label = 'Transit';
              break;
            case AmenityType.park:
              icon = Icons.park_outlined;
              label = 'Parks';
              break;
          }

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              avatar: Icon(
                icon,
                size: 14,
                color: isSelected ? colors.onPrimaryContainer : colors.primary,
              ),
              label: Text(label),
              selected: isSelected,
              selectedColor: colors.primaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colors.onPrimaryContainer
                    : colors.onSurface,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (_) {
                context.read<NeighborhoodCubit>().toggleAmenityLayer(type);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmenityItem(
    BuildContext context,
    ColorScheme colors,
    AmenityPinModel amenity,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              amenity.icon,
              size: 16,
              color: colors.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amenity.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  amenity.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${amenity.distanceKm.toStringAsFixed(2)} km',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
