import 'package:estate_view_app/core/services/gltf_binary_serializer.dart';
import 'package:estate_view_app/core/services/usdz_archive_serializer.dart';
import 'package:estate_view_app/data/models/plane_reconstruction_model.dart';
import 'package:estate_view_app/data/models/spatial_export_model.dart';
import 'package:estate_view_app/data/models/staged_furniture_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Polygon Triangulation & Spatial Serializers Unit Tests', () {
    test(
      '1. Ear-clipping triangulates convex quad and concave L-shaped polygons',
      () {
        const quad = [Offset(0, 0), Offset(4, 0), Offset(4, 3), Offset(0, 3)];
        final quadIndices = SpatialSceneGraph.triangulatePolygonXZ(quad);
        expect(quadIndices.length, 6); // 2 triangles * 3 indices

        // Concave L-shaped floorplan (6 vertices -> 4 triangles = 12 indices)
        const lShape = [
          Offset(0, 0),
          Offset(6, 0),
          Offset(6, 2),
          Offset(2, 2),
          Offset(2, 5),
          Offset(0, 5),
        ];
        final lIndices = SpatialSceneGraph.triangulatePolygonXZ(lShape);
        expect(lIndices.length, 12);
      },
    );

    test('2. GltfBinarySerializer writes valid 4-byte aligned GLB header and chunks', () {
      const enclosure = RoomEnclosureModel(
        walls: [
          WallPlaneModel(
            id: 'wall-1',
            wallIndex: 0,
            p1: Offset(0, 0),
            p2: Offset(3, 0),
            lengthMeters: 3.0,
            heightMeters: 2.8,
            normal: [0.0, 0.0, 1.0],
            grossAreaSqMeters: 8.4,
            netAreaSqMeters: 6.4,
            orientation: 'SOUTH_FACING',
            openings: [],
          ),
          WallPlaneModel(
            id: 'wall-2',
            wallIndex: 1,
            p1: Offset(3, 0),
            p2: Offset(3, 3),
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
            p1: Offset(3, 3),
            p2: Offset(0, 3),
            lengthMeters: 3.0,
            heightMeters: 2.8,
            normal: [0.0, 0.0, -1.0],
            grossAreaSqMeters: 8.4,
            netAreaSqMeters: 8.4,
            orientation: 'NORTH_FACING',
            openings: [],
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
        totalGrossWallAreaSqMeters: 33.6,
        totalNetWallAreaSqMeters: 31.6,
        totalOpeningsCount: 0,
        ceilingHeightMeters: 2.8,
      );

      final scene = SpatialSceneGraph.fromEnclosure(
        roomName: 'Unit Studio',
        enclosure: enclosure,
      );

      final serializer = GltfBinarySerializer();
      final glbBytes = serializer.serialize(scene);
      final inspection = serializer.inspectGlb(glbBytes);

      expect(inspection.isValidGlb, isTrue);
      expect(inspection.version, equals(2));
      expect(inspection.declaredTotalLength, equals(glbBytes.length));
      expect(inspection.jsonChunkLength % 4, equals(0));
      expect(inspection.binChunkLength % 4, equals(0));
      expect(inspection.meshCount, equals(6)); // Floor + Ceiling + 4 walls
    });

    test('3. UsdzArchiveSerializer produces Quick Look compatible 64-byte aligned uncompressed ZIP', () {
      const enclosure = RoomEnclosureModel(
        walls: [
          WallPlaneModel(
            id: 'wall-1',
            wallIndex: 0,
            p1: Offset(0, 0),
            p2: Offset(4, 0),
            lengthMeters: 4.0,
            heightMeters: 3.0,
            normal: [0.0, 0.0, 1.0],
            grossAreaSqMeters: 12.0,
            netAreaSqMeters: 12.0,
            orientation: 'SOUTH_FACING',
            openings: [],
          ),
          WallPlaneModel(
            id: 'wall-2',
            wallIndex: 1,
            p1: Offset(4, 0),
            p2: Offset(4, 3),
            lengthMeters: 3.0,
            heightMeters: 3.0,
            normal: [-1.0, 0.0, 0.0],
            grossAreaSqMeters: 9.0,
            netAreaSqMeters: 9.0,
            orientation: 'WEST_FACING',
            openings: [],
          ),
          WallPlaneModel(
            id: 'wall-3',
            wallIndex: 2,
            p1: Offset(4, 3),
            p2: Offset(0, 3),
            lengthMeters: 4.0,
            heightMeters: 3.0,
            normal: [0.0, 0.0, -1.0],
            grossAreaSqMeters: 12.0,
            netAreaSqMeters: 12.0,
            orientation: 'NORTH_FACING',
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
          elevationMeters: 3.0,
        ),
        totalGrossWallAreaSqMeters: 33.0,
        totalNetWallAreaSqMeters: 33.0,
        totalOpeningsCount: 0,
        ceilingHeightMeters: 3.0,
      );

      final scene = SpatialSceneGraph.fromEnclosure(
        roomName: 'Solarium',
        enclosure: enclosure,
        stagedFurniture: [FurniturePresets.catalog.first],
      );

      final usdzSerializer = UsdzArchiveSerializer();
      final usdzBytes = usdzSerializer.serialize(scene);
      final inspection = usdzSerializer.inspectUsdz(usdzBytes);

      expect(inspection.isValidZip, isTrue);
      expect(inspection.isUncompressedStore, isTrue);
      expect(inspection.is64ByteAligned, isTrue);
      expect(inspection.payloadOffset % 64, equals(0));
      expect(inspection.entryName, equals('scene.usda'));
      expect(inspection.usdaContent, contains('#usda 1.0'));
      expect(
        inspection.usdaContent,
        contains('defaultPrim = "EstateViewRoom"'),
      );
      expect(inspection.usdaContent, contains('UsdPreviewSurface'));
      expect(inspection.usdaContent, contains('Furniture_Staging_Group'));
    });
  });
}
