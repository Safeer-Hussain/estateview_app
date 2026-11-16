import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/core/services/ar_spatial_service.dart';
import 'package:estate_view_app/core/theme/app_theme.dart';
import 'package:estate_view_app/presentation/ar_scanner/widgets/point_cloud_visualizer.dart';

void main() {
  group('PointCloudVisualizer 3D Widget Tests', () {
    final samplePacket = DepthPointCloudPacket(
      pointCount: 16,
      points: [
        for (double x = -1.5; x <= 1.5; x += 1.0)
          for (double z = 1.0; z <= 4.0; z += 1.0)
            LidarPoint3D(x: x, y: -1.0, z: z, confidence: 0.95),
      ],
      minDepthMeters: 1.0,
      maxDepthMeters: 4.5,
      densityPointsPerSqMeter: 42.0,
      timestamp: DateTime.now(),
    );

    testWidgets('1. Renders 3D Point Cloud Visualizer with HUD and telemetry', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PointCloudVisualizer(
              pointCloud: samplePacket,
              isStreaming: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PointCloudVisualizer), findsOneWidget);
      expect(find.text('ARCore / ARKit LiDAR Depth Stream'), findsOneWidget);
      expect(find.textContaining('16 points'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets(
      '2. Handles drag pan gesture without throwing projection exceptions',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: PointCloudVisualizer(
                pointCloud: samplePacket,
                isStreaming: true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Drag across viewport to trigger 3D yaw and pitch rotation
        await tester.drag(
          find.byType(CustomPaint).first,
          const Offset(60, -40),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('3. Renders cleanly on 800x360 landscape viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: PointCloudVisualizer(
              pointCloud: samplePacket,
              isStreaming: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PointCloudVisualizer), findsOneWidget);
    });
  });
}
