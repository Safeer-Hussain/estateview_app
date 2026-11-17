import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:estate_view_app/core/services/ar_spatial_service.dart';
import 'package:estate_view_app/data/models/plane_reconstruction_model.dart';

void main() {
  group('Plane Normal Orientation & Wall Reconstruction Unit Tests', () {
    late ArSpatialService service;

    setUp(() {
      service = ArSpatialService();
    });

    tearDown(() {
      service.dispose();
    });

    test('1. Horizontal planes have strictly unit vertical normals', () async {
      final anchors = [
        {'x': 0.0, 'z': 0.0},
        {'x': 4.0, 'z': 0.0},
        {'x': 4.0, 'z': 3.0},
        {'x': 0.0, 'z': 3.0},
      ];

      final enclosure = await service.reconstructWallPlanes(
        anchors,
        ceilingHeight: 2.8,
      );

      // Floor plane: normal is strictly (0, 1, 0)
      expect(enclosure.floorPlane.type, PlaneType.horizontalFloor);
      expect(enclosure.floorPlane.normal, [0.0, 1.0, 0.0]);
      expect(enclosure.floorPlane.elevationMeters, 0.0);

      // Ceiling plane: normal is strictly (0, -1, 0)
      expect(enclosure.ceilingPlane.type, PlaneType.horizontalCeiling);
      expect(enclosure.ceilingPlane.normal, [0.0, -1.0, 0.0]);
      expect(enclosure.ceilingPlane.elevationMeters, 2.8);
    });

    test('2. Vertical wall normals are strictly unit length and horizontal (ny = 0)', () async {
      // 4 corners of a 5m x 4m room
      final anchors = [
        {'x': 0.0, 'z': 0.0},
        {'x': 5.0, 'z': 0.0},
        {'x': 5.0, 'z': 4.0},
        {'x': 0.0, 'z': 4.0},
      ];

      final enclosure = await service.reconstructWallPlanes(
        anchors,
        ceilingHeight: 3.0,
      );

      expect(enclosure.walls.length, 4);

      for (final wall in enclosure.walls) {
        final nx = wall.normal[0];
        final ny = wall.normal[1];
        final nz = wall.normal[2];

        // ny must be zero (purely horizontal normal)
        expect(ny, 0.0);

        // Vector magnitude must be strictly 1.0
        final mag = sqrt(nx * nx + ny * ny + nz * nz);
        expect(mag, closeTo(1.0, 1e-5));
      }
    });

    test('3. Wall normals strictly point inward toward the room polygon centroid', () async {
      // Room centered around (2.5, 2.0)
      final anchors = [
        {'x': 0.0, 'z': 0.0},
        {'x': 5.0, 'z': 0.0},
        {'x': 5.0, 'z': 4.0},
        {'x': 0.0, 'z': 4.0},
      ];

      final enclosure = await service.reconstructWallPlanes(
        anchors,
        ceilingHeight: 2.8,
      );

      const centroidX = 2.5;
      const centroidZ = 2.0;

      for (final wall in enclosure.walls) {
        final midX = (wall.p1.dx + wall.p2.dx) / 2.0;
        final midZ = (wall.p1.dy + wall.p2.dy) / 2.0;

        final toCentroidX = centroidX - midX;
        final toCentroidZ = centroidZ - midZ;

        final nx = wall.normal[0];
        final nz = wall.normal[2];

        // Dot product of inward normal and vector to centroid must be positive
        final dotProduct = nx * toCentroidX + nz * toCentroidZ;
        expect(dotProduct, greaterThan(0.0));
      }

      // Wall 1 (along z = 0, x from 0 to 5) must point toward +Z
      expect(enclosure.walls[0].normal[2], closeTo(1.0, 1e-4));

      // Wall 2 (along x = 5, z from 0 to 4) must point toward -X
      expect(enclosure.walls[1].normal[0], closeTo(-1.0, 1e-4));

      // Wall 3 (along z = 4, x from 5 to 0) must point toward -Z
      expect(enclosure.walls[2].normal[2], closeTo(-1.0, 1e-4));

      // Wall 4 (along x = 0, z from 4 to 0) must point toward +X
      expect(enclosure.walls[3].normal[0], closeTo(1.0, 1e-4));
    });

    test(
      '4. Wall opening detection correctly reduces net wall surface area',
      () async {
        final anchors = [
          {'x': 0.0, 'z': 0.0},
          {'x': 4.5, 'z': 0.0},
          {'x': 4.5, 'z': 3.5},
          {'x': 0.0, 'z': 3.5},
        ];

        final enclosure = await service.reconstructWallPlanes(
          anchors,
          ceilingHeight: 2.8,
        );

        // Wall 1: length = 4.5m, gross = 4.5 * 2.8 = 12.6 m²
        final wall1 = enclosure.walls.first;
        expect(wall1.lengthMeters, closeTo(4.5, 0.01));
        expect(wall1.grossAreaSqMeters, closeTo(12.6, 0.01));
        expect(wall1.openings, isNotEmpty);
        expect(wall1.openings.first.type, OpeningType.door);

        // Net area must be strictly less than gross area by opening surface
        expect(wall1.netAreaSqMeters, lessThan(wall1.grossAreaSqMeters));
        expect(
          wall1.grossAreaSqMeters - wall1.openings.first.areaSqMeters,
          closeTo(wall1.netAreaSqMeters, 0.01),
        );

        // Total Net Area must be less than Total Gross Area
        expect(
          enclosure.totalNetWallAreaSqMeters,
          lessThan(enclosure.totalGrossWallAreaSqMeters),
        );
        expect(enclosure.totalOpeningsCount, greaterThan(0));
      },
    );
  });
}
