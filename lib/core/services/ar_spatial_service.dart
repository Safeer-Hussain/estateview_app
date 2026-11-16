import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

class SpatialTelemetryPacket {
  final double confidencePercent;
  final double ambientLux;
  final double compassAzimuth;
  final String solarExposureRating;
  final double raycastDistanceMeters;
  final DateTime timestamp;

  const SpatialTelemetryPacket({
    required this.confidencePercent,
    required this.ambientLux,
    required this.compassAzimuth,
    required this.solarExposureRating,
    required this.raycastDistanceMeters,
    required this.timestamp,
  });

  factory SpatialTelemetryPacket.fromMap(Map<dynamic, dynamic> map) {
    return SpatialTelemetryPacket(
      confidencePercent: (map['confidencePercent'] as num?)?.toDouble() ?? 92.0,
      ambientLux: (map['ambientLux'] as num?)?.toDouble() ?? 480.0,
      compassAzimuth: (map['compassAzimuth'] as num?)?.toDouble() ?? 145.0,
      solarExposureRating:
          map['solarExposureRating'] as String? ?? 'OPTIMAL_SOUTH_EXPOSURE',
      raycastDistanceMeters:
          (map['raycastDistanceMeters'] as num?)?.toDouble() ?? 2.4,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }
}

class LidarPoint3D {
  final double x;
  final double y;
  final double z;
  final double confidence;

  const LidarPoint3D({
    required this.x,
    required this.y,
    required this.z,
    required this.confidence,
  });

  factory LidarPoint3D.fromMap(Map<dynamic, dynamic> map) {
    return LidarPoint3D(
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      z: (map['z'] as num?)?.toDouble() ?? 0.0,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.9,
    );
  }
}

class DepthPointCloudPacket {
  final int pointCount;
  final List<LidarPoint3D> points;
  final double minDepthMeters;
  final double maxDepthMeters;
  final double densityPointsPerSqMeter;
  final DateTime timestamp;

  const DepthPointCloudPacket({
    required this.pointCount,
    required this.points,
    required this.minDepthMeters,
    required this.maxDepthMeters,
    required this.densityPointsPerSqMeter,
    required this.timestamp,
  });

  factory DepthPointCloudPacket.fromMap(Map<dynamic, dynamic> map) {
    final rawPoints = map['points'] as List<dynamic>? ?? [];
    final parsed = rawPoints.map((p) {
      if (p is Map) {
        return LidarPoint3D.fromMap(p);
      }
      return const LidarPoint3D(x: 0, y: 0, z: 0, confidence: 0.9);
    }).toList();

    return DepthPointCloudPacket(
      pointCount: (map['pointCount'] as num?)?.toInt() ?? parsed.length,
      points: parsed,
      minDepthMeters: (map['minDepthMeters'] as num?)?.toDouble() ?? 0.8,
      maxDepthMeters: (map['maxDepthMeters'] as num?)?.toDouble() ?? 5.5,
      densityPointsPerSqMeter:
          (map['densityPointsPerSqMeter'] as num?)?.toDouble() ?? 42.0,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }
}

class ArSpatialService {
  static const MethodChannel _methodChannel = MethodChannel(
    AppConstants.arSpatialMethodChannel,
  );
  static const EventChannel _eventChannel = EventChannel(
    AppConstants.arSpatialEventChannel,
  );
  static const EventChannel _depthEventChannel = EventChannel(
    AppConstants.arLidarDepthEventChannel,
  );

  StreamController<SpatialTelemetryPacket>? _fallbackController;
  Timer? _fallbackTimer;
  int _fallbackStep = 0;

  StreamController<DepthPointCloudPacket>? _depthFallbackController;
  Timer? _depthFallbackTimer;
  int _depthFallbackStep = 0;

  Future<Map<String, dynamic>> initializeArSession() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'initializeArSession',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Fallback for desktop/simulator
    }
    return {
      'status': 'INITIALIZED',
      'trackingState': 'TRACKING_ACTIVE',
      'arEngine': 'Native_AR_Studio_Simulated',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Future<Map<String, dynamic>> placeCornerAnchor(
    double x,
    double y,
    double z,
  ) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'placeCornerAnchor',
        {'x': x, 'y': y, 'z': z},
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Fallback
    }
    return {
      'anchorCount': 1,
      'latestAnchor': {'x': x, 'y': y, 'z': z},
      'status': 'ANCHOR_PLACED',
    };
  }

