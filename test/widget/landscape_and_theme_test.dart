import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/core/theme/app_theme.dart';
import 'package:estate_view_app/data/models/floorplan_model.dart';
import 'package:estate_view_app/presentation/discovery/widgets/room_hotspot_canvas.dart';
import 'package:estate_view_app/presentation/discovery/widgets/schedule_viewing_modal.dart';
import 'package:estate_view_app/presentation/discovery/widgets/share_dossier_sheet.dart';

import '../helpers/mock_repositories.dart';
import '../helpers/test_locator.dart';

void main() {
  setUp(() async {
    await setupTestLocator();
  });

  group('Interactive Widgets & Sheets Tests', () {
    testWidgets(
      '1. Interactive Blueprint Hotspot Canvas renders and changes selected room on tap',
      (tester) async {
        const sampleFloorplan = FloorplanData(
          blueprintId: 'fp-sample',
          totalAreaSqFt: 4500.0,
          rooms: [
            RoomHotspot(
              id: 'rm-test-1',
              name: 'Master Suite',
              widthFt: 22.0,
              lengthFt: 18.0,
              areaSqFt: 396.0,
              flooringType: 'Hand-scraped Oak',
              sunOrientation: 'South-West',
              relativePosition: Offset(0.7, 0.3),
              description: 'En-suite spa bath and walk-in dressing hall.',
            ),
            RoomHotspot(
              id: 'rm-test-2',
              name: 'Living Atrium',
              widthFt: 30.0,
              lengthFt: 20.0,
              areaSqFt: 600.0,
              flooringType: 'Polished Honed Basalt',
              sunOrientation: 'South Exposure',
              relativePosition: Offset(0.35, 0.35),
              description: 'Double height glass atrium.',
            ),
          ],
        );

        RoomHotspot? selected;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: RoomHotspotCanvas(
                floorplan: sampleFloorplan,
                onRoomSelected: (r) => selected = r,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initial room card displayed
        expect(find.text('Master Suite'), findsWidgets);
        expect(find.text('Flooring: Hand-scraped Oak'), findsOneWidget);

        // Tap the second room chip
        await tester.tap(find.text('Living Atrium'));
        await tester.pumpAndSettle();

        expect(selected?.id, 'rm-test-2');
        expect(find.text('Flooring: Polished Honed Basalt'), findsOneWidget);
      },
    );

    testWidgets('2. Schedule Viewing Modal validates required form fields', (
      tester,
    ) async {
      final sampleProp = testMockProperties.first;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () =>
                      ScheduleViewingModal.show(context, sampleProp),
                  child: const Text('Open Modal'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule Private Viewing'), findsOneWidget);

      // Clear the name field to trigger validation error
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'),
        '',
      );
      await tester.pumpAndSettle();

      // Scroll to and tap confirm button
      await tester.ensureVisible(find.text('Confirm Viewing Reservation'));
      await tester.tap(find.text('Confirm Viewing Reservation'));
      await tester.pumpAndSettle();

      expect(find.text('Please provide your full legal name.'), findsOneWidget);
    });

    testWidgets(
      '3. Share Dossier Sheet renders formatted brief with investment details',
      (tester) async {
        final sampleProp = testMockProperties.first;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () =>
                        ShareDossierSheet.show(context, sampleProp, false),
                    child: const Text('Open Dossier'),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Dossier'));
        await tester.pumpAndSettle();

        expect(find.text('Export Property Dossier'), findsOneWidget);
        expect(find.text('Copy Formatted Brief to Clipboard'), findsOneWidget);
        expect(find.text('Export 3D Blueprint (.GLB / .USDZ)'), findsOneWidget);
      },
    );
  });
}
