import 'dart:io';

import 'package:estate_view_app/core/services/ar_spatial_service.dart';
import 'package:estate_view_app/core/services/spatial_archive_export_service.dart';
import 'package:estate_view_app/data/models/spatial_export_model.dart';
import 'package:estate_view_app/data/models/staged_furniture_model.dart';
import 'package:estate_view_app/presentation/ar_scanner/bloc/ar_spatial_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_repositories.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('glTF 2.0 & USDZ 3D Floorplan Export Integration Tests', () {
    late Directory tempRoot;
    late ArSpatialService arService;
    late SpatialArchiveExportService exportService;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('estateview_3d_int_');
      arService = ArSpatialService();
      exportService = SpatialArchiveExportService(
        arService: arService,
        directoryProvider: () async => tempRoot,
      );
    });

    tearDown(() async {
      arService.dispose();
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('1. Verifies full glTF 2.0 binary node hierarchy, parent-child links, and exact vertex counts', () async {
      // 4.5m x 3.5m room => produces 4 walls, 1 door (Wall 1) + 3 windows (Walls 2, 3, 4 >= 3.2m)
      final anchorsMeters = [
        const Offset(0.0, 0.0),
        const Offset(4.5, 0.0),
        const Offset(4.5, 3.5),
        const Offset(0.0, 3.5),
      ];

      final staged = [
        FurniturePresets.catalog[0].copyWith(
          id: 'chair-1',
          posX: 1.5,
          posZ: 1.5,
          rotationY: 0.5,
        ),
        FurniturePresets.catalog[2].copyWith(
          id: 'table-1',
          posX: 2.8,
          posZ: 2.0,
          scale: 1.1,
        ),
      ];

      final bundle = await exportService.exportRoomArchive(
        propertyId: 'test-prop-01',
        roomName: 'Master Architectural Suite',
        viewportAnchors: anchorsMeters,
        ceilingHeightMeters: 3.0,
        stagedFurniture: staged,
        format: SpatialArchiveFormat.bundle,
        anchorsAlreadyInMeters: true,
      );

      expect(bundle.record.glbPath, isNotNull);
      expect(bundle.record.usdzPath, isNotNull);

      final glbFile = File(bundle.record.glbPath!);
      final usdzFile = File(bundle.record.usdzPath!);
      expect(await glbFile.exists(), isTrue);
      expect(await usdzFile.exists(), isTrue);

      // Parse persisted GLB binary from disk
      final persistedGlbBytes = await glbFile.readAsBytes();
      final glb = exportService.inspectGlbBytes(persistedGlbBytes);

      expect(glb.isValidGlb, isTrue);
      expect(glb.version, equals(2));

      // Verify glTF 2.0 node hierarchy structure
      final scenes = glb.gltfJson['scenes'] as List<dynamic>;
      final rootNodeIndex =
          (scenes.first['nodes'] as List<dynamic>).first as int;
      final nodes = (glb.gltfJson['nodes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final rootNode = nodes[rootNodeIndex];
      expect(rootNode['name'], equals('EstateView_Room_Root'));

      final rootChildrenIndices = (rootNode['children'] as List<dynamic>)
          .cast<int>();
      final rootChildrenNames = rootChildrenIndices
          .map((i) => nodes[i]['name'] as String)
          .toList();

      expect(
        rootChildrenNames,
        equals([
          'Floor_Slab',
          'Ceiling_Slab',
          'Walls_Group',
          'Furniture_Staging_Group',
        ]),
      );

      // Verify Walls_Group children (4 walls) and their child openings
      final wallsGroupIdx = rootChildrenIndices[2];
      final wallIndices = (nodes[wallsGroupIdx]['children'] as List<dynamic>)
          .cast<int>();
      expect(wallIndices.length, equals(4));

      var openingNodesFound = 0;
      for (final wIdx in wallIndices) {
        final wallNode = nodes[wIdx];
        expect(wallNode['name'], startsWith('Wall_'));
        expect(wallNode['mesh'], isNotNull);
        final children = (wallNode['children'] as List<dynamic>? ?? [])
            .cast<int>();
        openingNodesFound += children.length;
      }
      // Wall 1 (4.5m -> Door), Wall 2 (3.5m -> Window), Wall 3 (4.5m -> Window), Wall 4 (3.5m -> Window)
      expect(openingNodesFound, equals(4));

      // Verify Furniture_Staging_Group children + TRS transforms
      final furnGroupIdx = rootChildrenIndices[3];
      final furnIndices = (nodes[furnGroupIdx]['children'] as List<dynamic>)
          .cast<int>();
      expect(furnIndices.length, equals(2));
      expect(nodes[furnIndices[0]]['translation'], equals([1.5, 0.0, 1.5]));
      expect(nodes[furnIndices[1]]['scale'], equals([1.1, 1.1, 1.1]));

      // Verify exact mathematical vertex & triangle counts:
      // Floor quad: 4 verts, 2 tris
      // Ceiling quad: 4 verts, 2 tris
      // 4 wall quads: 4 * 4 = 16 verts, 8 tris
      // 4 opening quads: 4 * 4 = 16 verts, 8 tris
      // 2 furniture cuboids: 2 * 24 = 48 verts, 24 tris
      // Total = 4 + 4 + 16 + 16 + 48 = 88 vertices; Triangles = 2 + 2 + 8 + 8 + 24 = 44 triangles
      expect(glb.totalVertexCount, equals(88));
      expect(glb.totalTriangleCount, equals(44));
      expect(glb.totalVertexCount, equals(bundle.record.vertexCount));
      expect(glb.totalTriangleCount, equals(bundle.record.triangleCount));

      // Verify persisted USDZ archive alongside GLB
      final usdz = exportService.inspectUsdzBytes(await usdzFile.readAsBytes());
      expect(usdz.isValidZip, isTrue);
      expect(usdz.is64ByteAligned, isTrue);
      expect(usdz.isUncompressedStore, isTrue);
      expect(usdz.usdaContent, contains('Wall_1_Door_0'));
      expect(usdz.usdaContent, contains('Furniture_Staging_Group'));
    });

    test('2. ArSpatialBloc ExportRoomArchiveEvent writes files and persists export metadata', () async {
      final mockMeasurementRepo = MockArMeasurementRepository();
      final mockArchiveRepo = MockSpatialArchiveRepository();
      final bloc = ArSpatialBloc(
        arService,
        mockMeasurementRepo,
        exportService: exportService,
        archiveRepository: mockArchiveRepo,
      );
      addTearDown(bloc.close);

      // Place 4 anchors of a room (4m x 3m at 100px = 1m enclosure scale)
      bloc.add(const PlaceCornerAnchorEvent(Offset(0, 0)));
      await bloc.stream.first;
      bloc.add(const PlaceCornerAnchorEvent(Offset(400, 0)));
      await bloc.stream.first;
      bloc.add(const PlaceCornerAnchorEvent(Offset(400, 300)));
      await bloc.stream.first;
      bloc.add(const PlaceCornerAnchorEvent(Offset(0, 300)));
      final readyState = await bloc.stream.first;
      expect(readyState.anchors.length, equals(4));

      bloc.add(
        const ExportRoomArchiveEvent(
          propertyId: 'test-prop-01',
          roomName: 'Living Atrium',
          format: SpatialArchiveFormat.glb,
          openNativeShareOrQuickLook: true,
        ),
      );

      final exportedState = await bloc.stream.firstWhere(
        (s) => !s.isExportingArchive && s.lastExportRecord != null,
      );

      expect(exportedState.lastExportRecord, isNotNull);
      expect(exportedState.lastExportRecord!.roomName, equals('Living Atrium'));
      expect(exportedState.lastExportRecord!.glbPath, isNotNull);
      expect(
        await File(exportedState.lastExportRecord!.glbPath!).exists(),
        isTrue,
      );
      expect(exportedState.exportedArchives.length, equals(1));
      expect(mockArchiveRepo.records.length, equals(1));

      // 4 floor + 4 ceiling + 16 walls + 4*4 openings (4x3m walls all >= 2.0/3.2? Wait 4m & 3m)
      // 4.0m (wall 0) -> door, 3.0m (<3.2) -> no win, 4.0m (wall 2) -> win, 3.0m -> no win
      // => 2 openings: 4 + 4 + 16 + 8 = 32 vertices
      expect(exportedState.lastExportRecord!.vertexCount, equals(32));
      expect(exportedState.lastExportRecord!.triangleCount, equals(16));
    });
  });
}
