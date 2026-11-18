import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data/models/staged_furniture_model.dart';

class FurnitureStagingCanvas extends StatefulWidget {
  final List<Offset> floorAnchors;
  final List<StagedFurnitureModel> stagedItems;
  final String? selectedItemId;
  final bool hasCollisionWarning;
  final bool isOutOfBoundsWarning;
  final Function(String? id) onSelectItem;
  final Function(String id, Offset newPos) onUpdatePosition;
  final Function(String id, double newRotation) onUpdateRotation;
  final Function(String id, double newScale) onUpdateScale;
  final VoidCallback onStageFurnitureTap;

  const FurnitureStagingCanvas({
    super.key,
    required this.floorAnchors,
    required this.stagedItems,
    this.selectedItemId,
    required this.hasCollisionWarning,
    required this.isOutOfBoundsWarning,
    required this.onSelectItem,
    required this.onUpdatePosition,
    required this.onUpdateRotation,
    required this.onUpdateScale,
    required this.onStageFurnitureTap,
  });

  @override
  State<FurnitureStagingCanvas> createState() => _FurnitureStagingCanvasState();
}

class _FurnitureStagingCanvasState extends State<FurnitureStagingCanvas> {
  Offset? _dragStartItemPos;
  Offset? _dragStartTouchPos;
  String? _activeDraggingId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // Interactive Floorplan & Furniture Canvas
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                _handleCanvasTap(details.localPosition, size);
              },
              onPanStart: (details) {
                _handlePanStart(details.localPosition, size);
              },
              onPanUpdate: (details) {
                _handlePanUpdate(details.localPosition, size);
              },
              onPanEnd: (_) {
                _activeDraggingId = null;
                _dragStartItemPos = null;
                _dragStartTouchPos = null;
              },
              child: CustomPaint(
                size: size,
                painter: _FurnitureStagingPainter(
                  floorAnchors: widget.floorAnchors,
                  stagedItems: widget.stagedItems,
                  selectedItemId: widget.selectedItemId,
                  colors: colors,
                ),
              ),
            ),

            // Top Status & Warning HUD
            Positioned(
              top: 10,
              left: 12,
              right: 12,
              child: _buildStatusHud(colors),
            ),

            // Selected Item Floating Manipulator Bar
            if (widget.selectedItemId != null)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: _buildManipulatorBar(colors),
              ),
          ],
        );
      },
    );
  }

  Widget _buildStatusHud(ColorScheme colors) {
    final selectedItem = widget.stagedItems
        .cast<StagedFurnitureModel?>()
        .firstWhere((i) => i?.id == widget.selectedItemId, orElse: () => null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceContainer.withOpacity(0.92),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.view_in_ar_outlined,
                    size: 14,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.stagedItems.length} Staged Items',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.hasCollisionWarning)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.error),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: colors.onErrorContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Collision Detected',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
            if (widget.isOutOfBoundsWarning && !widget.hasCollisionWarning)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.tertiary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.crop_free_outlined,
                      size: 14,
                      color: colors.onTertiaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Out of Room Bounds',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (selectedItem != null) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colors.surfaceContainer.withOpacity(0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Selected: ${selectedItem.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                Text(
                  '${selectedItem.widthMeters.toStringAsFixed(2)}m x ${selectedItem.depthMeters.toStringAsFixed(2)}m',
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManipulatorBar(ColorScheme colors) {
    final selectedItem = widget.stagedItems
        .cast<StagedFurnitureModel?>()
        .firstWhere((i) => i?.id == widget.selectedItemId, orElse: () => null);

    if (selectedItem == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.rotate_right_outlined,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Rotation: ${(selectedItem.rotationY * 180 / pi).toStringAsFixed(0)} deg',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Expanded(
                child: Slider(
                  value: selectedItem.rotationY,
                  min: -pi,
                  max: pi,
                  onChanged: (val) {
                    widget.onUpdateRotation(selectedItem.id, val);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.straighten_outlined,
                size: 16,
                color: colors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Scale: ${(selectedItem.scale * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Expanded(
                child: Slider(
                  value: selectedItem.scale,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (val) {
                    widget.onUpdateScale(selectedItem.id, val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCanvasTap(Offset localPos, Size size) {
    final scale = _getScale(size);
    final center = Offset(size.width / 2, size.height / 2);

    for (final item in widget.stagedItems.reversed) {
      final itemScreenCenter =
          center + Offset(item.posX * scale, item.posZ * scale);
      final dist = (localPos - itemScreenCenter).distance;
      final hitRadius =
          max(item.widthMeters, item.depthMeters) * scale * item.scale * 0.7;

      if (dist <= max(24.0, hitRadius)) {
        widget.onSelectItem(item.id);
        return;
      }
    }
    widget.onSelectItem(null);
  }

  void _handlePanStart(Offset localPos, Size size) {
    final scale = _getScale(size);
    final center = Offset(size.width / 2, size.height / 2);

    for (final item in widget.stagedItems.reversed) {
      final itemScreenCenter =
          center + Offset(item.posX * scale, item.posZ * scale);
      final dist = (localPos - itemScreenCenter).distance;
      final hitRadius =
          max(item.widthMeters, item.depthMeters) * scale * item.scale * 0.7;

      if (dist <= max(24.0, hitRadius)) {
        _activeDraggingId = item.id;
        _dragStartItemPos = Offset(item.posX, item.posZ);
        _dragStartTouchPos = localPos;
        widget.onSelectItem(item.id);
        return;
      }
    }
  }

  void _handlePanUpdate(Offset localPos, Size size) {
    if (_activeDraggingId == null ||
        _dragStartTouchPos == null ||
        _dragStartItemPos == null) {
      return;
    }

    final scale = _getScale(size);
    final deltaScreen = localPos - _dragStartTouchPos!;
    final deltaMeters = Offset(deltaScreen.dx / scale, deltaScreen.dy / scale);

    final newMeters = _dragStartItemPos! + deltaMeters;
    widget.onUpdatePosition(_activeDraggingId!, newMeters);
  }

  double _getScale(Size size) {
    return min(size.width, size.height) / 8.0;
  }
}

class _FurnitureStagingPainter extends CustomPainter {
  final List<Offset> floorAnchors;
  final List<StagedFurnitureModel> stagedItems;
  final String? selectedItemId;
  final ColorScheme colors;

  _FurnitureStagingPainter({
    required this.floorAnchors,
    required this.stagedItems,
    required this.selectedItemId,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = min(size.width, size.height) / 8.0;

    _drawIsometricGrid(canvas, size, center);

    // Draw Floor Boundary Polygon
    if (floorAnchors.length >= 3) {
      _drawFloorPolygon(canvas, size, center, scale);
    }

    // Draw Staged Furniture Items with Oriented Bounding Boxes
    for (final item in stagedItems) {
      _drawFurnitureItem(canvas, size, center, scale, item);
    }
  }

  void _drawIsometricGrid(Canvas canvas, Size size, Offset center) {
    final gridPaint = Paint()
      ..color = colors.outlineVariant.withOpacity(0.25)
      ..strokeWidth = 1.0;

    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Origin crosshair
    final originPaint = Paint()
      ..color = colors.primary.withOpacity(0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(center.dx - 12, center.dy),
      Offset(center.dx + 12, center.dy),
      originPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 12),
      Offset(center.dx, center.dy + 12),
      originPaint,
    );
  }

  void _drawFloorPolygon(
    Canvas canvas,
    Size size,
    Offset center,
    double scale,
  ) {
    final polyPath = Path();
    for (int i = 0; i < floorAnchors.length; i++) {
      final pt =
          center +
          Offset(floorAnchors[i].dx * scale, floorAnchors[i].dy * scale);
      if (i == 0) {
        polyPath.moveTo(pt.dx, pt.dy);
      } else {
        polyPath.lineTo(pt.dx, pt.dy);
      }
    }
    polyPath.close();

    final fillPaint = Paint()
      ..color = colors.primary.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polyPath, fillPaint);

    final borderPaint = Paint()
      ..color = colors.primary.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(polyPath, borderPaint);
  }

  void _drawFurnitureItem(
    Canvas canvas,
    Size size,
    Offset center,
    double scale,
    StagedFurnitureModel item,
  ) {
    final isSelected = item.id == selectedItemId;
    final cornersMeters = item.getBoundingBoxCorners();

    // Convert corners to screen coordinates
    final screenCorners = cornersMeters.map((c) {
      return center + Offset(c.dx * scale, c.dy * scale);
    }).toList();

    Color baseColor;
    try {
      final hex = item.colorHex.replaceFirst('#', '');
      baseColor = Color(int.parse('0xFF$hex'));
    } catch (_) {
      baseColor = colors.primary;
    }

    final polyPath = Path();
    for (int i = 0; i < screenCorners.length; i++) {
      if (i == 0) {
        polyPath.moveTo(screenCorners[i].dx, screenCorners[i].dy);
      } else {
        polyPath.lineTo(screenCorners[i].dx, screenCorners[i].dy);
      }
    }
    polyPath.close();

    // 1. Footprint Fill
    final fillPaint = Paint()
      ..color = baseColor.withOpacity(isSelected ? 0.45 : 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(polyPath, fillPaint);

    // 2. Footprint Border
    final borderPaint = Paint()
      ..color = isSelected ? colors.primary : baseColor
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(polyPath, borderPaint);

    // 3. Directional Heading Indicator (front edge indicator)
    if (screenCorners.length == 4) {
      final frontCenter = Offset(
        (screenCorners[0].dx + screenCorners[1].dx) / 2,
        (screenCorners[0].dy + screenCorners[1].dy) / 2,
      );
      final itemCenter = center + Offset(item.posX * scale, item.posZ * scale);

      final dirPaint = Paint()
        ..color = isSelected ? colors.primary : colors.secondary
        ..strokeWidth = 2.0;
      canvas.drawLine(itemCenter, frontCenter, dirPaint);

      // Arrowhead dot at front center
      canvas.drawCircle(
        frontCenter,
        3.5,
        Paint()..color = isSelected ? colors.primary : colors.secondary,
      );
    }

    // 4. Selection Corner Handles
    if (isSelected) {
      final handlePaint = Paint()..color = colors.primary;
      for (final corner in screenCorners) {
        canvas.drawCircle(corner, 4.0, handlePaint);
      }
    }

    // 5. Item Label
    final itemCenter = center + Offset(item.posX * scale, item.posZ * scale);
    final textPainter = TextPainter(
      text: TextSpan(
        text: item.name,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          backgroundColor: colors.surface.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);

    textPainter.paint(
      canvas,
      Offset(
        itemCenter.dx - textPainter.width / 2,
        itemCenter.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _FurnitureStagingPainter oldDelegate) {
    return oldDelegate.stagedItems != stagedItems ||
        oldDelegate.selectedItemId != selectedItemId ||
        oldDelegate.colors != colors ||
        oldDelegate.floorAnchors != floorAnchors;
  }
}
