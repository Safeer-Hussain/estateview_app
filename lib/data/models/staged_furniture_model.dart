import 'dart:math';
import 'dart:ui';

class StagedFurnitureModel {
  final String id;
  final String propertyId;
  final String presetId;
  final String name;
  final String category;
  final double widthMeters;
  final double depthMeters;
  final double heightMeters;
  final double posX;
  final double posZ;
  final double rotationY;
  final double scale;
  final String colorHex;
  final double priceUsd;
  final int createdAt;

  const StagedFurnitureModel({
    required this.id,
    required this.propertyId,
    required this.presetId,
    required this.name,
    required this.category,
    required this.widthMeters,
    required this.depthMeters,
    required this.heightMeters,
    required this.posX,
    required this.posZ,
    this.rotationY = 0.0,
    this.scale = 1.0,
    required this.colorHex,
    required this.priceUsd,
    required this.createdAt,
  });

  StagedFurnitureModel copyWith({
    String? id,
    String? propertyId,
    String? presetId,
    String? name,
    String? category,
    double? widthMeters,
    double? depthMeters,
    double? heightMeters,
    double? posX,
    double? posZ,
    double? rotationY,
    double? scale,
    String? colorHex,
    double? priceUsd,
    int? createdAt,
  }) {
    return StagedFurnitureModel(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      presetId: presetId ?? this.presetId,
      name: name ?? this.name,
      category: category ?? this.category,
      widthMeters: widthMeters ?? this.widthMeters,
      depthMeters: depthMeters ?? this.depthMeters,
      heightMeters: heightMeters ?? this.heightMeters,
      posX: posX ?? this.posX,
      posZ: posZ ?? this.posZ,
      rotationY: rotationY ?? this.rotationY,
      scale: scale ?? this.scale,
      colorHex: colorHex ?? this.colorHex,
      priceUsd: priceUsd ?? this.priceUsd,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'property_id': propertyId,
      'preset_id': presetId,
      'name': name,
      'category': category,
      'width_meters': widthMeters,
      'depth_meters': depthMeters,
      'height_meters': heightMeters,
      'pos_x': posX,
      'pos_z': posZ,
      'rotation_y': rotationY,
      'scale': scale,
      'color_hex': colorHex,
      'price_usd': priceUsd,
      'created_at': createdAt,
    };
  }

  factory StagedFurnitureModel.fromMap(Map<String, dynamic> map) {
    return StagedFurnitureModel(
      id: map['id'] as String? ?? '',
      propertyId: map['property_id'] as String? ?? '',
      presetId: map['preset_id'] as String? ?? 'preset-custom',
      name: map['name'] as String? ?? 'Luxury Furniture Item',
      category: map['category'] as String? ?? 'Seating',
      widthMeters: (map['width_meters'] as num?)?.toDouble() ?? 1.0,
      depthMeters: (map['depth_meters'] as num?)?.toDouble() ?? 1.0,
      heightMeters: (map['height_meters'] as num?)?.toDouble() ?? 0.8,
      posX: (map['pos_x'] as num?)?.toDouble() ?? 0.0,
      posZ: (map['pos_z'] as num?)?.toDouble() ?? 0.0,
      rotationY: (map['rotation_y'] as num?)?.toDouble() ?? 0.0,
      scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
      colorHex: map['color_hex'] as String? ?? '#2B3A42',
      priceUsd: (map['price_usd'] as num?)?.toDouble() ?? 2500.0,
      createdAt: (map['created_at'] as num?)?.toInt() ?? 0,
    );
  }

  /// Computes the 4 corners of the Oriented Bounding Box in 2D floor coordinates (x, z)
  List<Offset> getBoundingBoxCorners() {
    final hw = (widthMeters * scale) / 2.0;
    final hd = (depthMeters * scale) / 2.0;

    final cosR = cos(rotationY);
    final sinR = sin(rotationY);

    // Local corners: (-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd)
    final localCorners = [
      Offset(-hw, -hd),
      Offset(hw, -hd),
      Offset(hw, hd),
      Offset(-hw, hd),
    ];

    return localCorners.map((local) {
      final rotX = local.dx * cosR - local.dy * sinR;
      final rotZ = local.dx * sinR + local.dy * cosR;
      return Offset(posX + rotX, posZ + rotZ);
    }).toList();
  }

  /// Separating Axis Theorem (SAT) collision test between two oriented bounding boxes
  bool collidesWith(StagedFurnitureModel other) {
    final polyA = getBoundingBoxCorners();
    final polyB = other.getBoundingBoxCorners();

    return _polygonsOverlap(polyA, polyB) && _polygonsOverlap(polyB, polyA);
  }

