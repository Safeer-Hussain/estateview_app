import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'plane_reconstruction_model.dart';
import 'staged_furniture_model.dart';

enum SpatialArchiveFormat { glb, usdz, bundle }

class SpatialExportRecord {
  final String id;
  final String propertyId;
  final String roomName;
  final SpatialArchiveFormat format;
  final String? glbPath;
  final String? usdzPath;
  final int vertexCount;
  final int triangleCount;
  final int nodeCount;
  final int totalBytes;
  final int createdAt;

  const SpatialExportRecord({
    required this.id,
    required this.propertyId,
    required this.roomName,
    required this.format,
    this.glbPath,
    this.usdzPath,
    required this.vertexCount,
    required this.triangleCount,
    required this.nodeCount,
    required this.totalBytes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'room_name': roomName,
      'format': format.name,
      'glb_path': glbPath,
      'usdz_path': usdzPath,
      'vertex_count': vertexCount,
      'triangle_count': triangleCount,
      'node_count': nodeCount,
      'total_bytes': totalBytes,
      'created_at': createdAt,
    };
  }

  factory SpatialExportRecord.fromMap(Map<String, dynamic> map) {
    final formatStr = map['format'] as String? ?? 'bundle';
    final format = SpatialArchiveFormat.values.firstWhere(
      (f) => f.name == formatStr,
      orElse: () => SpatialArchiveFormat.bundle,
    );

    return SpatialExportRecord(
      id: map['id'] as String? ?? '',
      propertyId: map['property_id'] as String? ?? '',
      roomName: map['room_name'] as String? ?? 'Exported Room',
      format: format,
      glbPath: map['glb_path'] as String?,
      usdzPath: map['usdz_path'] as String?,
      vertexCount: (map['vertex_count'] as num?)?.toInt() ?? 0,
      triangleCount: (map['triangle_count'] as num?)?.toInt() ?? 0,
      nodeCount: (map['node_count'] as num?)?.toInt() ?? 0,
      totalBytes: (map['total_bytes'] as num?)?.toInt() ?? 0,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }
}

class SpatialMaterialSpec {
  final String name;
  final List<double> baseColorFactor; // [r, g, b, a]
  final double roughness;
  final double metallic;
  final bool transparent;

  const SpatialMaterialSpec({
    required this.name,
    required this.baseColorFactor,
    required this.roughness,
    required this.metallic,
    this.transparent = false,
  });
}

class MeshNodeData {
  final String name;
  final String semanticType;
  final int? materialIndex;
  final Float32List? positions; // XYZ packed
  final Float32List? normals; // XYZ packed
  final Uint16List? indices; // triangle indices
  final List<double>? translation;
  final List<double>? rotationQuat;
  final List<double>? scale;
  final List<MeshNodeData> children;

  const MeshNodeData({
    required this.name,
    required this.semanticType,
    this.materialIndex,
    this.positions,
    this.normals,
    this.indices,
    this.translation,
    this.rotationQuat,
    this.scale,
    this.children = const [],
  });

  bool get hasMesh =>
      positions != null &&
      normals != null &&
      indices != null &&
      materialIndex != null;

  int get vertexCount => positions == null ? 0 : positions!.length ~/ 3;

  int get triangleCount => indices == null ? 0 : indices!.length ~/ 3;

  List<double> computeMinBounds() {
    final pos = positions;
    if (pos == null || pos.isEmpty) return const [0.0, 0.0, 0.0];
    var minX = double.infinity;
    var minY = double.infinity;
    var minZ = double.infinity;
    for (int i = 0; i < pos.length; i += 3) {
      if (pos[i] < minX) minX = pos[i];
      if (pos[i + 1] < minY) minY = pos[i + 1];
      if (pos[i + 2] < minZ) minZ = pos[i + 2];
    }
    return [minX, minY, minZ];
  }

