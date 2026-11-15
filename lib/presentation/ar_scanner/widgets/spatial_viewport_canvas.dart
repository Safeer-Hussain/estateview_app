import 'package:flutter/material.dart';

class SpatialViewportCanvas extends StatelessWidget {
  final List<Offset> anchors;
  final List<double> wallLengthsFt;
  final double areaSqFt;
  final bool isClosed;
  final ValueChanged<Offset> onTap;

  const SpatialViewportCanvas({
    super.key,
    required this.anchors,
    required this.wallLengthsFt,
    required this.areaSqFt,
    required this.isClosed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) {
            onTap(details.localPosition);
          },
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _SpatialPainter(
              anchors: anchors,
              wallLengthsFt: wallLengthsFt,
              areaSqFt: areaSqFt,
              isClosed: isClosed,
              colorScheme: colors,
            ),
          ),
        );
      },
    );
  }
}

class _SpatialPainter extends CustomPainter {
  final List<Offset> anchors;
  final List<double> wallLengthsFt;
  final double areaSqFt;
  final bool isClosed;
  final ColorScheme colorScheme;

  _SpatialPainter({
    required this.anchors,
    required this.wallLengthsFt,
    required this.areaSqFt,
    required this.isClosed,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Viewport background with spatial depth grid
    final bgPaint = Paint()..color = colorScheme.surface;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final gridPaint = Paint()
      ..color = colorScheme.outline.withOpacity(0.15)
      ..strokeWidth = 0.8;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Center Reticle Target
    final center = Offset(size.width / 2, size.height / 2);
    final reticlePaint = Paint()
      ..color = colorScheme.primary.withOpacity(0.6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 18, reticlePaint);
    canvas.drawLine(
      Offset(center.dx - 26, center.dy),
      Offset(center.dx - 6, center.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx + 6, center.dy),
      Offset(center.dx + 26, center.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 26),
      Offset(center.dx, center.dy - 6),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy + 6),
      Offset(center.dx, center.dy + 26),
      reticlePaint,
    );

    if (anchors.isEmpty) return;

    // 3. Closed Polygon Shading
    if (anchors.length >= 3 && isClosed) {
      final polyPath = Path()..moveTo(anchors[0].dx, anchors[0].dy);
      for (int i = 1; i < anchors.length; i++) {
        polyPath.lineTo(anchors[i].dx, anchors[i].dy);
      }
      polyPath.close();

      final fillPaint = Paint()
        ..color = colorScheme.primary.withOpacity(0.18)
        ..style = PaintingStyle.fill;
      canvas.drawPath(polyPath, fillPaint);
    }

    // 4. Connecting Wall Lines
    final wallPaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final n = anchors.length;
    for (int i = 0; i < n; i++) {
      if (i == n - 1 && !isClosed) break;
      final p1 = anchors[i];
      final p2 = anchors[(i + 1) % n];
      canvas.drawLine(p1, p2, wallPaint);

      // Draw Wall Length Label
      if (i < wallLengthsFt.length) {
        final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final lengthText = '${wallLengthsFt[i].toStringAsFixed(1)} ft';
        _drawText(canvas, lengthText, mid, colorScheme);
      }
    }

    // 5. Draw Anchor Points
    for (int i = 0; i < n; i++) {
      final p = anchors[i];
      // Glow
      final glowPaint = Paint()
        ..color = colorScheme.secondary.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 10, glowPaint);

      // Core anchor
      final corePaint = Paint()
        ..color = colorScheme.secondary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 5, corePaint);

      // Anchor Index Label
      _drawText(
        canvas,
        '${i + 1}',
        Offset(p.dx, p.dy - 14),
        colorScheme,
        isMini: true,
      );
    }

    // 6. Draw Total Area in center if closed
    if (isClosed && anchors.length >= 3) {
      double cx = 0;
      double cy = 0;
      for (final a in anchors) {
        cx += a.dx;
        cy += a.dy;
      }
      cx /= anchors.length;
      cy /= anchors.length;

      _drawText(
        canvas,
        '${areaSqFt.toStringAsFixed(1)} sq.ft\n(${(areaSqFt / 10.7639).toStringAsFixed(1)} sq.m)',
        Offset(cx, cy),
        colorScheme,
        isBold: true,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    ColorScheme colorScheme, {
    bool isBold = false,
    bool isMini = false,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: isBold ? colorScheme.primary : colorScheme.onSurface,
        fontSize: isMini ? 9 : (isBold ? 13 : 11),
        fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
        backgroundColor: colorScheme.surface.withOpacity(0.75),
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _SpatialPainter oldDelegate) {
    return oldDelegate.anchors.length != anchors.length ||
        oldDelegate.isClosed != isClosed ||
        oldDelegate.colorScheme != colorScheme;
  }
}
