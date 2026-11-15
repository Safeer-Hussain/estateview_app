import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/services/preferences_service.dart';
import '../../ar_scanner/bloc/ar_spatial_bloc.dart';
import '../../discovery/bloc/property_catalog_bloc.dart';
import '../../discovery/views/property_detail_view.dart';
import '../../discovery/widgets/property_card.dart';
import '../../../data/models/tour_booking_model.dart';
import '../../../data/repositories/tour_repository.dart';

class PortfolioHubView extends StatefulWidget {
  const PortfolioHubView({super.key});

  @override
  State<PortfolioHubView> createState() => _PortfolioHubViewState();
}

class _PortfolioHubViewState extends State<PortfolioHubView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<TourBookingModel> _tours = [];
  bool _isLoadingTours = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTours();
    context.read<ArSpatialBloc>().add(const LoadSavedScansEvent());
  }

  Future<void> _loadTours() async {
    setState(() => _isLoadingTours = true);
    final tourRepo = sl<TourRepository>();
    final tours = await tourRepo.getTours();
    if (mounted) {
      setState(() {
        _tours = tours;
        _isLoadingTours = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPkr = sl<PreferencesService>().isPkrCurrency;

    return Column(
      children: [
        // Tab Header Bar
        Container(
          color: colors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            indicatorColor: colors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.favorite_outline, size: 18),
                text: 'Shortlisted',
              ),
              Tab(
                icon: Icon(Icons.calendar_today_outlined, size: 18),
                text: 'Scheduled Tours',
              ),
              Tab(
                icon: Icon(Icons.view_in_ar_outlined, size: 18),
                text: 'AR Room Scans',
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. Shortlisted Properties Tab
              BlocBuilder<PropertyCatalogBloc, PropertyCatalogState>(
                builder: (context, state) {
                  final shortlisted = state.shortlistedProperties;
                  if (shortlisted.isEmpty) {
                    return _buildEmptyTab(
                      context,
                      icon: Icons.favorite_border,
                      title: 'No Shortlisted Properties',
                      subtitle: 'Tap the heart icon on any property card across the discovery catalog to save it to your private portfolio.',
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: shortlisted.length,
                    itemBuilder: (context, index) {
                      final prop = shortlisted[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: PropertyCard(
                          property: prop,
                          isPkr: isPkr,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    PropertyDetailView(property: prop),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),

              // 2. Scheduled Tours Tab
              _isLoadingTours
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colors.primary,
                        ),
                      ),
                    )
                  : _tours.isEmpty
                  ? _buildEmptyTab(
                      context,
                      icon: Icons.event_busy_outlined,
                      title: 'No Scheduled Viewings',
                      subtitle: 'Book private In-Person VIP tours or 4K Spatial Walkthroughs directly from any property page.',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                      itemCount: _tours.length,
                      itemBuilder: (context, index) {
                        final tour = _tours[index];
                        return _buildTourCard(context, colors, tour);
                      },
                    ),

              // 3. Saved AR Room Scans Tab
              BlocBuilder<ArSpatialBloc, ArSpatialState>(
                builder: (context, state) {
                  if (state.savedScans.isEmpty) {
                    return _buildEmptyTab(
                      context,
                      icon: Icons.straighten_outlined,
                      title: 'No Saved Floorplan Scans',
                      subtitle: 'Use the AR Spatial Studio tab to place corner anchors, measure room dimensions, and save scans to SQLite.',
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: state.savedScans.length,
                    itemBuilder: (context, index) {
                      final scan = state.savedScans[index];
                      return _buildScanCard(context, colors, scan);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTab(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: colors.onSurfaceVariant),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourCard(
    BuildContext context,
    ColorScheme colors,
    TourBookingModel tour,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tour.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
              Text(
                '${tour.date} | ${tour.timeSlot}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tour.propertyTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.badge_outlined,
                size: 14,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${tour.tourType} • Reserved for ${tour.contactName}',
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          if (tour.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Inspection Notes: ${tour.notes}',
              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanCard(
    BuildContext context,
    ColorScheme colors,
    dynamic scan,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                scan.roomName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${scan.areaSqFt.toStringAsFixed(1)} sq.ft',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Perimeter: ${scan.perimeterFt.toStringAsFixed(1)} ft | ${scan.points.length} Anchors | ${scan.solarExposure.replaceAll('_', ' ')}',
            style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Est. Paint: \$${scan.paintCostEstimate.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Text(
                'Est. Flooring: \$${scan.flooringCostEstimate.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
