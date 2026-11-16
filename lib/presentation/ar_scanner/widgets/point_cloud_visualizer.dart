import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/services/ar_spatial_service.dart';

class PointCloudVisualizer extends StatefulWidget {
  final DepthPointCloudPacket? pointCloud;
  final bool isStreaming;
  final VoidCallback? onToggleStream;

  const PointCloudVisualizer({
    super.key,
    required this.pointCloud,
    this.isStreaming = true,
    this.onToggleStream,
  });

  @override
  State<PointCloudVisualizer> createState() => _PointCloudVisualizerState();
}

class _PointCloudVisualizerState extends State<PointCloudVisualizer> {
  double _yaw = 0.35;
  double _pitch = 0.28;
  double _zoom = 1.0;

  void _resetCamera() {
    setState(() {
      _yaw = 0.35;
      _pitch = 0.28;
      _zoom = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final packet = widget.pointCloud;

    return Stack(
      children: [
        // Interactive 3D Gestures Viewport
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
              painter: _PointCloudPainter(
                points: packet?.points ?? const [],
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
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.isStreaming ? colors.primary : colors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ARCore / ARKit LiDAR Depth Stream',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        packet != null
                            ? '${packet.pointCount} points • ${packet.densityPointsPerSqMeter.toStringAsFixed(0)} pts/m² • ${packet.minDepthMeters.toStringAsFixed(1)}m-${packet.maxDepthMeters.toStringAsFixed(1)}m'
                            : 'Acquiring LiDAR raw depth image buffer...',
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
                  tooltip: 'Reset 3D Camera',
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

        // Bottom HUD Interaction Hint
        Positioned(
          bottom: 12,
          left: 12,
          right: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  'Drag to orbit 3D point cloud • Pinch to zoom',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Zoom: ${(_zoom * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjectedPoint {
  final double screenX;
  final double screenY;
  final double depth;
  final double confidence;

  const _ProjectedPoint({
    required this.screenX,
    required this.screenY,
    required this.depth,
    required this.confidence,
  });
}

class _PointCloudPainter extends CustomPainter {
  final List<LidarPoint3D> points;
  final double yaw;
  final double pitch;
  final double zoom;
  final ColorScheme colors;

  const _PointCloudPainter({
    required this.points,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const focalLength = 260.0;
    final cameraDist = 4.2 / zoom;

    final cosYaw = cos(yaw);
    final sinYaw = sin(yaw);
    final cosPitch = cos(pitch);
    final sinPitch = sin(pitch);

    // Draw 3D floor perspective grid
    final gridPaint = Paint()
      ..color = colors.outlineVariant.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawFloorGrid(
      canvas,
      centerX,
      centerY,
      focalLength,
      cameraDist,
      cosYaw,
      sinYaw,
      cosPitch,
      sinPitch,
      gridPaint,
    );

    if (points.isEmpty) {
      return;
    }

    final projected = <_ProjectedPoint>[];

    for (final p in points) {
      // Rotate around Y (yaw)
      final x1 = p.x * cosYaw + p.z * sinYaw;
      final z1 = -p.x * sinYaw + p.z * cosYaw;

      // Rotate around X (pitch)
      final y2 = p.y * cosPitch - z1 * sinPitch;
      final z2 = p.y * sinPitch + z1 * cosPitch + cameraDist;

      if (z2 <= 0.2) continue; // Behind camera

      final scale = focalLength / z2;
      final screenX = centerX + x1 * scale;
      final screenY = centerY - y2 * scale;

      projected.add(
        _ProjectedPoint(
          screenX: screenX,
          screenY: screenY,
          depth: z2,
          confidence: p.confidence,
        ),
      );
    }

    // Depth sort (draw far to near)
    projected.sort((a, b) => b.depth.compareTo(a.depth));

    // Draw depth points with gradient mapping
    for (final pt in projected) {
      final normDepth = ((pt.depth - 2.0) / 4.0).clamp(0.0, 1.0);
      final pointColor = Color.lerp(
        colors.primary,
        colors.secondary,
        normDepth,
      )!.withOpacity(0.4 + pt.confidence * 0.55);

      final radius = (4.0 / (pt.depth * 0.4)).clamp(1.2, 4.8);

      final pointPaint = Paint()
        ..color = pointColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(pt.screenX, pt.screenY), radius, pointPaint);
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
    const floorY = -1.2;
    const gridRange = 2.4;
    const step = 0.8;

    // Grid lines along Z
    for (double x = -gridRange; x <= gridRange + 0.01; x += step) {
      _drawLine3D(
        canvas,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
        paint,
        x,
        floorY,
        -gridRange,
        x,
        floorY,
        gridRange,
      );
    }

    // Grid lines along X
    for (double z = -gridRange; z <= gridRange + 0.01; z += step) {
      _drawLine3D(
        canvas,
        cx,
        cy,
        focal,
        camDist,
        cosY,
        sinY,
        cosP,
        sinP,
        paint,
        -gridRange,
        floorY,
        z,
        gridRange,
        floorY,
        z,
      );
    }
  }

  void _drawLine3D(
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
    double x1,
    double y1,
    double z1,
    double x2,
    double y2,
    double z2,
  ) {
    final rx1 = x1 * cosY + z1 * sinY;
    final rz1 = -x1 * sinY + z1 * cosY;
    final ry1 = y1 * cosP - rz1 * sinP;
    final depth1 = y1 * sinP + rz1 * cosP + camDist;

    final rx2 = x2 * cosY + z2 * sinY;
    final rz2 = -x2 * sinY + z2 * cosY;
    final ry2 = y2 * cosP - rz2 * sinP;
    final depth2 = y2 * sinP + rz2 * cosP + camDist;

    if (depth1 <= 0.2 || depth2 <= 0.2) return;

    final sx1 = cx + rx1 * (focal / depth1);
    final sy1 = cy - ry1 * (focal / depth1);
    final sx2 = cx + rx2 * (focal / depth2);
    final sy2 = cy - ry2 * (focal / depth2);

    canvas.drawLine(Offset(sx1, sy1), Offset(sx2, sy2), paint);
  }

  @override
  bool shouldRepaint(covariant _PointCloudPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.colors != colors;
  }
}
