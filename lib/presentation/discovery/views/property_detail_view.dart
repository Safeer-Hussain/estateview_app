import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/preferences_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/property_model.dart';
import '../../roi_analyzer/bloc/mortgage_roi_cubit.dart';
import '../bloc/property_catalog_bloc.dart';
import '../widgets/room_hotspot_canvas.dart';
import '../widgets/schedule_viewing_modal.dart';
import '../widgets/share_dossier_sheet.dart';

class PropertyDetailView extends StatelessWidget {
  final PropertyModel property;

  const PropertyDetailView({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPkr = sl<PreferencesService>().isPkrCurrency;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final priceStr = CurrencyFormatter.format(
      usdAmount: property.priceUsd,
      pkrAmount: property.pricePkr,
      isPkr: isPkr,
    );
    final pricePerSqFt = property.areaSqFt > 0
        ? (property.priceUsd / property.areaSqFt).toStringAsFixed(1)
        : '0';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: isLandscape ? 36 : kToolbarHeight,
        title: Text(
          property.title,
          style: TextStyle(
            fontSize: isLandscape ? 14 : 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          BlocBuilder<PropertyCatalogBloc, PropertyCatalogState>(
            builder: (context, state) {
              final currentProp = state.allUnfilteredProperties.firstWhere(
                (p) => p.id == property.id,
                orElse: () => property,
              );
              return IconButton(
                icon: Icon(
                  currentProp.isShortlisted
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: currentProp.isShortlisted
                      ? colors.error
                      : colors.onSurface,
                ),
                onPressed: () {
                  context.read<PropertyCatalogBloc>().add(
                    ToggleShortlistEvent(property.id),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => ShareDossierSheet.show(context, property, isPkr),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: AppConstants.fabPropertyScheduleTour,
        onPressed: () => ScheduleViewingModal.show(context, property),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.calendar_month_outlined, size: 20),
        label: const Text(
          'Schedule Private Viewing',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: isLandscape
          ? _buildLandscapeLayout(
              context,
              colors,
              priceStr,
              pricePerSqFt,
              isPkr,
            )
          : _buildPortraitLayout(
              context,
              colors,
              priceStr,
              pricePerSqFt,
              isPkr,
            ),
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ColorScheme colors,
    String priceStr,
    String pricePerSqFt,
    bool isPkr,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Image
          AspectRatio(
            aspectRatio: 1.6,
            child: Image.asset(
              property.imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colors.surfaceContainerHighest,
                  child: Icon(Icons.apartment, size: 64, color: colors.primary),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price & Type Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      property.listingType == 'rent'
                          ? '$priceStr / month'
                          : priceStr,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        property.propertyType,
                        style: TextStyle(
                          color: colors.onSecondaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Title & Location
                Text(
                  property.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  property.subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: colors.secondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${property.address}, ${property.city}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Key Specs Grid Bar
                _buildSpecsBar(context, colors, pricePerSqFt),
                const SizedBox(height: 24),

                // Interactive Blueprint Floorplan Section
                Text(
                  'Interactive Architectural Blueprint',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap any room hotspot to inspect live dimensions, structural flooring, and solar daylight angles.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                RoomHotspotCanvas(floorplan: property.floorplan),
                const SizedBox(height: 24),

                // Amenities
                Text(
                  'Architectural Specifications & Amenities',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: property.amenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            amenity,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Verified Advisor Card
                _buildAdvisorCard(context, colors),
                const SizedBox(height: 16),

                // Model in ROI Cockpit Button
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<MortgageRoiCubit>().loadForProperty(
                      property,
                      isPkr,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Loaded ${property.title} into Mortgage ROI Cockpit.',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: const Text('Model Financing & Cash-on-Cash ROI'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ColorScheme colors,
    String priceStr,
    String pricePerSqFt,
    bool isPkr,
  ) {
    return Row(
      children: [
        // Left Master Pane: Image, Title, Specs, Advisor
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 2.1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(property.imageAsset, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      priceStr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                      ),
                    ),
                    Text(
                      property.propertyType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  property.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSpecsBar(context, colors, pricePerSqFt),
                const SizedBox(height: 12),
                _buildAdvisorCard(context, colors),
              ],
            ),
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Detail Pane: Blueprint Floorplan & Amenities
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: 80,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Interactive Blueprint Floorplan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                RoomHotspotCanvas(floorplan: property.floorplan),
                const SizedBox(height: 16),
                Text(
                  'Key Amenities',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: property.amenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Text(
                        amenity,
                        style: TextStyle(fontSize: 11, color: colors.onSurface),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecsBar(
    BuildContext context,
    ColorScheme colors,
    String pricePerSqFt,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSpecTile(
            context,
            Icons.bed_outlined,
            '${property.bedrooms} Beds',
          ),
          _buildSpecTile(
            context,
            Icons.bathtub_outlined,
            '${property.bathrooms} Baths',
          ),
          _buildSpecTile(
            context,
            Icons.square_foot_outlined,
            '${property.areaSqFt.toInt()} sqft',
          ),
          _buildSpecTile(
            context,
            Icons.monetization_on_outlined,
            '\$$pricePerSqFt/sqft',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecTile(BuildContext context, IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Icon(icon, size: 18, color: colors.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvisorCard(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.primaryContainer,
            child: ClipOval(
              child: Image.asset(
                property.advisorAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, color: colors.onPrimaryContainer),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      property.advisorName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.verified, size: 14, color: colors.secondary),
                  ],
                ),
                Text(
                  property.advisorRole,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  property.advisorPhone,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
