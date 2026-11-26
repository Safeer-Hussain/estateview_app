import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../data/models/plane_reconstruction_model.dart';
import '../../data/models/spatial_export_model.dart';
import '../../data/models/staged_furniture_model.dart';
import '../constants/app_constants.dart';
import 'ar_spatial_service.dart';
import 'gltf_binary_serializer.dart';
import 'usdz_archive_serializer.dart';

class SpatialArchiveExportBundle {
  final SpatialSceneGraph sceneGraph;
  final SpatialExportRecord record;
  final Uint8List? glbBytes;
  final Uint8List? usdzBytes;

  const SpatialArchiveExportBundle({
    required this.sceneGraph,
    required this.record,
    this.glbBytes,
    this.usdzBytes,
  });
}

/// Orchestrates 3D floorplan mesh assembly, binary glTF 2.0 (.glb) & Apple USDZ (.usdz)
/// serialization, disk archival, and native iOS Quick Look / Android Share dispatch.
class SpatialArchiveExportService {
  static const MethodChannel _channel = MethodChannel(
    AppConstants.arSpatialMethodChannel,
  );

  final ArSpatialService _arService;
  final GltfBinarySerializer _glbSerializer;
  final UsdzArchiveSerializer _usdzSerializer;
  final Future<Directory> Function()? directoryProvider;

  SpatialArchiveExportService({
    ArSpatialService? arService,
    GltfBinarySerializer? glbSerializer,
    UsdzArchiveSerializer? usdzSerializer,
    this.directoryProvider,
  }) : _arService = arService ?? ArSpatialService(),
       _glbSerializer = glbSerializer ?? GltfBinarySerializer(),
       _usdzSerializer = usdzSerializer ?? UsdzArchiveSerializer();

  /// Builds a watertight [SpatialSceneGraph] synchronously for instant UI diagnostics.
  SpatialSceneGraph buildSceneGraphSync({
    required String roomName,
    required List<Offset> viewportAnchors,
    RoomEnclosureModel? existingEnclosure,
    double ceilingHeightMeters = 2.8,
    List<StagedFurnitureModel> stagedFurniture = const [],
    bool anchorsAlreadyInMeters = false,
  }) {
    final enclosure =
        (existingEnclosure != null &&
            existingEnclosure.walls.length >= 3 &&
            (existingEnclosure.ceilingHeightMeters - ceilingHeightMeters)
                    .abs() <
                0.01)
        ? existingEnclosure
        : _arService.reconstructWallPlanesSync(
            _effectiveMeterAnchors(
              viewportAnchors,
              anchorsAlreadyInMeters: anchorsAlreadyInMeters,
            ),
            ceilingHeight: ceilingHeightMeters,
          );

    return SpatialSceneGraph.fromEnclosure(
      roomName: roomName,
      enclosure: enclosure,
      stagedFurniture: stagedFurniture,
    );
  }

  /// Builds a watertight [SpatialSceneGraph] from viewport anchors, optional precomputed
  /// enclosure, and optional staged furniture items.
  Future<SpatialSceneGraph> buildSceneGraph({
    required String roomName,
    required List<Offset> viewportAnchors,
    RoomEnclosureModel? existingEnclosure,
    double ceilingHeightMeters = 2.8,
    List<StagedFurnitureModel> stagedFurniture = const [],
    bool anchorsAlreadyInMeters = false,
  }) async {
    final RoomEnclosureModel enclosure;
    if (existingEnclosure != null &&
        existingEnclosure.walls.length >= 3 &&
        (existingEnclosure.ceilingHeightMeters - ceilingHeightMeters).abs() <
            0.01) {
      enclosure = existingEnclosure;
    } else {
      enclosure = await _arService.reconstructWallPlanes(
        _effectiveMeterAnchors(
          viewportAnchors,
          anchorsAlreadyInMeters: anchorsAlreadyInMeters,
        ),
        ceilingHeight: ceilingHeightMeters,
      );
    }

    return SpatialSceneGraph.fromEnclosure(
      roomName: roomName,
      enclosure: enclosure,
      stagedFurniture: stagedFurniture,
    );
  }

  List<Map<String, double>> _effectiveMeterAnchors(
    List<Offset> viewportAnchors, {
    required bool anchorsAlreadyInMeters,
  }) {
    final scale = anchorsAlreadyInMeters ? 1.0 : 100.0;
    final meterAnchors = viewportAnchors
        .map((pt) => {'x': pt.dx / scale, 'z': pt.dy / scale})
        .toList();
    if (meterAnchors.length >= 3) {
      return meterAnchors;
    }
    return const [
      {'x': 0.0, 'z': 0.0},
      {'x': 4.8, 'z': 0.0},
      {'x': 4.8, 'z': 3.6},
      {'x': 0.0, 'z': 3.6},
    ];
  }