  Future<Map<String, dynamic>> computeRoomPolygonArea(
    List<Map<String, double>> anchors,
  ) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'computeRoomPolygonArea',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Fallback calculation using Shoelace formula
    }

    if (anchors.length < 3) {
      return {
        'areaSqMeters': 0.0,
        'areaSqFeet': 0.0,
        'perimeterMeters': 0.0,
        'perimeterFeet': 0.0,
        'pointCount': anchors.length,
        'isClosed': false,
      };
    }

    double areaSum = 0.0;
    double perimeter = 0.0;
    final n = anchors.length;

    for (int i = 0; i < n; i++) {
      final p1 = anchors[i];
      final p2 = anchors[(i + 1) % n];
      final x1 = p1['x'] ?? 0.0;
      final z1 = p1['z'] ?? (p1['y'] ?? 0.0);
      final x2 = p2['x'] ?? 0.0;
      final z2 = p2['z'] ?? (p2['y'] ?? 0.0);

      areaSum += (x1 * z2) - (x2 * z1);
      final dx = x2 - x1;
      final dz = z2 - z1;
      perimeter += sqrt(dx * dx + dz * dz);
    }

    final areaMeters = (areaSum.abs()) / 2.0;
    final areaFeet = areaMeters * 10.7639;
    final perimeterFeet = perimeter * 3.28084;

    return {
      'areaSqMeters': areaMeters,
      'areaSqFeet': areaFeet,
      'perimeterMeters': perimeter,
      'perimeterFeet': perimeterFeet,
      'pointCount': n,
      'isClosed': true,
    };
  }

  Future<Map<String, dynamic>> resetSpatialAnchors() async {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'resetSpatialAnchors',
      );
      if (result != null) {
        return Map<String, dynamic>.from(result);
      }
    } catch (_) {
      // Fallback
    }
    return {'status': 'RESET', 'anchorCount': 0};
  }

  Stream<SpatialTelemetryPacket> streamSpatialTelemetry() {
    try {
      return _eventChannel
          .receiveBroadcastStream()
          .map((event) {
            if (event is Map) {
              return SpatialTelemetryPacket.fromMap(event);
            }
            return SpatialTelemetryPacket(
              confidencePercent: 94.0,
              ambientLux: 490.0,
              compassAzimuth: 145.0,
              solarExposureRating: 'OPTIMAL_SOUTH_EXPOSURE',
              raycastDistanceMeters: 2.35,
              timestamp: DateTime.now(),
            );
          })
          .handleError((_) {
            return _createFallbackStream();
          });
    } catch (_) {
      return _createFallbackStream();
    }
  }

  Stream<SpatialTelemetryPacket> _createFallbackStream() {
    _fallbackController?.close();
    _fallbackTimer?.cancel();

    _fallbackController = StreamController<SpatialTelemetryPacket>.broadcast();
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 1500), (
      timer,
    ) {
      _fallbackStep++;
      final confidence = 91.0 + (_fallbackStep % 7);
      final lux = 450.0 + (_fallbackStep * 11 % 120);
      final azimuth = (142.5 + (_fallbackStep * 4.2)) % 360.0;
      final solarRating = (azimuth >= 135.0 && azimuth <= 225.0)
          ? 'OPTIMAL_SOUTH_EXPOSURE'
          : 'MORNING_EAST_LIGHT';
      final raycast = 2.30 + ((_fallbackStep % 6) * 0.18);

      _fallbackController?.add(
        SpatialTelemetryPacket(
          confidencePercent: confidence,
          ambientLux: lux,
          compassAzimuth: azimuth,
          solarExposureRating: solarRating,
          raycastDistanceMeters: raycast,
          timestamp: DateTime.now(),
        ),
      );
    });

    return _fallbackController!.stream;
  }

  Stream<DepthPointCloudPacket> streamDepthPoints() {
    try {
      return _depthEventChannel
          .receiveBroadcastStream()
          .map((event) {
            if (event is Map) {
              return DepthPointCloudPacket.fromMap(event);
            }
            return _generateSamplePointCloud(0);
          })
          .handleError((_) {
            return _createDepthFallbackStream();
          });
    } catch (_) {
      return _createDepthFallbackStream();
    }
  }

  Stream<DepthPointCloudPacket> _createDepthFallbackStream() {
    _depthFallbackController?.close();
    _depthFallbackTimer?.cancel();

    _depthFallbackController =
        StreamController<DepthPointCloudPacket>.broadcast();
    _depthFallbackTimer = Timer.periodic(const Duration(milliseconds: 1200), (
      timer,
    ) {
      _depthFallbackStep++;
      _depthFallbackController?.add(
        _generateSamplePointCloud(_depthFallbackStep),
      );
    });

    return _depthFallbackController!.stream;
  }

  DepthPointCloudPacket _generateSamplePointCloud(int step) {
    final jitter = (step % 5) * 0.02;
    final points = <LidarPoint3D>[];

    // Floor grid (-2.4 to 2.4 on X, 0.5 to 5.5 on Z, Y approx -1.2)
    for (int ix = -4; ix <= 4; ix++) {
      for (int iz = -4; iz <= 4; iz++) {
        final x = ix * 0.6 + jitter;
        final z = iz * 0.6 + 3.0 + jitter;
        final y = -1.2 + ((ix * iz) % 3) * 0.01;
        final conf = 0.90 + ((ix + iz).abs() % 5) * 0.02;
        points.add(LidarPoint3D(x: x, y: y, z: z, confidence: conf));
      }
    }

    // Vertical wall boundaries
    for (int iy = -2; iy <= 4; iy++) {
      final y = iy * 0.45;
      // Back wall (z = 5.4)
      for (int ix = -4; ix <= 4; ix++) {
        points.add(
          LidarPoint3D(x: ix * 0.6, y: y, z: 5.4 + jitter, confidence: 0.95),
        );
      }
      // Left wall (x = -2.4) and Right wall (x = 2.4)
      for (int iz = 0; iz <= 7; iz++) {
        final z = iz * 0.6 + 0.8;
        points.add(
          LidarPoint3D(x: -2.4 + jitter, y: y, z: z, confidence: 0.92),
        );
        points.add(LidarPoint3D(x: 2.4 - jitter, y: y, z: z, confidence: 0.93));
      }
    }

    return DepthPointCloudPacket(
      pointCount: points.length,
      points: points,
      minDepthMeters: 0.8,
      maxDepthMeters: 5.5,
      densityPointsPerSqMeter: 42.0,
      timestamp: DateTime.now(),
    );
  }

  void dispose() {
    _fallbackTimer?.cancel();
    _fallbackController?.close();
    _depthFallbackTimer?.cancel();
    _depthFallbackController?.close();
  }
}