  List<double> computeMaxBounds() {
    final pos = positions;
    if (pos == null || pos.isEmpty) return const [0.0, 0.0, 0.0];
    var maxX = -double.infinity;
    var maxY = -double.infinity;
    var maxZ = -double.infinity;
    for (int i = 0; i < pos.length; i += 3) {
      if (pos[i] > maxX) maxX = pos[i];
      if (pos[i + 1] > maxY) maxY = pos[i + 1];
      if (pos[i + 2] > maxZ) maxZ = pos[i + 2];
    }
    return [maxX, maxY, maxZ];
  }
}

class SpatialSceneGraph {
  final String roomName;
  final MeshNodeData rootNode;
  final List<SpatialMaterialSpec> materials;

  const SpatialSceneGraph({
    required this.roomName,
    required this.rootNode,
    required this.materials,
  });

  static const List<SpatialMaterialSpec> defaultArchitecturalMaterials = [
    SpatialMaterialSpec(
      name: 'FloorMaterial',
      baseColorFactor: [0.72, 0.62, 0.48, 1.0],
      roughness: 0.65,
      metallic: 0.0,
    ),
    SpatialMaterialSpec(
      name: 'WallMaterial',
      baseColorFactor: [0.92, 0.91, 0.89, 1.0],
      roughness: 0.85,
      metallic: 0.0,
    ),
    SpatialMaterialSpec(
      name: 'CeilingMaterial',
      baseColorFactor: [0.96, 0.96, 0.97, 1.0],
      roughness: 0.90,
      metallic: 0.0,
    ),
    SpatialMaterialSpec(
      name: 'OpeningGlassMaterial',
      baseColorFactor: [0.45, 0.72, 0.86, 0.55],
      roughness: 0.15,
      metallic: 0.1,
      transparent: true,
    ),
    SpatialMaterialSpec(
      name: 'FurnitureMaterial',
      baseColorFactor: [0.25, 0.30, 0.36, 1.0],
      roughness: 0.50,
      metallic: 0.1,
    ),
  ];

  int get totalNodeCount => _countNodes(rootNode);

  int get totalMeshCount => _countMeshes(rootNode);

  int get totalVertexCount => _sumVertices(rootNode);

  int get totalTriangleCount => _sumTriangles(rootNode);

  int _countNodes(MeshNodeData node) {
    var count = 1;
    for (final child in node.children) {
      count += _countNodes(child);
    }
    return count;
  }

  int _countMeshes(MeshNodeData node) {
    var count = node.hasMesh ? 1 : 0;
    for (final child in node.children) {
      count += _countMeshes(child);
    }
    return count;
  }

  int _sumVertices(MeshNodeData node) {
    var count = node.vertexCount;
    for (final child in node.children) {
      count += _sumVertices(child);
    }
    return count;
  }

  int _sumTriangles(MeshNodeData node) {
    var count = node.triangleCount;
    for (final child in node.children) {
      count += _sumTriangles(child);
    }
    return count;
  }

  String toHierarchySummaryJson() {
    Map<String, dynamic> encodeNode(MeshNodeData n) {
      return {
        'name': n.name,
        'type': n.semanticType,
        if (n.hasMesh) 'vertices': n.vertexCount,
        if (n.hasMesh) 'triangles': n.triangleCount,
        if (n.children.isNotEmpty)
          'children': n.children.map(encodeNode).toList(),
      };
    }

    return const JsonEncoder.withIndent('  ').convert({
      'roomName': roomName,
      'totalNodes': totalNodeCount,
      'totalMeshes': totalMeshCount,
      'totalVertices': totalVertexCount,
      'totalTriangles': totalTriangleCount,
      'hierarchy': encodeNode(rootNode),
    });
  }

