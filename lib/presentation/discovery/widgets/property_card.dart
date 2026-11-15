import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/property_model.dart';
import '../bloc/property_catalog_bloc.dart';

class PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final bool isPkr;
  final VoidCallback onTap;

  const PropertyCard({
    super.key,
    required this.property,
    required this.isPkr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final priceStr = CurrencyFormatter.format(
      usdAmount: property.priceUsd,
      pkrAmount: property.pricePkr,
      isPkr: isPkr,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Image Container with badges and shortlist button (Height-safe)
            SizedBox(
              height: 135,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(15),
                    ),
                    child: Image.asset(
                      property.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.home_work_outlined,
                            size: 36,
                            color: colors.primary,
                          ),
                        );
                      },
                    ),
                  ),

                  // Listing Type Chip (Buy / Rent)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: property.listingType == 'buy'
                            ? colors.primary
                            : colors.secondary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        property.listingType == 'buy'
                            ? 'FOR SALE'
                            : 'FOR LEASE',
                        style: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // Shortlist Heart Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: colors.surface.withOpacity(0.85),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          context.read<PropertyCatalogBloc>().add(
                            ToggleShortlistEvent(property.id),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            property.isShortlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: property.isShortlisted
                                ? colors.error
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Price Badge at bottom of image
                  Positioned(
                    bottom: 6,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Text(
                        property.listingType == 'rent'
                            ? '$priceStr/mo'
                            : priceStr,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Card Body Content
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: colors.secondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${property.address}, ${property.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Specs Row (Overflow safe)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSpecItem(
                          context,
                          icon: Icons.bed_outlined,
                          label: '${property.bedrooms} Beds',
                        ),
                        const SizedBox(width: 8),
                        _buildSpecItem(
                          context,
                          icon: Icons.bathtub_outlined,
                          label: '${property.bathrooms} Baths',
                        ),
                        const SizedBox(width: 8),
                        _buildSpecItem(
                          context,
                          icon: Icons.square_foot_outlined,
                          label: '${property.areaSqFt.toInt()} sqft',
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            property.propertyType,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecItem(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
