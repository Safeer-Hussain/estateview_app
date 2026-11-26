import 'dart:io';

import 'package:estate_view_app/core/services/ar_spatial_service.dart';
import 'package:estate_view_app/core/services/spatial_archive_export_service.dart';
import 'package:estate_view_app/core/theme/app_theme.dart';
import 'package:estate_view_app/data/models/staged_furniture_model.dart';
import 'package:estate_view_app/presentation/ar_scanner/widgets/spatial_archive_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_repositories.dart';

void main() {
  group('SpatialArchiveShareSheet Widget Tests', () {
    late Directory tempRoot;
    late ArSpatialService arService;
    late SpatialArchiveExportService exportService;
    late MockSpatialArchiveRepository archiveRepo;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('estateview_sheet_');
      arService = ArSpatialService();
      exportService = SpatialArchiveExportService(
        arService: arService,
        directoryProvider: () async => tempRoot,
      );
      archiveRepo = MockSpatialArchiveRepository();
    });

    tearDown(() async {
      arService.dispose();
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    testWidgets(
      '1. Renders diagnostics, switches formats, toggles inspector, and exports archive cleanly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SpatialArchiveShareSheet(
                propertyId: 'test-prop-01',
                roomName: 'Garden Pavilion',
                anchors: const [
                  Offset(0, 0),
                  Offset(450, 0),
                  Offset(450, 350),
                  Offset(0, 350),
                ],
                stagedFurniture: [FurniturePresets.catalog.first],
                exportService: exportService,
                archiveRepository: archiveRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Export Interactive 3D Archive'), findsOneWidget);
        expect(find.text('glTF 2.0 Binary Verified'), findsOneWidget);
        expect(find.text('USDZ Quick Look 64B Aligned'), findsOneWidget);

        // Inspect glTF Node Tree toggle
        await tester.tap(
          find.text('Inspect glTF Node Hierarchy & USDA Schema'),
        );
        await tester.pumpAndSettle();
        expect(find.textContaining('EstateView_Room_Root'), findsOneWidget);

        // Toggle to USDA tab inside inspector
        await tester.tap(find.text('USDA 1.0 Primitives'));
        await tester.pumpAndSettle();
        expect(find.textContaining('#usda 1.0'), findsOneWidget);

        // Save 3D Archive action (interleave real OS I/O ticks and FakeAsync pumps)
        await tester.ensureVisible(find.text('Export & Save 3D Archive'));
        await tester.tap(find.text('Export & Save 3D Archive'));
        await tester.pump();
        for (int i = 0; i < 30; i++) {
          if (find.text('Archive Written & Verified').evaluate().isNotEmpty) {
            break;
          }
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(find.text('Archive Written & Verified'), findsOneWidget);
        expect(archiveRepo.records.length, equals(1));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Renders cleanly without RenderFlex overflow on 800x360 landscape viewport',
      (tester) async {
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
              body: SpatialArchiveShareSheet(
                propertyId: 'test-prop-01',
                roomName: 'Penthouse Terrace',
                anchors: const [
                  Offset(0, 0),
                  Offset(350, 0),
                  Offset(350, 350),
                  Offset(0, 350),
                ],
                exportService: exportService,
                archiveRepository: archiveRepo,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SpatialArchiveShareSheet), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