  /// Builds a deterministic hierarchical 3D scene from a reconstructed room enclosure
  /// and optional staged furniture items.
  factory SpatialSceneGraph.fromEnclosure({
    required String roomName,
    required RoomEnclosureModel enclosure,
    List<StagedFurnitureModel> stagedFurniture = const [],
  }) {
    final floorPoints = enclosure.walls.map((w) => w.p1).toList();
    final topChildren = <MeshNodeData>[];

    // 1. Floor Slab & Ceiling Slab from enclosure floor polygon
    if (floorPoints.length >= 3) {
      final triangleIndices = triangulatePolygonXZ(floorPoints);
      topChildren.add(
        _buildHorizontalSlabNode(
          name: 'Floor_Slab',
          semanticType: 'HORIZONTAL_FLOOR',
          polygonPoints: floorPoints,
          triangleIndices: triangleIndices,
          elevationMeters: enclosure.floorPlane.elevationMeters,
          normalY: 1.0,
          flipWinding: false,
          materialIndex: 0,
        ),
      );

      topChildren.add(
        _buildHorizontalSlabNode(
          name: 'Ceiling_Slab',
          semanticType: 'HORIZONTAL_CEILING',
          polygonPoints: floorPoints,
          triangleIndices: triangleIndices,
          elevationMeters: enclosure.ceilingHeightMeters,
          normalY: -1.0,
          flipWinding: true,
          materialIndex: 2,
        ),
      );
    }

    // 2. Walls Group -> individual wall quads + child door/window opening portals
    final wallNodes = <MeshNodeData>[];
    for (final wall in enclosure.walls) {
      wallNodes.add(_buildWallNode(wall));
    }
    topChildren.add(
      MeshNodeData(
        name: 'Walls_Group',
        semanticType: 'WALLS_GROUP',
        children: wallNodes,
      ),
    );

    // 3. Staged Furniture Group -> oriented 3D bounding cuboids with TRS transforms
    if (stagedFurniture.isNotEmpty) {
      final furnitureNodes = <MeshNodeData>[];
      for (int i = 0; i < stagedFurniture.length; i++) {
        furnitureNodes.add(_buildFurnitureNode(stagedFurniture[i], i));
      }
      topChildren.add(
        MeshNodeData(
          name: 'Furniture_Staging_Group',
          semanticType: 'FURNITURE_GROUP',
          children: furnitureNodes,
        ),
      );
    }

    final root = MeshNodeData(
      name: 'EstateView_Room_Root',
      semanticType: 'SCENE_ROOT',
      children: topChildren,
    );

    return SpatialSceneGraph(
      roomName: roomName,
      rootNode: root,
      materials: defaultArchitecturalMaterials,
    );
  }

  static MeshNodeData _buildHorizontalSlabNode({
    required String name,
    required String semanticType,
    required List<Offset> polygonPoints,
    required List<int> triangleIndices,
    required double elevationMeters,
    required double normalY,
    required bool flipWinding,
    required int materialIndex,
  }) {
    final n = polygonPoints.length;
    final positions = Float32List(n * 3);
    final normals = Float32List(n * 3);

    for (int i = 0; i < n; i++) {
      final p = polygonPoints[i];
      positions[i * 3] = p.dx;
      positions[i * 3 + 1] = elevationMeters;
      positions[i * 3 + 2] = p.dy;

      normals[i * 3] = 0.0;
      normals[i * 3 + 1] = normalY;
      normals[i * 3 + 2] = 0.0;
    }

    final indices = Uint16List(triangleIndices.length);
    for (int i = 0; i < triangleIndices.length; i += 3) {
      if (flipWinding) {
        indices[i] = triangleIndices[i];
        indices[i + 1] = triangleIndices[i + 2];
        indices[i + 2] = triangleIndices[i + 1];
      } else {
        indices[i] = triangleIndices[i];
        indices[i + 1] = triangleIndices[i + 1];
        indices[i + 2] = triangleIndices[i + 2];
      }
    }

    return MeshNodeData(
      name: name,
      semanticType: semanticType,
      materialIndex: materialIndex,
      positions: positions,
      normals: normals,
      indices: indices,
    );
  }