  /// Serializes [sceneGraph] in memory (for diagnostics/preview) without writing to disk.
  SpatialArchiveExportBundle serializePreview({
    required String propertyId,
    required SpatialSceneGraph sceneGraph,
    SpatialArchiveFormat format = SpatialArchiveFormat.bundle,
  }) {
    Uint8List? glbBytes;
    Uint8List? usdzBytes;

    if (format == SpatialArchiveFormat.glb ||
        format == SpatialArchiveFormat.bundle) {
      glbBytes = _glbSerializer.serialize(sceneGraph);
    }
    if (format == SpatialArchiveFormat.usdz ||
        format == SpatialArchiveFormat.bundle) {
      usdzBytes = _usdzSerializer.serialize(sceneGraph);
    }

    final totalBytes = (glbBytes?.length ?? 0) + (usdzBytes?.length ?? 0);
    final now = DateTime.now().millisecondsSinceEpoch;

    final record = SpatialExportRecord(
      id: 'exp-$now',
      propertyId: propertyId,
      roomName: sceneGraph.roomName,
      format: format,
      vertexCount: sceneGraph.totalVertexCount,
      triangleCount: sceneGraph.totalTriangleCount,
      nodeCount: sceneGraph.totalNodeCount,
      totalBytes: totalBytes,
      createdAt: now,
    );

    return SpatialArchiveExportBundle(
      sceneGraph: sceneGraph,
      record: record,
      glbBytes: glbBytes,
      usdzBytes: usdzBytes,
    );
  }

  /// Generates binary .glb and/or .usdz files on local storage and returns file metadata.
  Future<SpatialArchiveExportBundle> exportRoomArchive({
    required String propertyId,
    required String roomName,
    required List<Offset> viewportAnchors,
    RoomEnclosureModel? existingEnclosure,
    double ceilingHeightMeters = 2.8,
    List<StagedFurnitureModel> stagedFurniture = const [],
    SpatialArchiveFormat format = SpatialArchiveFormat.bundle,
    bool anchorsAlreadyInMeters = false,
  }) async {
    final sceneGraph = await buildSceneGraph(
      roomName: roomName,
      viewportAnchors: viewportAnchors,
      existingEnclosure: existingEnclosure,
      ceilingHeightMeters: ceilingHeightMeters,
      stagedFurniture: stagedFurniture,
      anchorsAlreadyInMeters: anchorsAlreadyInMeters,
    );

    final preview = serializePreview(
      propertyId: propertyId,
      sceneGraph: sceneGraph,
      format: format,
    );

    final exportDir = await _resolveExportDirectory();
    final safeSlug = roomName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final baseName =
        '${safeSlug.isEmpty ? "room_scan" : safeSlug}_${preview.record.createdAt}';

    String? glbPath;
    String? usdzPath;

    if (preview.glbBytes != null) {
      final file = File(p.join(exportDir.path, '$baseName.glb'));
      await file.writeAsBytes(preview.glbBytes!, flush: true);
      glbPath = file.path;
    }

    if (preview.usdzBytes != null) {
      final file = File(p.join(exportDir.path, '$baseName.usdz'));
      await file.writeAsBytes(preview.usdzBytes!, flush: true);
      usdzPath = file.path;
    }

    final savedRecord = SpatialExportRecord(
      id: preview.record.id,
      propertyId: propertyId,
      roomName: roomName,
      format: format,
      glbPath: glbPath,
      usdzPath: usdzPath,
      vertexCount: preview.record.vertexCount,
      triangleCount: preview.record.triangleCount,
      nodeCount: preview.record.nodeCount,
      totalBytes: preview.record.totalBytes,
      createdAt: preview.record.createdAt,
    );

    return SpatialArchiveExportBundle(
      sceneGraph: sceneGraph,
      record: savedRecord,
      glbBytes: preview.glbBytes,
      usdzBytes: preview.usdzBytes,
    );
  }

  /// Opens native iOS QLPreviewController for .usdz archives, with structured fallback.
  Future<Map<String, dynamic>> previewUsdzQuickLook(String usdzFilePath) async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'previewUsdzQuickLook',
        {'filePath': usdzFilePath},
      );
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {
      // Fallback on Android / Desktop / Unit Test environments
    }

    return {
      'status': Platform.isIOS ? 'QUICKLOOK_UNAVAILABLE' : 'PLATFORM_ARCHIVED',
      'filePath': usdzFilePath,
      'platform': Platform.operatingSystem,
    };
  }

  /// Invokes platform native share sheet for exported .glb / .usdz files.
  Future<Map<String, dynamic>> shareSpatialArchive({
    required List<String> filePaths,
    required String title,
  }) async {
    try {
      final res = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'shareSpatialArchive',
        {'filePaths': filePaths, 'title': title},
      );
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } catch (_) {
      // Fallback on Desktop / Headless CI environments
    }

    return {
      'status': 'ARCHIVED_LOCALLY',
      'filePaths': filePaths,
      'title': title,
    };
  }

  GltfArchiveInspection inspectGlbBytes(Uint8List bytes) =>
      _glbSerializer.inspectGlb(bytes);

  UsdzArchiveInspection inspectUsdzBytes(Uint8List bytes) =>
      _usdzSerializer.inspectUsdz(bytes);

  Future<Directory> _resolveExportDirectory() async {
    Directory baseDir;
    if (directoryProvider != null) {
      baseDir = await directoryProvider!();
    } else {
      try {
        baseDir = await getApplicationDocumentsDirectory();
      } catch (_) {
        baseDir = Directory.systemTemp;
      }
    }

    final exportDir = Directory(p.join(baseDir.path, 'estateview_3d_exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }
}
