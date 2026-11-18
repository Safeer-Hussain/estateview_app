import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/core/theme/app_theme.dart';
import 'package:estate_view_app/data/models/staged_furniture_model.dart';
import 'package:estate_view_app/presentation/ar_scanner/widgets/furniture_catalog_sheet.dart';
import 'package:estate_view_app/presentation/ar_scanner/widgets/furniture_staging_canvas.dart';

void main() {
  testWidgets(
    'FurnitureCatalogSheet renders all luxury presets in dark theme',
    (tester) async {
      StagedFurnitureModel? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: FurnitureCatalogSheet(
              onSelectPreset: (preset) {
                selected = preset;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3D Architectural Staging Studio'), findsOneWidget);
      expect(find.text('Eames Lounge Chair & Ottoman'), findsOneWidget);
      expect(find.text('Barcelona Architectural Daybed'), findsOneWidget);
      expect(find.text('Noguchi Sculptural Coffee Table'), findsOneWidget);

      final stageButtons = find.text('Stage');
      expect(stageButtons, findsWidgets);

      await tester.tap(stageButtons.first);
      await tester.pumpAndSettle();

      expect(selected, isNotNull);
      expect(selected!.name, equals('Eames Lounge Chair & Ottoman'));
    },
  );

  testWidgets(
    'FurnitureStagingCanvas renders cleanly on 800x360 landscape viewport',
    (tester) async {
      tester.view.physicalSize = const Size(800, 360);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testItems = [
        FurniturePresets.catalog[0].copyWith(
          id: 'staged-1',
          posX: 0.0,
          posZ: 0.0,
        ),
        FurniturePresets.catalog[1].copyWith(
          id: 'staged-2',
          posX: 2.0,
          posZ: 1.5,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 360,
              child: FurnitureStagingCanvas(
                floorAnchors: const [
                  Offset(-3, -3),
                  Offset(3, -3),
                  Offset(3, 3),
                  Offset(-3, 3),
                ],
                stagedItems: testItems,
                selectedItemId: 'staged-1',
                hasCollisionWarning: false,
                isOutOfBoundsWarning: false,
                onSelectItem: (_) {},
                onUpdatePosition: (id, pos) {},
                onUpdateRotation: (id, rot) {},
                onUpdateScale: (id, scale) {},
                onStageFurnitureTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FurnitureStagingCanvas), findsOneWidget);
      expect(find.text('2 Staged Items'), findsOneWidget);
      expect(find.textContaining('Selected:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'FurnitureStagingCanvas displays collision and out of bounds warnings',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: FurnitureStagingCanvas(
              floorAnchors: const [
                Offset(-2, -2),
                Offset(2, -2),
                Offset(2, 2),
                Offset(-2, 2),
              ],
              stagedItems: FurniturePresets.catalog.take(2).toList(),
              selectedItemId: null,
              hasCollisionWarning: true,
              isOutOfBoundsWarning: true,
              onSelectItem: (_) {},
              onUpdatePosition: (id, pos) {},
              onUpdateRotation: (id, rot) {},
              onUpdateScale: (id, scale) {},
              onStageFurnitureTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Collision Detected'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