  static MeshNodeData _buildWallNode(WallPlaneModel wall) {
    final x1 = wall.p1.dx;
    final z1 = wall.p1.dy;
    final x2 = wall.p2.dx;
    final z2 = wall.p2.dy;
    final h = wall.heightMeters;
    final nx = wall.normal.isNotEmpty ? wall.normal[0] : 0.0;
    final ny = wall.normal.length >= 2 ? wall.normal[1] : 0.0;
    final nz = wall.normal.length >= 3 ? wall.normal[2] : 1.0;

    final positions = Float32List.fromList([
      x1, 0.0, z1, // v0 bottom-start
      x2, 0.0, z2, // v1 bottom-end
      x2, h, z2, // v2 top-end
      x1, h, z1, // v3 top-start
    ]);

    final normals = Float32List.fromList([
      nx,
      ny,
      nz,
      nx,
      ny,
      nz,
      nx,
      ny,
      nz,
      nx,
      ny,
      nz,
    ]);

    final indices = Uint16List.fromList([0, 1, 2, 0, 2, 3]);

    final openingNodes = <MeshNodeData>[];
    if (wall.lengthMeters > 0.001) {
      final ux = (x2 - x1) / wall.lengthMeters;
      final uz = (z2 - z1) / wall.lengthMeters;

      for (int i = 0; i < wall.openings.length; i++) {
        final op = wall.openings[i];
        final startD = op.offsetMeters;
        final endD = op.offsetMeters + op.widthMeters;
        final ox1 = x1 + ux * startD + nx * 0.015;
        final oz1 = z1 + uz * startD + nz * 0.015;
        final ox2 = x1 + ux * endD + nx * 0.015;
        final oz2 = z1 + uz * endD + nz * 0.015;
        final y0 = op.sillHeightMeters;
        final y1 = op.sillHeightMeters + op.heightMeters;

        final opPositions = Float32List.fromList([
          ox1,
          y0,
          oz1,
          ox2,
          y0,
          oz2,
          ox2,
          y1,
          oz2,
          ox1,
          y1,
          oz1,
        ]);

        final opNormals = Float32List.fromList([
          nx,
          ny,
          nz,
          nx,
          ny,
          nz,
          nx,
          ny,
          nz,
          nx,
          ny,
          nz,
        ]);

        final typeLabel = op.type == OpeningType.door ? 'Door' : 'Window';
        openingNodes.add(
          MeshNodeData(
            name: 'Wall_${wall.wallIndex + 1}_${typeLabel}_$i',
            semanticType: op.type == OpeningType.door
                ? 'OPENING_DOOR'
                : 'OPENING_WINDOW',
            materialIndex: 3,
            positions: opPositions,
            normals: opNormals,
            indices: Uint16List.fromList([0, 1, 2, 0, 2, 3]),
          ),
        );
      }
    }

    return MeshNodeData(
      name: 'Wall_${wall.wallIndex + 1}',
      semanticType: 'VERTICAL_WALL',
      materialIndex: 1,
      positions: positions,
      normals: normals,
      indices: indices,
      children: openingNodes,
    );
  }

  static MeshNodeData _buildFurnitureNode(
    StagedFurnitureModel item,
    int index,
  ) {
    final hw = item.widthMeters / 2.0;
    final hd = item.depthMeters / 2.0;
    final h = item.heightMeters;

    // 6-face flat-shaded cuboid: 24 vertices (4 per face), 12 triangles (36 indices)
    final positions = Float32List.fromList([
      // Front (+Z)
      -hw, 0.0, hd, hw, 0.0, hd, hw, h, hd, -hw, h, hd,
      // Back (-Z)
      hw, 0.0, -hd, -hw, 0.0, -hd, -hw, h, -hd, hw, h, -hd,
      // Top (+Y)
      -hw, h, hd, hw, h, hd, hw, h, -hd, -hw, h, -hd,
      // Bottom (-Y)
      -hw, 0.0, -hd, hw, 0.0, -hd, hw, 0.0, hd, -hw, 0.0, hd,
      // Right (+X)
      hw, 0.0, hd, hw, 0.0, -hd, hw, h, -hd, hw, h, hd,
      // Left (-X)
      -hw, 0.0, -hd, -hw, 0.0, hd, -hw, h, hd, -hw, h, -hd,
    ]);

    final normals = Float32List.fromList([
      0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, // Front
      0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, // Back
      0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, // Top
      0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, // Bottom
      1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, // Right
      -1, 0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, // Left
    ]);

    final indices = Uint16List.fromList([
      0, 1, 2, 0, 2, 3, // Front
      4, 5, 6, 4, 6, 7, // Back
      8, 9, 10, 8, 10, 11, // Top
      12, 13, 14, 12, 14, 15, // Bottom
      16, 17, 18, 16, 18, 19, // Right
      20, 21, 22, 20, 22, 23, // Left
    ]);

    final halfYaw = item.rotationY / 2.0;
    final cleanName = item.name
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return MeshNodeData(
      name: 'Furniture_${index + 1}_$cleanName',
      semanticType: 'STAGED_FURNITURE',
      materialIndex: 4,
      positions: positions,
      normals: normals,
      indices: indices,
      translation: [item.posX, 0.0, item.posZ],
      rotationQuat: [0.0, sin(halfYaw), 0.0, cos(halfYaw)],
      scale: [item.scale, item.scale, item.scale],
    );
  }

