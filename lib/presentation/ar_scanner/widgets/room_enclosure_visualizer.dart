import 'dart:math';

import 'package:flutter/material.dart';

import '../../../data/models/plane_reconstruction_model.dart';

class RoomEnclosureVisualizer extends StatefulWidget {
  final RoomEnclosureModel? enclosure;
  final WallPlaneModel? selectedWall;
  final ValueChanged<WallPlaneModel>? onSelectWall;

  const RoomEnclosureVisualizer({
    super.key,
    required this.enclosure,
    this.selectedWall,
    this.onSelectWall,
  });

  @override
  State<RoomEnclosureVisualizer> createState() =>
      _RoomEnclosureVisualizerState();
}

class _RoomEnclosureVisualizerState extends State<RoomEnclosureVisualizer> {
  double _yaw = 0.45;
  double _pitch = 0.35;
  double _zoom = 1.0;

  void _resetCamera() {
    setState(() {
      _yaw = 0.45;
      _pitch = 0.35;
      _zoom = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final enclosure = widget.enclosure;

    if (enclosure == null || enclosure.walls.isEmpty) {
      return Container(
        color: colors.surfaceContainerLowest,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.view_in_ar_outlined, size: 48, color: colors.primary),
            const SizedBox(height: 12),
            Text(
              '3D Wireframe Room Enclosure',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Place at least 3 floor anchors to reconstruct 3D walls, openings, and normals.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final activeWall = widget.selectedWall ?? enclosure.walls.first;

    return Stack(
      children: [
        // Interactive 3D Orbit Viewport
        GestureDetector(
          onScaleUpdate: (details) {
            setState(() {
              if (details.scale != 1.0) {
                _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
              } else {
                _yaw += details.focalPointDelta.dx * 0.01;
                _pitch = (_pitch - details.focalPointDelta.dy * 0.01).clamp(
                  -1.2,
                  1.2,
                );
              }
            });
          },
          child: Container(
            color: colors.surfaceContainerLowest,
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(
              painter: _RoomEnclosurePainter(
                enclosure: enclosure,
                selectedWallId: activeWall.id,
                yaw: _yaw,
                pitch: _pitch,
                zoom: _zoom,
                colors: colors,
              ),
            ),
          ),
        ),

        // Top Telemetry Header Badge
        Positioned(
          top: 10,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.surfaceContainer.withOpacity(0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.architecture_outlined,
                    size: 16,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Reconstructed 3D Room Enclosure',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        '${enclosure.walls.length} Walls • ${enclosure.totalOpeningsCount} Openings • Ceiling: ${enclosure.ceilingHeightMeters.toStringAsFixed(1)}m',
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, size: 18, color: colors.primary),
                  tooltip: 'Reset 3D View',
                  onPressed: _resetCamera,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom Selected Wall Inspector Card
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer.withOpacity(0.95),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Selected: ${activeWall.id.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        activeWall.orientation.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricMini(
                        colors,
                        'Length',
                        '${activeWall.lengthMeters.toStringAsFixed(2)}m',
                      ),
                    ),
                    Expanded(
                      child: _buildMetricMini(
                        colors,
                        'Gross Area',
                        '${activeWall.grossAreaSqMeters.toStringAsFixed(1)}m²',
                      ),
                    ),
                    Expanded(
                      child: _buildMetricMini(
                        colors,
                        'Net Wall Area',
                        '${activeWall.netAreaSqMeters.toStringAsFixed(1)}m²',
                      ),
                    ),
                    Expanded(
                      child: _buildMetricMini(
                        colors,
                        'Openings',
                        '${activeWall.openings.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Wall Selector Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: enclosure.walls.map((w) {
                      final isSelected = w.id == activeWall.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(w.id.toUpperCase()),
                          selected: isSelected,
                          selectedColor: colors.primaryContainer,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                          ),
                          onSelected: (selected) {
                            if (selected && widget.onSelectWall != null) {
                              widget.onSelectWall!(w);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricMini(ColorScheme colors, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _RoomEnclosurePainter extends CustomPainter {
  final RoomEnclosureModel enclosure;
  final String selectedWallId;
  final double yaw;
  final double pitch;
  final double zoom;
  final ColorScheme colors;

  const _RoomEnclosurePainter({
    required this.enclosure,
    required this.selectedWallId,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const focal = 280.0;
    final camDist = 4.8 / zoom;

    final cosY = cos(yaw);
    final sinY = sin(yaw);
    final cosP = cos(pitch);
    final sinP = sin(pitch);

    final h = enclosure.ceilingHeightMeters;

    // 1. Draw floor plane grid
    final gridPaint = Paint()
      ..color = colors.outlineVariant.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawFloorGrid(
      canvas,
      cx,
      cy,
      focal,
      camDist,
      cosY,
      sinY,
      cosP,
      sinP,
      gridPaint,
    );

    // 2. Project and draw wall planes
    for (final wall in enclosure.walls) {
      final isSelected = wall.id == selectedWallId;

      // 4 corners of the vertical wall
      final p1 = Offset(wall.p1.dx, wall.p1.dy);
      final p2 = Offset(wall.p2.dx, wall.p2.dy);

      final pt1 = _project(
        p1.dx,
        0.0,
        p1.dy,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      final pt2 = _project(
        p2.dx,
        0.0,
        p2.dy,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      final pt3 = _project(
        p2.dx,
        h,
        p2.dy,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      final pt4 = _project(
        p1.dx,
        h,
        p1.dy,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );

      if (pt1 == null || pt2 == null || pt3 == null || pt4 == null) continue;

      final wallPath = Path()
        ..moveTo(pt1.dx, pt1.dy)
        ..lineTo(pt2.dx, pt2.dy)
        ..lineTo(pt3.dx, pt3.dy)
        ..lineTo(pt4.dx, pt4.dy)
        ..close();

      // Semi-transparent wall fill
      final fillPaint = Paint()
        ..color = isSelected
            ? colors.primary.withOpacity(0.22)
            : colors.surfaceContainerHighest.withOpacity(0.12)
        ..style = PaintingStyle.fill;
      canvas.drawPath(wallPath, fillPaint);

      // Wall outline wireframe
      final strokePaint = Paint()
        ..color = isSelected ? colors.primary : colors.outlineVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.2;
      canvas.drawPath(wallPath, strokePaint);

      // Draw Inward Normal Vector Arrow
      _drawInwardNormal(
        canvas,
        wall,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
        isSelected,
      );

      // Draw Openings (doors and windows)
      _drawOpenings(
        canvas,
        wall,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
    }

    // 3. Draw Ceiling perimeter wireframe
    final ceilPoints = <Offset>[];
    for (final wall in enclosure.walls) {
      final pt = _project(
        wall.p1.dx,
        h,
        wall.p1.dy,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      if (pt != null) ceilPoints.add(pt);
    }

    if (ceilPoints.length >= 3) {
      final ceilPath = Path()..moveTo(ceilPoints.first.dx, ceilPoints.first.dy);
      for (int i = 1; i < ceilPoints.length; i++) {
        ceilPath.lineTo(ceilPoints[i].dx, ceilPoints[i].dy);
      }
      ceilPath.close();

      final ceilPaint = Paint()
        ..color = colors.secondary.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(ceilPath, ceilPaint);
    }
  }

  void _drawInwardNormal(
    Canvas canvas,
    WallPlaneModel wall,
    double cx,
    double cy,
    double focal,
    double camDist,
    double cosY,
    double sinY,
    double cosP,
    double sinP,
    bool isSelected,
  ) {
    final midX = (wall.p1.dx + wall.p2.dx) / 2.0;
    final midZ = (wall.p1.dy + wall.p2.dy) / 2.0;
    final midY = wall.heightMeters / 2.0;

    final nx = wall.normal.isNotEmpty ? wall.normal[0] : 0.0;
    final nz = wall.normal.length >= 3 ? wall.normal[2] : 0.0;

    // Normal arrow 0.5m length
    const arrowLen = 0.55;
    final startPt = _project(
      midX,
      midY,
      midZ,
      cx,
      cy,
      focal,
      camDist,
      cosY,
      sinY,
      cosP,
      sinP,
    );
    final endPt = _project(
      midX + nx * arrowLen,
      midY,
      midZ + nz * arrowLen,
      cx,
      cy,
      focal,
      camDist,
      cosY,
      sinY,
      cosP,
      sinP,
    );

    if (startPt == null || endPt == null) return;

    final arrowPaint = Paint()
      ..color = isSelected ? colors.primary : colors.tertiary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawLine(startPt, endPt, arrowPaint);
    canvas.drawCircle(
      endPt,
      3.0,
      Paint()
        ..color = isSelected ? colors.primary : colors.tertiary
        ..style = PaintingStyle.fill,
    );
  }

  void _drawOpenings(
    Canvas canvas,
    WallPlaneModel wall,
    double cx,
    double cy,
    double focal,
    double camDist,
    double cosY,
    double sinY,
    double cosP,
    double sinP,
  ) {
    if (wall.openings.isEmpty) return;

    final dx = wall.p2.dx - wall.p1.dx;
    final dz = wall.p2.dy - wall.p1.dy;
    final len = wall.lengthMeters;
    if (len < 0.001) return;

    final ux = dx / len;
    final uz = dz / len;

    for (final op in wall.openings) {
      final startDist = op.offsetMeters;
      final endDist = op.offsetMeters + op.widthMeters;
      final bottomY = op.sillHeightMeters;
      final topY = op.sillHeightMeters + op.heightMeters;

      final op1x = wall.p1.dx + ux * startDist;
      final op1z = wall.p1.dy + uz * startDist;
      final op2x = wall.p1.dx + ux * endDist;
      final op2z = wall.p1.dy + uz * endDist;

      final pt1 = _project(
        op1x,
        bottomY,
        op1z,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      final pt2 = _project(
        op2x,
        bottomY,
        op2z,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      final pt3 = _project(
        op2x,
        topY,
        op2z,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      final pt4 = _project(
        op1x,
        topY,
        op1z,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );

      if (pt1 == null || pt2 == null || pt3 == null || pt4 == null) continue;

      final opPath = Path()
        ..moveTo(pt1.dx, pt1.dy)
        ..lineTo(pt2.dx, pt2.dy)
        ..lineTo(pt3.dx, pt3.dy)
        ..lineTo(pt4.dx, pt4.dy)
        ..close();

      final isDoor = op.type == OpeningType.door;
      final fillPaint = Paint()
        ..color = isDoor
            ? colors.tertiary.withOpacity(0.25)
            : colors.primaryContainer.withOpacity(0.35)
        ..style = PaintingStyle.fill;
      canvas.drawPath(opPath, fillPaint);

      final strokePaint = Paint()
        ..color = isDoor ? colors.tertiary : colors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8;
      canvas.drawPath(opPath, strokePaint);
    }
  }

  void _drawFloorGrid(
    Canvas canvas,
    double cx,
    double cy,
    double focal,
    double camDist,
    double cosY,
    double sinY,
    double cosP,
    double sinP,
    Paint paint,
  ) {
    const range = 2.4;
    const step = 0.8;

    for (double x = -range; x <= range + 0.01; x += step) {
      final p1 = _project(
        x,
        0.0,
        -range,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      final p2 = _project(
        x,
        0.0,
        range,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }

    for (double z = -range; z <= range + 0.01; z += step) {
      final p1 = _project(
        -range,
        0.0,
        z,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      final p2 = _project(
        range,
        0.0,
        z,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
      );
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  Offset? _project(
    double x,
    double y,
    double z,
    double cx,
    double cy,
    double focal,
    double camDist,
    double cosY,
    double sinY,
    double cosP,
    double sinP,
  ) {
    final x1 = x * cosY + z * sinY;
    final z1 = -x * sinY + z * cosY;

    final y2 = y * cosP - z1 * sinP;
    final z2 = y * sinP + z1 * cosP + camDist;

    if (z2 <= 0.2) return null;

    final scale = focal / z2;
    return Offset(cx + x1 * scale, cy - y2 * scale);
  }

  @override
  bool shouldRepaint(covariant _RoomEnclosurePainter oldDelegate) {
    return oldDelegate.enclosure != enclosure ||
        oldDelegate.selectedWallId != selectedWallId ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.colors != colors;
  }
}