  static bool _polygonsOverlap(List<Offset> polyA, List<Offset> polyB) {
    for (int i = 0; i < polyA.length; i++) {
      final p1 = polyA[i];
      final p2 = polyA[(i + 1) % polyA.length];

      // Normal perpendicular to edge (axis of projection)
      final edgeX = p2.dx - p1.dx;
      final edgeY = p2.dy - p1.dy;
      final axis = Offset(-edgeY, edgeX);

      final projA = _projectPolygon(axis, polyA);
      final projB = _projectPolygon(axis, polyB);

      // If projections do not overlap, separating axis exists -> no collision
      if (projA.$2 < projB.$1 || projB.$2 < projA.$1) {
        return false;
      }
    }
    return true;
  }

  static (double, double) _projectPolygon(Offset axis, List<Offset> polygon) {
    double minDot = double.infinity;
    double maxDot = -double.infinity;

    for (final p in polygon) {
      final dot = p.dx * axis.dx + p.dy * axis.dy;
      if (dot < minDot) minDot = dot;
      if (dot > maxDot) maxDot = dot;
    }
    return (minDot, maxDot);
  }

  /// Point-in-polygon raycasting test verifying if furniture is contained inside room floorplan
  bool isInsideFloorPolygon(List<Offset> floorAnchors) {
    if (floorAnchors.length < 3) return true;

    final corners = getBoundingBoxCorners();
    final center = Offset(posX, posZ);

    // Center point must be inside polygon
    if (!_pointInPolygon(center, floorAnchors)) {
      return false;
    }

    // Check all 4 corners
    for (final c in corners) {
      if (!_pointInPolygon(c, floorAnchors)) {
        return false;
      }
    }
    return true;
  }

  static bool _pointInPolygon(Offset point, List<Offset> polygon) {
    bool inside = false;
    final n = polygon.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;

      final intersect =
          ((yi > point.dy) != (yj > point.dy)) &&
          (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
    }
    return inside;
  }
}

/// Curated Luxury Architectural Furniture Presets
class FurniturePresets {
  static const List<StagedFurnitureModel> catalog = [
    StagedFurnitureModel(
      id: 'preset_eames_lounge',
      propertyId: '',
      presetId: 'preset_eames_lounge',
      name: 'Eames Lounge Chair & Ottoman',
      category: 'Seating',
      widthMeters: 0.85,
      depthMeters: 0.90,
      heightMeters: 0.84,
      posX: 0.0,
      posZ: 0.0,
      colorHex: '#1F1E1D',
      priceUsd: 6495.0,
      createdAt: 0,
    ),
    StagedFurnitureModel(
      id: 'preset_barcelona_daybed',
      propertyId: '',
      presetId: 'preset_barcelona_daybed',
      name: 'Barcelona Architectural Daybed',
      category: 'Seating',
      widthMeters: 1.96,
      depthMeters: 0.98,
      heightMeters: 0.65,
      posX: 0.0,
      posZ: 0.0,
      colorHex: '#3D2F28',
      priceUsd: 8750.0,
      createdAt: 0,
    ),
    StagedFurnitureModel(
      id: 'preset_noguchi_table',
      propertyId: '',
      presetId: 'preset_noguchi_table',
      name: 'Noguchi Sculptural Coffee Table',
      category: 'Tables',
      widthMeters: 1.28,
      depthMeters: 0.91,
      heightMeters: 0.40,
      posX: 0.0,
      posZ: 0.0,
      colorHex: '#6F8A91',
      priceUsd: 2890.0,
      createdAt: 0,
    ),
    StagedFurnitureModel(
      id: 'preset_arco_lamp',
      propertyId: '',
      presetId: 'preset_arco_lamp',
      name: 'Flos Arco Carrara Floor Lamp',
      category: 'Lighting',
      widthMeters: 0.50,
      depthMeters: 2.15,
      heightMeters: 2.32,
      posX: 0.0,
      posZ: 0.0,
      colorHex: '#EAE6E1',
      priceUsd: 3995.0,
      createdAt: 0,
    ),
    StagedFurnitureModel(
      id: 'preset_minimalist_dining',
      propertyId: '',
      presetId: 'preset_minimalist_dining',
      name: 'Solid Walnut Executive Dining Table',
      category: 'Tables',
      widthMeters: 2.40,
      depthMeters: 1.05,
      heightMeters: 0.75,
      posX: 0.0,
      posZ: 0.0,
      colorHex: '#4A3326',
      priceUsd: 5800.0,
      createdAt: 0,
    ),
    StagedFurnitureModel(
      id: 'preset_king_platform_bed',
      propertyId: '',
      presetId: 'preset_king_platform_bed',
      name: 'Cantilever Master Platform Bed',
      category: 'Beds',
      widthMeters: 2.10,
      depthMeters: 2.25,
      heightMeters: 0.95,
      posX: 0.0,
      posZ: 0.0,
      colorHex: '#252D32',
      priceUsd: 7400.0,
      createdAt: 0,
    ),
  ];
}
