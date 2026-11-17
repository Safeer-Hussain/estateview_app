import 'dart:ui';

enum PlaneType { horizontalFloor, horizontalCeiling, verticalWall }

enum OpeningType { door, window }

class ArchitecturalOpeningModel {
  final String id;
  final OpeningType type;
  final double widthMeters;
  final double heightMeters;
  final double offsetMeters;
  final double sillHeightMeters;
  final double areaSqMeters;

  const ArchitecturalOpeningModel({
    required this.id,
    required this.type,
    required this.widthMeters,
    required this.heightMeters,
    required this.offsetMeters,
    this.sillHeightMeters = 0.0,
    required this.areaSqMeters,
  });

  factory ArchitecturalOpeningModel.fromMap(
    Map<dynamic, dynamic> map,
    int index,
  ) {
    final typeStr = map['type'] as String? ?? 'DOOR_OPENING';
    final isDoor = typeStr.contains('DOOR');
    final w = (map['widthMeters'] as num?)?.toDouble() ?? 0.95;
    final h =
        (map['heightMeters'] as num?)?.toDouble() ?? (isDoor ? 2.10 : 1.40);

    return ArchitecturalOpeningModel(
      id: 'opening-$index-${isDoor ? "door" : "win"}',
      type: isDoor ? OpeningType.door : OpeningType.window,
      widthMeters: w,
      heightMeters: h,
      offsetMeters: (map['offsetMeters'] as num?)?.toDouble() ?? 0.45,
      sillHeightMeters:
          (map['sillHeightMeters'] as num?)?.toDouble() ??
          (isDoor ? 0.0 : 0.90),
      areaSqMeters: (map['areaSqMeters'] as num?)?.toDouble() ?? (w * h),
    );
  }
}

class WallPlaneModel {
  final String id;
  final int wallIndex;
  final Offset p1;
  final Offset p2;
  final double lengthMeters;
  final double heightMeters;
  final List<double> normal;
  final double grossAreaSqMeters;
  final double netAreaSqMeters;
  final String orientation;
  final List<ArchitecturalOpeningModel> openings;

  const WallPlaneModel({
    required this.id,
    required this.wallIndex,
    required this.p1,
    required this.p2,
    required this.lengthMeters,
    required this.heightMeters,
    required this.normal,
    required this.grossAreaSqMeters,
    required this.netAreaSqMeters,
    required this.orientation,
    required this.openings,
  });

  factory WallPlaneModel.fromMap(Map<dynamic, dynamic> map) {
    final p1Map = map['p1'] as Map<dynamic, dynamic>? ?? {};
    final p2Map = map['p2'] as Map<dynamic, dynamic>? ?? {};

    final rawOpenings = map['openings'] as List<dynamic>? ?? [];
    final openings = <ArchitecturalOpeningModel>[];
    for (int i = 0; i < rawOpenings.length; i++) {
      if (rawOpenings[i] is Map) {
        openings.add(
          ArchitecturalOpeningModel.fromMap(
            rawOpenings[i] as Map<dynamic, dynamic>,
            i,
          ),
        );
      }
    }

    final rawNormal =
        (map['normal'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [0.0, 0.0, 1.0];

    return WallPlaneModel(
      id: map['id'] as String? ?? 'wall-0',
      wallIndex: (map['wallIndex'] as num?)?.toInt() ?? 0,
      p1: Offset(
        (p1Map['x'] as num?)?.toDouble() ?? 0.0,
        (p1Map['z'] as num?)?.toDouble() ?? 0.0,
      ),
      p2: Offset(
        (p2Map['x'] as num?)?.toDouble() ?? 0.0,
        (p2Map['z'] as num?)?.toDouble() ?? 0.0,
      ),
      lengthMeters: (map['lengthMeters'] as num?)?.toDouble() ?? 0.0,
      heightMeters: (map['heightMeters'] as num?)?.toDouble() ?? 2.8,
      normal: rawNormal,
      grossAreaSqMeters: (map['grossAreaSqMeters'] as num?)?.toDouble() ?? 0.0,
      netAreaSqMeters: (map['netAreaSqMeters'] as num?)?.toDouble() ?? 0.0,
      orientation: map['orientation'] as String? ?? 'SOUTH_FACING',
      openings: openings,
    );
  }
}

class HorizontalPlaneModel {
  final PlaneType type;
  final List<double> normal;
  final double elevationMeters;
  final double areaSqMeters;

  const HorizontalPlaneModel({
    required this.type,
    required this.normal,
    required this.elevationMeters,
    this.areaSqMeters = 0.0,
  });

  factory HorizontalPlaneModel.fromMap(
    Map<dynamic, dynamic> map,
    PlaneType type,
  ) {
    final rawNormal =
        (map['normal'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        (type == PlaneType.horizontalFloor
            ? [0.0, 1.0, 0.0]
            : [0.0, -1.0, 0.0]);

    return HorizontalPlaneModel(
      type: type,
      normal: rawNormal,
      elevationMeters: (map['elevationMeters'] as num?)?.toDouble() ?? 0.0,
      areaSqMeters: (map['areaSqMeters'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RoomEnclosureModel {
  final List<WallPlaneModel> walls;
  final HorizontalPlaneModel floorPlane;
  final HorizontalPlaneModel ceilingPlane;
  final double totalGrossWallAreaSqMeters;
  final double totalNetWallAreaSqMeters;
  final int totalOpeningsCount;
  final double ceilingHeightMeters;

  const RoomEnclosureModel({
    required this.walls,
    required this.floorPlane,
    required this.ceilingPlane,
    required this.totalGrossWallAreaSqMeters,
    required this.totalNetWallAreaSqMeters,
    required this.totalOpeningsCount,
    required this.ceilingHeightMeters,
  });

  factory RoomEnclosureModel.fromMap(Map<dynamic, dynamic> map) {
    final rawWalls = map['walls'] as List<dynamic>? ?? [];
    final walls = rawWalls
        .whereType<Map<dynamic, dynamic>>()
        .map((w) => WallPlaneModel.fromMap(w))
        .toList();

    final floorMap = map['floorPlane'] as Map<dynamic, dynamic>? ?? {};
    final ceilMap = map['ceilingPlane'] as Map<dynamic, dynamic>? ?? {};

    return RoomEnclosureModel(
      walls: walls,
      floorPlane: HorizontalPlaneModel.fromMap(
        floorMap,
        PlaneType.horizontalFloor,
      ),
      ceilingPlane: HorizontalPlaneModel.fromMap(
        ceilMap,
        PlaneType.horizontalCeiling,
      ),
      totalGrossWallAreaSqMeters:
          (map['totalGrossWallAreaSqMeters'] as num?)?.toDouble() ?? 0.0,
      totalNetWallAreaSqMeters:
          (map['totalNetWallAreaSqMeters'] as num?)?.toDouble() ?? 0.0,
      totalOpeningsCount: (map['totalOpeningsCount'] as num?)?.toInt() ?? 0,
      ceilingHeightMeters:
          (map['ceilingHeightMeters'] as num?)?.toDouble() ?? 2.8,
    );
  }
}