  /// Ear-clipping triangulation on XZ floorplan points returning (N - 2) * 3 indices
  /// with consistent upward (+Y) orientation when viewed from above.
  static List<int> triangulatePolygonXZ(List<Offset> points) {
    final n = points.length;
    if (n < 3) return const [];
    if (n == 3) return [0, 1, 2];

    // Compute signed area on (x, z)
    double signedArea = 0.0;
    for (int i = 0; i < n; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      signedArea += (p1.dx * p2.dy) - (p2.dx * p1.dy);
    }

    // Build index ring oriented counter-clockwise in XZ
    final remaining = List<int>.generate(n, (i) => i);
    if (signedArea < 0) {
      remaining.setAll(0, remaining.reversed.toList());
    }

    final triangles = <int>[];
    int guard = 0;
    while (remaining.length > 3 && guard < n * n) {
      guard++;
      bool clipped = false;
      final m = remaining.length;

      for (int i = 0; i < m; i++) {
        final iPrev = remaining[(i - 1 + m) % m];
        final iCurr = remaining[i];
        final iNext = remaining[(i + 1) % m];

        final a = points[iPrev];
        final b = points[iCurr];
        final c = points[iNext];

        if (!_isConvexVertex(a, b, c)) continue;

        bool containsOther = false;
        for (int j = 0; j < m; j++) {
          final idx = remaining[j];
          if (idx == iPrev || idx == iCurr || idx == iNext) continue;
          if (_pointInTriangle(points[idx], a, b, c)) {
            containsOther = true;
            break;
          }
        }
        if (containsOther) continue;

        triangles.addAll([iPrev, iCurr, iNext]);
        remaining.removeAt(i);
        clipped = true;
        break;
      }

      if (!clipped) break;
    }

    if (remaining.length == 3) {
      triangles.addAll(remaining);
    }

    if (triangles.isEmpty) {
      // Fallback fan triangulation for degenerate input
      for (int i = 1; i < n - 1; i++) {
        triangles.addAll([0, i, i + 1]);
      }
    }

    return triangles;
  }

  static bool _isConvexVertex(Offset a, Offset b, Offset c) {
    final cross = (b.dx - a.dx) * (c.dy - a.dy) - (b.dy - a.dy) * (c.dx - a.dx);
    return cross > 1e-9;
  }

  static bool _pointInTriangle(Offset p, Offset a, Offset b, Offset c) {
    final d1 = _sign(p, a, b);
    final d2 = _sign(p, b, c);
    final d3 = _sign(p, c, a);
    final hasNeg = (d1 < -1e-9) || (d2 < -1e-9) || (d3 < -1e-9);
    final hasPos = (d1 > 1e-9) || (d2 > 1e-9) || (d3 > 1e-9);
    return !(hasNeg && hasPos);
  }

  static double _sign(Offset p1, Offset p2, Offset p3) {
    return (p1.dx - p3.dx) * (p2.dy - p3.dy) -
        (p2.dx - p3.dx) * (p1.dy - p3.dy);
  }
}
