import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/core/theme/app_theme.dart';
import 'package:estate_view_app/data/models/plane_reconstruction_model.dart';
import 'package:estate_view_app/presentation/ar_scanner/widgets/room_enclosure_visualizer.dart';

void main() {
  group('RoomEnclosureVisualizer Widget Tests', () {
    const sampleEnclosure = RoomEnclosureModel(
      walls: [
        WallPlaneModel(
          id: 'wall-1',
          wallIndex: 0,
          p1: Offset(0, 0),
          p2: Offset(4, 0),
          lengthMeters: 4.0,
          heightMeters: 2.8,
          normal: [0.0, 0.0, 1.0],
          grossAreaSqMeters: 11.2,
          netAreaSqMeters: 9.2,
          orientation: 'SOUTH_FACING',
          openings: [
            ArchitecturalOpeningModel(
              id: 'door-1',
              type: OpeningType.door,
              widthMeters: 0.95,
              heightMeters: 2.10,
              offsetMeters: 0.5,
              sillHeightMeters: 0.0,
              areaSqMeters: 2.0,
            ),
          ],
        ),
        WallPlaneModel(
          id: 'wall-2',
          wallIndex: 1,
          p1: Offset(4, 0),
          p2: Offset(4, 3),
          lengthMeters: 3.0,
          heightMeters: 2.8,
          normal: [-1.0, 0.0, 0.0],
          grossAreaSqMeters: 8.4,
          netAreaSqMeters: 8.4,
          orientation: 'WEST_FACING',
          openings: [],
        ),
        WallPlaneModel(
          id: 'wall-3',
          wallIndex: 2,
          p1: Offset(4, 3),
          p2: Offset(0, 3),
          lengthMeters: 4.0,
          heightMeters: 2.8,
          normal: [0.0, 0.0, -1.0],
          grossAreaSqMeters: 11.2,
          netAreaSqMeters: 8.7,
          orientation: 'NORTH_FACING',
          openings: [
            ArchitecturalOpeningModel(
              id: 'win-1',
              type: OpeningType.window,
              widthMeters: 1.8,
              heightMeters: 1.4,
              offsetMeters: 1.1,
              sillHeightMeters: 0.9,
              areaSqMeters: 2.5,
            ),
          ],
        ),
        WallPlaneModel(
          id: 'wall-4',
          wallIndex: 3,
          p1: Offset(0, 3),
          p2: Offset(0, 0),
          lengthMeters: 3.0,
          heightMeters: 2.8,
          normal: [1.0, 0.0, 0.0],
          grossAreaSqMeters: 8.4,
          netAreaSqMeters: 8.4,
          orientation: 'EAST_FACING',
          openings: [],
        ),
      ],
      floorPlane: HorizontalPlaneModel(
        type: PlaneType.horizontalFloor,
        normal: [0.0, 1.0, 0.0],
        elevationMeters: 0.0,
      ),
      ceilingPlane: HorizontalPlaneModel(
        type: PlaneType.horizontalCeiling,
        normal: [0.0, -1.0, 0.0],
        elevationMeters: 2.8,
      ),
      totalGrossWallAreaSqMeters: 39.2,
      totalNetWallAreaSqMeters: 34.7,
      totalOpeningsCount: 2,
      ceilingHeightMeters: 2.8,
    );

    testWidgets('1. Renders empty enclosure state gracefully', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: RoomEnclosureVisualizer(enclosure: null)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RoomEnclosureVisualizer), findsOneWidget);
      expect(find.text('3D Wireframe Room Enclosure'), findsOneWidget);
      expect(
        find.textContaining('Place at least 3 floor anchors'),
        findsOneWidget,
      );
    });

    testWidgets(
      '2. Renders 3D wireframe room enclosure with wall inspector and HUD',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: RoomEnclosureVisualizer(enclosure: sampleEnclosure),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(RoomEnclosureVisualizer), findsOneWidget);
        expect(find.text('Reconstructed 3D Room Enclosure'), findsOneWidget);
        expect(find.textContaining('4 Walls'), findsOneWidget);
        expect(find.text('Selected: WALL-1'), findsOneWidget);
        expect(find.byIcon(Icons.refresh), findsOneWidget);
      },
    );

    testWidgets('3. Handles drag pan gesture without throwing exceptions', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: RoomEnclosureVisualizer(enclosure: sampleEnclosure),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomPaint).first, const Offset(50, -30));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Renders cleanly on 800x360 landscape viewport', (
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
          home: const Scaffold(
            body: RoomEnclosureVisualizer(enclosure: sampleEnclosure),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(RoomEnclosureVisualizer), findsOneWidget);
    });
  });
}
