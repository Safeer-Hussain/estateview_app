import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_feedback.dart';
import '../../discovery/bloc/property_catalog_bloc.dart';
import '../bloc/ar_spatial_bloc.dart';
import '../widgets/point_cloud_visualizer.dart';
import '../widgets/room_enclosure_visualizer.dart';
import '../widgets/solar_azimuth_gauge.dart';
import '../widgets/spatial_viewport_canvas.dart';

class ArScannerView extends StatefulWidget {
  const ArScannerView({super.key});

  @override
  State<ArScannerView> createState() => _ArScannerViewState();
}

class _ArScannerViewState extends State<ArScannerView> {
  final TextEditingController _roomNameController = TextEditingController(
    text: 'Master Bedroom Suite',
  );
  String _selectedPropertyId = 'prop-lahore-01';

  @override
  void initState() {
    super.initState();
    context.read<ArSpatialBloc>().add(const InitializeArSessionEvent());
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  void _showSaveScanModal(BuildContext context, ArSpatialState state) {
    final colors = Theme.of(context).colorScheme;
    final properties = context
        .read<PropertyCatalogBloc>()
        .state
        .allUnfilteredProperties;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.save_outlined,
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Save Floorplan Measurement',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                            Text(
                              '${state.areaSqFt.toStringAsFixed(1)} sq.ft | ${state.anchors.length} Wall Anchors',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Room Name Field
                  TextFormField(
                    controller: _roomNameController,
                    decoration: const InputDecoration(
                      labelText: 'Room / Space Name',
                      prefixIcon: Icon(Icons.meeting_room_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Property Selector Dropdown
                  if (properties.isNotEmpty)
                    DropdownButtonFormField<String>(
                      value: _selectedPropertyId,
                      decoration: const InputDecoration(
                        labelText: 'Associate with Property',
                        prefixIcon: Icon(Icons.apartment_outlined),
                      ),
                      items: properties.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            p.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPropertyId = val);
                        }
                      },
                    ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      context.read<ArSpatialBloc>().add(
                        SaveRoomScanEvent(
                          propertyId: _selectedPropertyId,
                          roomName: _roomNameController.text.trim(),
                        ),
                      );
                      Navigator.of(bottomSheetContext).pop();
                      AppFeedback.showSuccess(
                        context,
                        'Floorplan scan for ${_roomNameController.text} saved to portfolio.',
                      );
                    },
                    child: const Text('Confirm & Persist to Portfolio'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocConsumer<ArSpatialBloc, ArSpatialState>(
      listener: (context, state) {
        if (state.message != null &&
            state.message!.isNotEmpty &&
            !state.isSaved) {
          // message notification
        }
      },
      builder: (context, state) {
        return isLandscape
            ? _buildLandscapeLayout(context, colors, state)
            : _buildPortraitLayout(context, colors, state);
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ColorScheme colors,
    ArSpatialState state,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            // Spatial Viewport Canvas (2D Planar vs 3D LiDAR vs 3D Wireframe Enclosure)
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  if (state.isEnclosureActive)
                    RoomEnclosureVisualizer(
                      enclosure: state.roomEnclosure,
                      selectedWall: state.selectedWall,
                      onSelectWall: (wall) {
                        context.read<ArSpatialBloc>().add(
                          SelectWallPlaneEvent(wall),
                        );
                      },
                    )
                  else if (state.isLidarActive)
                    PointCloudVisualizer(
                      pointCloud: state.latestPointCloud,
                      isStreaming: state.isLidarActive,
                    )
                  else ...[
                    SpatialViewportCanvas(
                      anchors: state.anchors,
                      wallLengthsFt: state.wallLengthsFt,
                      areaSqFt: state.areaSqFt,
                      isClosed: state.isClosed,
                      onTap: (point) {
                        context.read<ArSpatialBloc>().add(
                          PlaceCornerAnchorEvent(point),
                        );
                      },
                    ),

                    // Top Solar Azimuth Gauge HUD
                    Positioned(
                      top: 10,
                      left: 12,
                      right: 12,
                      child: SolarAzimuthGauge(
                        azimuthDegrees: state.compassAzimuth,
                        exposureRating: state.solarExposureRating,
                        ambientLux: state.ambientLux,
                        confidencePercent: state.trackingConfidence,
                      ),
                    ),

                    // Raycast Distance Badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.straighten,
                              size: 14,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Raycast: ${state.raycastDistanceMeters.toStringAsFixed(2)}m',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Viewport Mode Switcher Pill (2D Planar, 3D LiDAR, 3D Enclosure)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: _buildViewportModeSelector(context, colors, state),
                  ),
                ],
              ),
            ),

            // Metrics & Estimator Bottom Panel
            Expanded(
              flex: 4,
              child: Container(
                color: colors.surface,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Area & Perimeter Tiles
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              colors,
                              title: 'Total Floor Area',
                              primaryValue:
                                  '${state.areaSqFt.toStringAsFixed(1)} sq.ft',
                              secondaryValue:
                                  '${state.areaSqMeters.toStringAsFixed(1)} sq.m',
                              icon: Icons.aspect_ratio_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              colors,
                              title: 'Perimeter Boundary',
                              primaryValue:
                                  '${state.perimeterFt.toStringAsFixed(1)} ft',
                              secondaryValue:
                                  '${state.perimeterMeters.toStringAsFixed(1)} m',
                              icon: Icons.timeline_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Material Cost Estimates
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              colors,
                              title: 'Est. Wall Coating / Paint',
                              primaryValue:
                                  '\$${state.paintCostEstimate.toStringAsFixed(0)}',
                              secondaryValue: 'Based on 10ft Wall Height',
                              icon: Icons.format_paint_outlined,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              colors,
                              title: 'Est. Premium Flooring',
                              primaryValue:
                                  '\$${state.flooringCostEstimate.toStringAsFixed(0)}',
                              secondaryValue: '\$12.00 / sq.ft Oak/Stone',
                              icon: Icons.layers_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // FAB Controls Bar
        Positioned(
          right: 16,
          bottom: 16,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (state.anchors.isNotEmpty) ...[
                FloatingActionButton.small(
                  heroTag: AppConstants.fabArReset,
                  backgroundColor: colors.surfaceContainer,
                  foregroundColor: colors.error,
                  onPressed: () {
                    context.read<ArSpatialBloc>().add(
                      const ResetSpatialAnchorsEvent(),
                    );
                  },
                  child: const Icon(Icons.refresh, size: 20),
                ),
                const SizedBox(width: 10),
              ],
              if (state.anchors.length >= 3) ...[
                FloatingActionButton.small(
                  heroTag: AppConstants.fabArSaveScan,
                  backgroundColor: colors.secondary,
                  foregroundColor: colors.onSecondary,
                  onPressed: () => _showSaveScanModal(context, state),
                  child: const Icon(Icons.bookmark_add_outlined, size: 20),
                ),
                const SizedBox(width: 10),
              ],
              FloatingActionButton.extended(
                heroTag: AppConstants.fabArMeasurePoint,
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                onPressed: () {
                  // Drop anchor at center of screen
                  final size = MediaQuery.of(context).size;
                  final centerPoint = Offset(
                    size.width / 2,
                    (size.height * 0.6) / 2,
                  );
                  context.read<ArSpatialBloc>().add(
                    PlaceCornerAnchorEvent(centerPoint),
                  );
                },
                icon: const Icon(Icons.add_location_alt_outlined, size: 20),
                label: Text(
                  state.anchors.length >= 2 ? 'Close Polygon' : '+ Drop Anchor',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ColorScheme colors,
    ArSpatialState state,
  ) {
    return Row(
      children: [
        // Left Pane: Viewport Canvas (2D Planar vs 3D LiDAR vs 3D Wireframe Enclosure)
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              if (state.isEnclosureActive)
                RoomEnclosureVisualizer(
                  enclosure: state.roomEnclosure,
                  selectedWall: state.selectedWall,
                  onSelectWall: (wall) {
                    context.read<ArSpatialBloc>().add(
                      SelectWallPlaneEvent(wall),
                    );
                  },
                )
              else if (state.isLidarActive)
                PointCloudVisualizer(
                  pointCloud: state.latestPointCloud,
                  isStreaming: state.isLidarActive,
                )
              else ...[
                SpatialViewportCanvas(
                  anchors: state.anchors,
                  wallLengthsFt: state.wallLengthsFt,
                  areaSqFt: state.areaSqFt,
                  isClosed: state.isClosed,
                  onTap: (point) {
                    context.read<ArSpatialBloc>().add(
                      PlaceCornerAnchorEvent(point),
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: SolarAzimuthGauge(
                    azimuthDegrees: state.compassAzimuth,
                    exposureRating: state.solarExposureRating,
                    ambientLux: state.ambientLux,
                    confidencePercent: state.trackingConfidence,
                  ),
                ),
              ],
              Positioned(
                bottom: 8,
                right: 8,
                child: _buildViewportModeSelector(
                  context,
                  colors,
                  state,
                  isLandscape: true,
                ),
              ),
            ],
          ),
        ),

        const VerticalDivider(width: 1),

        // Right Pane: Metrics & Actions
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildMetricTile(
                  context,
                  colors,
                  title: 'Total Floor Area',
                  primaryValue: '${state.areaSqFt.toStringAsFixed(1)} sq.ft',
                  secondaryValue:
                      '${state.areaSqMeters.toStringAsFixed(1)} sq.m',
                  icon: Icons.aspect_ratio_outlined,
                ),
                const SizedBox(height: 8),
                _buildMetricTile(
                  context,
                  colors,
                  title: 'Perimeter Boundary',
                  primaryValue: '${state.perimeterFt.toStringAsFixed(1)} ft',
                  secondaryValue:
                      '${state.perimeterMeters.toStringAsFixed(1)} m',
                  icon: Icons.timeline_outlined,
                ),
                const SizedBox(height: 8),
                _buildMetricTile(
                  context,
                  colors,
                  title: 'Est. Material Costs',
                  primaryValue:
                      '\$${(state.paintCostEstimate + state.flooringCostEstimate).toStringAsFixed(0)}',
                  secondaryValue:
                      'Paint: \$${state.paintCostEstimate.toStringAsFixed(0)} | Floor: \$${state.flooringCostEstimate.toStringAsFixed(0)}',
                  icon: Icons.monetization_on_outlined,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<ArSpatialBloc>().add(
                            const ResetSpatialAnchorsEvent(),
                          );
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.anchors.length >= 3
                            ? () => _showSaveScanModal(context, state)
                            : null,
                        child: const Text('Save Scan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context,
    ColorScheme colors, {
    required String title,
    required String primaryValue,
    required String secondaryValue,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            primaryValue,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
            ),
          ),
          Text(
            secondaryValue,
            style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildViewportModeSelector(
    BuildContext context,
    ColorScheme colors,
    ArSpatialState state, {
    bool isLandscape = false,
  }) {
    final isEnclosure = state.isEnclosureActive;
    final isLidar = state.isLidarActive && !isEnclosure;
    final isPlanar = !state.isLidarActive && !isEnclosure;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withOpacity(0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton(
            context,
            colors,
            label: '2D Planar',
            icon: Icons.grid_view_outlined,
            isSelected: isPlanar,
            onTap: () {
              context.read<ArSpatialBloc>().add(
                const ToggleLidarPointCloudEvent(false),
              );
              context.read<ArSpatialBloc>().add(
                const ToggleRoomEnclosureEvent(false),
              );
            },
          ),
          const SizedBox(width: 4),
          _buildModeButton(
            context,
            colors,
            label: '3D LiDAR',
            icon: Icons.blur_on_outlined,
            isSelected: isLidar,
            onTap: () {
              context.read<ArSpatialBloc>().add(
                const ToggleRoomEnclosureEvent(false),
              );
              context.read<ArSpatialBloc>().add(
                const ToggleLidarPointCloudEvent(true),
              );
            },
          ),
          const SizedBox(width: 4),
          _buildModeButton(
            context,
            colors,
            label: '3D Enclosure',
            icon: Icons.architecture_outlined,
            isSelected: isEnclosure,
            onTap: () {
              context.read<ArSpatialBloc>().add(
                const ToggleLidarPointCloudEvent(false),
              );
              context.read<ArSpatialBloc>().add(
                const ToggleRoomEnclosureEvent(true),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(
    BuildContext context,
    ColorScheme colors, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
